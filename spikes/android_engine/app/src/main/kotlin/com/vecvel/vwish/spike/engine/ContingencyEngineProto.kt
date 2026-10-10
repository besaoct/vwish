@file:OptIn(UnstableApi::class, ExperimentalApi::class)

package com.vecvel.vwish.spike.engine

import android.content.Context
import android.graphics.ImageFormat
import android.graphics.SurfaceTexture
import android.hardware.HardwareBuffer
import android.media.Image
import android.media.ImageReader
import android.net.Uri
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLExt
import android.opengl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLES30
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.view.Choreographer
import android.view.Surface
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.ExperimentalApi
import androidx.media3.common.util.GlProgram
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.SeekParameters
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.abs

/**
 * AND-01 prototype of the AND-16 contingency engine (ARCH §13.3 "Contingency", D-36), built
 * because CompositionPlayer 1.11.1 stalls at secondary-sequence boundaries (R1 no-go):
 * one [ExoPlayer] per packing slot renders into a [SurfaceTexture] (OES texture); a frame clock at
 * the project fps (Choreographer on the preview thread) decides the output frame k, schedules the
 * slot players from the plan (gaps and gating follow the plan, not Media3), latches each slot's
 * texture and composites bottom → top with the place shader and the straight-alpha blend onto
 * the output surface (the SurfaceProducer stand-in). Drift > ½ frame is corrected by seeking the
 * late player (at most once per [correctionCooldownMs]). Audio slots are not prototyped.
 *
 * Everything (EGL, GL, players' application looper, Choreographer) runs on one preview thread.
 */
class ContingencyEngineProto(
    private val context: Context,
    private val plan: SpikePlan,
    private val store: ParamStore,
    private val regions: List<ProbeRegion>,
    private val frameSource: FrameSource = FrameSource.IMAGE_READER,
    private val correctionCooldownMs: Long = 1000,
) : AutoCloseable {
    /** Where a slot player's decoded frames land. */
    enum class FrameSource {
        /** One [SurfaceTexture] per slot: only the newest frame can be latched. */
        SURFACE_TEXTURE,

        /**
         * One [ImageReader] (PRIVATE, GPU-sampled) per slot: several decoded frames are held and the
         * one whose pts is the output frame's rule frame is imported (HardwareBuffer → EGLImage → OES).
         */
        IMAGE_READER,
    }

    data class SlotStats(val seq: Int, var seeks: Int = 0, var driftCorrections: Int = 0, var latched: Int = 0, var behind: Int = 0, var ahead: Int = 0)

    data class Result(
        val ended: Boolean,
        val wallMs: Double,
        val composedFrames: Int,
        val skippedFrames: Int,
        val compositeMs: List<Double>,
        val slots: List<SlotStats>,
    )

    private val thread = HandlerThread("vwish-preview-contingency").apply { start() }
    private val handler = Handler(thread.looper)

    /** Composited output frames as probe readings (pts = P(k)). */
    val frames = ConcurrentLinkedQueue<ProbeFrame>()

    private inner class Slot(val seq: Int) {
        val layers = plan.layersOf(seq)
        val clipStart = LongArray(layers.size)
        val tex: Int
        val st: SurfaceTexture?
        val reader: ImageReader?
        val surface: Surface
        /** IMAGE_READER: acquired images not yet shown (pts order), the bound image and its EGLImage. */
        val queue = ArrayDeque<Image>()
        var bound: Image? = null
        var boundEglImage = 0L
        val player: ExoPlayer
        val ptsByRelease = ConcurrentHashMap<Long, Long>()
        @Volatile var pending = 0
        var latchedPts = Long.MIN_VALUE
        var lastCorrectionMs = 0L
        val texMatrix = FloatArray(16)
        val stats = SlotStats(seq)

        init {
            val ids = IntArray(1)
            GLES20.glGenTextures(1, ids, 0)
            tex = ids[0]
            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, tex)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            if (frameSource == FrameSource.SURFACE_TEXTURE) {
                st = SurfaceTexture(tex).also { it.setOnFrameAvailableListener({ pending++ }, handler) }
                reader = null
                surface = Surface(st)
            } else {
                st = null
                reader = ImageReader.newInstance(plan.canvasW, plan.canvasH, ImageFormat.PRIVATE, MAX_IMAGES, HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE)
                    .also { r -> r.setOnImageAvailableListener({ pull() }, handler) }
                surface = reader.surface
            }
            player = ExoPlayer.Builder(context).setLooper(thread.looper).build()
            player.setSeekParameters(SeekParameters.EXACT)
            player.setVideoSurface(surface)
            player.setVideoFrameMetadataListener { pts, releaseNs, _, _ ->
                ptsByRelease[releaseNs] = pts
                if (ptsByRelease.size > 512) ptsByRelease.keys.sorted().take(256).forEach { ptsByRelease.remove(it) }
            }
            val mapper = SpikeCompositionMapper(context)
            val items = layers.mapIndexed { i, l ->
                val (start, end) = mapper.clipping(plan, l, EpsilonMode.SNAP_TO_RULE_FRAME)
                clipStart[i] = start
                MediaItem.Builder().setUri(Uri.parse(l.uri))
                    .setClippingConfiguration(MediaItem.ClippingConfiguration.Builder().setStartPositionUs(start).setEndPositionUs(end).build())
                    .build()
            }
            player.setMediaItems(items)
            player.prepare()
        }

        /** Layer index active at plan time [t], or -1. */
        fun activeAt(t: Long): Int = layers.indexOfFirst {
            t >= GridTime.timeOfFrame(it.k0, plan.gridFps) && t < GridTime.timeOfFrame(it.k1, plan.gridFps)
        }

        fun nextAfter(t: Long): Int = layers.indexOfFirst { GridTime.timeOfFrame(it.k0, plan.gridFps) > t }

        /** Source time of layer [i] at plan time [t]. */
        fun sourceAt(i: Int, t: Long): Long {
            val l = layers[i]
            return l.srcStartUs + ((t - GridTime.timeOfFrame(l.k0, plan.gridFps)) * l.speed.toDouble()).toLong()
        }

        /** Item position (ms) of layer [i] at plan time [t]. */
        fun positionMs(i: Int, t: Long): Long = ((sourceAt(i, t) - clipStart[i]) / 1000).coerceAtLeast(0)

        /** IMAGE_READER: acquires queued images while one slot stays free for the bound image. */
        fun pull() {
            val r = reader ?: return
            while (queue.size + (if (bound != null) 1 else 0) < MAX_IMAGES - 1) {
                val img = try {
                    r.acquireNextImage()
                } catch (e: IllegalStateException) {
                    null
                } ?: return
                queue.addLast(img)
            }
        }

        private fun ptsOf(img: Image): Long? = ptsByRelease[img.timestamp]

        private fun bind(img: Image) {
            val hb = img.hardwareBuffer ?: return
            val egl = HwbImport.nativeCreateImage(hb)
            hb.close()
            check(egl != 0L) { "eglCreateImageKHR failed" }
            check(HwbImport.nativeBindOes(tex, egl)) { "glEGLImageTargetTexture2DOES failed" }
            if (boundEglImage != 0L) HwbImport.nativeDestroyImage(boundEglImage)
            bound?.close()
            bound = img
            boundEglImage = egl
            latchedPts = ptsOf(img) ?: latchedPts
            stats.latched++
        }

        /** Shows the newest available frame (paused / seeking / gated). */
        fun latchNewest() {
            if (st != null) {
                while (pending > 0) {
                    st.updateTexImage()
                    pending--
                    stats.latched++
                    latchedPts = ptsByRelease[st.timestamp] ?: latchedPts
                }
                return
            }
            pull()
            while (queue.size > 1) queue.removeFirst().close()
            queue.removeFirstOrNull()?.let { bind(it) }
            pull()
        }

        /** Latches the frame for rule-frame pts [expectedPts] (± ½ frame) as well as the frame source allows. */
        fun latchFor(expectedPts: Long, halfFrameUs: Long) {
            if (st != null) {
                while (pending > 0 && (latchedPts == Long.MIN_VALUE || latchedPts < expectedPts - halfFrameUs)) {
                    st.updateTexImage()
                    pending--
                    stats.latched++
                    latchedPts = ptsByRelease[st.timestamp] ?: latchedPts
                }
            } else {
                pull()
                // Drop frames older than the newest one that is not in the future.
                while (queue.size >= 2 && (ptsOf(queue.elementAt(1)) ?: Long.MAX_VALUE) <= expectedPts + halfFrameUs) queue.removeFirst().close()
                val head = queue.firstOrNull()
                val headPts = head?.let { ptsOf(it) }
                if (head != null && headPts != null && headPts <= expectedPts + halfFrameUs) {
                    queue.removeFirst()
                    bind(head)
                }
                pull()
            }
            if (latchedPts < expectedPts - halfFrameUs) stats.behind++ else if (latchedPts > expectedPts + halfFrameUs) stats.ahead++
        }

        /** Texture coordinate matrix: SurfaceTexture's own, or a y flip for HardwareBuffer images (row 0 = top). */
        fun matrix(): FloatArray {
            if (st != null) st.getTransformMatrix(texMatrix) else FLIP_Y.copyInto(texMatrix)
            return texMatrix
        }

        fun release() {
            player.release()
            queue.forEach { it.close() }
            queue.clear()
            if (boundEglImage != 0L) HwbImport.nativeDestroyImage(boundEglImage)
            bound?.close()
            reader?.close()
            surface.release()
            st?.release()
            GLES20.glDeleteTextures(1, intArrayOf(tex), 0)
        }
    }

    private var display: EGLDisplay = EGL14.EGL_NO_DISPLAY
    private var eglContext: EGLContext = EGL14.EGL_NO_CONTEXT
    private var eglSurface: EGLSurface = EGL14.EGL_NO_SURFACE
    private lateinit var program: GlProgram
    private val slots = ArrayList<Slot>()
    private lateinit var row: ByteBuffer

    private var playing = false
    private var startT = 0L
    private var wall0Ns = 0L
    private var lastK = -1L
    private var skipped = 0
    private var composed = 0
    private val compositeMs = ArrayList<Double>()
    private var ended = false
    private var endLatch: CountDownLatch? = null

    private fun <T> onThread(block: () -> T): T {
        val r = AtomicReference<Any?>()
        val f = AtomicReference<Throwable?>()
        val latch = CountDownLatch(1)
        handler.post {
            try {
                r.set(block())
            } catch (t: Throwable) {
                f.set(t)
            } finally {
                latch.countDown()
            }
        }
        check(latch.await(60, TimeUnit.SECONDS)) { "preview thread blocked" }
        f.get()?.let { throw it }
        @Suppress("UNCHECKED_CAST")
        return r.get() as T
    }

    /** Creates EGL on [output] and one player + SurfaceTexture per visual slot. */
    fun attach(output: Surface) = onThread {
        display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        val v = IntArray(2)
        check(EGL14.eglInitialize(display, v, 0, v, 1))
        val attribs = intArrayOf(
            EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8, EGL14.EGL_BLUE_SIZE, 8, EGL14.EGL_ALPHA_SIZE, 8,
            EGL14.EGL_RENDERABLE_TYPE, EGLExt.EGL_OPENGL_ES3_BIT_KHR, EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT, EGL14.EGL_NONE,
        )
        val configs = arrayOfNulls<EGLConfig>(1)
        val n = IntArray(1)
        check(EGL14.eglChooseConfig(display, attribs, 0, configs, 0, 1, n, 0) && n[0] > 0)
        eglContext = EGL14.eglCreateContext(display, configs[0], EGL14.EGL_NO_CONTEXT, intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 3, EGL14.EGL_NONE), 0)
        eglSurface = EGL14.eglCreateWindowSurface(display, configs[0], output, intArrayOf(EGL14.EGL_NONE), 0)
        check(EGL14.eglMakeCurrent(display, eglSurface, eglSurface, eglContext))
        program = GlProgram(PlaceShaders.VERTEX, OES_FRAGMENT).also {
            it.setBufferAttribute("aFramePosition", GlUtil.getNormalizedCoordinateBounds(), GlUtil.HOMOGENEOUS_COORDINATE_VECTOR_SIZE)
        }
        row = ByteBuffer.allocateDirect(plan.canvasW * 4).order(ByteOrder.nativeOrder())
        for (seq in 1..plan.visualSequenceCount) slots += Slot(seq)
    }

    private val halfFrameUs get() = 500_000L / plan.fps

    /** Pre-rolls every slot for plan time [t] (paused) and waits until all players are READY. */
    private fun preroll(t: Long, timeoutMs: Long) {
        onThread {
            for (s in slots) {
                val i = s.activeAt(t).takeIf { it >= 0 }
                val target = i ?: s.nextAfter(t)
                s.player.playWhenReady = false
                if (target >= 0) {
                    s.player.seekTo(target, if (i != null) s.positionMs(i, t) else 0)
                    s.stats.seeks++
                }
            }
        }
        val end = SystemClock.elapsedRealtime() + timeoutMs
        while (SystemClock.elapsedRealtime() < end) {
            if (onThread { slots.all { it.player.playbackState == Player.STATE_READY || it.player.playbackState == Player.STATE_ENDED } }) return
            Thread.sleep(10)
        }
        error("slots not ready after $timeoutMs ms")
    }

    /** Plays from output frame [fromK] to the end on the frame clock; returns when ended or after [timeoutMs]. */
    fun play(fromK: Long, timeoutMs: Long): Result {
        val t0 = GridTime.timeOfFrame(fromK, plan.fps)
        preroll(t0, 20_000)
        val latch = CountDownLatch(1)
        val started = System.nanoTime()
        onThread {
            endLatch = latch
            frames.clear()
            compositeMs.clear()
            composed = 0
            skipped = 0
            ended = false
            lastK = fromK - 1
            startT = t0
            wall0Ns = System.nanoTime()
            playing = true
            schedule(t0)
            Choreographer.getInstance().postFrameCallback(tick)
        }
        latch.await(timeoutMs, TimeUnit.MILLISECONDS)
        return onThread {
            playing = false
            slots.forEach { it.player.pause() }
            Result(ended, (System.nanoTime() - started) / 1e6, composed, skipped, compositeMs.toList(), slots.map { it.stats.copy() })
        }
    }

    private val tick = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            if (!playing) return
            val t = startT + (System.nanoTime() - wall0Ns) / 1000
            if (t >= plan.durUs) {
                ended = true
                playing = false
                endLatch?.countDown()
                return
            }
            val k = GridTime.frameIndexOf(t, plan.fps)
            schedule(t)
            if (k != lastK) {
                if (k > lastK + 1) skipped += (k - lastK - 1).toInt()
                composite(k)
                lastK = k
            }
            Choreographer.getInstance().postFrameCallback(this)
        }
    }

    /** Drives the slot players for plan time [t] (gaps, item changes, drift > ½ frame). */
    private fun schedule(t: Long) {
        val nowMs = SystemClock.elapsedRealtime()
        for (s in slots) {
            val i = s.activeAt(t)
            if (i >= 0) {
                val want = s.positionMs(i, t)
                when {
                    s.player.currentMediaItemIndex != i -> {
                        s.player.seekTo(i, want)
                        s.stats.seeks++
                        s.lastCorrectionMs = nowMs
                    }
                    s.player.playbackState == Player.STATE_READY && s.player.isPlaying &&
                        abs(s.player.currentPosition - want) * 1000 > halfFrameUs * 2 &&
                        nowMs - s.lastCorrectionMs > correctionCooldownMs -> {
                        s.player.seekTo(i, want)
                        s.stats.driftCorrections++
                        s.lastCorrectionMs = nowMs
                    }
                }
                s.player.playWhenReady = true
            } else {
                if (s.player.playWhenReady) s.player.playWhenReady = false
                val next = s.nextAfter(t)
                if (next >= 0 && (s.player.currentMediaItemIndex != next || s.player.currentPosition > 0)) {
                    s.player.seekTo(next, 0)
                    s.stats.seeks++
                }
            }
        }
    }

    /** Composites output frame [k] from the latched slot textures and reads the probe rows. */
    private fun composite(k: Long) {
        val started = System.nanoTime()
        val tk = GridTime.timeOfFrame(k, plan.fps)
        val pts = GridTime.platformTimeOfFrame(k, plan.fps)
        GLES20.glViewport(0, 0, plan.canvasW, plan.canvasH)
        val bg = plan.bgRgb()
        GLES20.glDisable(GLES20.GL_BLEND)
        GLES20.glClearColor(bg[0], bg[1], bg[2], 1f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES30.glBlendFuncSeparate(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA, GLES20.GL_ONE, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        for (s in slots.asReversed()) { // bottom sequence first; sequence 1 is the top
            val i = s.activeAt(tk)
            if (i < 0) {
                s.latchNewest()
                continue
            }
            val p = store.activeAt(s.seq, pts, plan.fps) ?: continue
            val rule = SpikeCompositionMapper.Companion.SourceFrameTimes.ruleFramePts(context, s.layers[i].uri, s.sourceAt(i, tk))
            s.latchFor(rule, halfFrameUs)
            if (s.latchedPts == Long.MIN_VALUE) continue
            program.use()
            program.setSamplerTexIdUniform("uTex", s.tex, 0)
            program.setFloatsUniform("uTexMatrix", s.matrix())
            program.setFloatsUniform("uRect", floatArrayOf(p.rect[0] / plan.canvasW, p.rect[1] / plan.canvasH, p.rect[2] / plan.canvasW, p.rect[3] / plan.canvasH))
            program.setFloatsUniform("uTint", p.tint)
            program.setFloatUniform("uAlpha", p.alpha)
            program.bindAttributesAndUniforms()
            // GlProgram binds by the reported sampler type; the emulator's GLES translator reports
            // samplerExternalOES as sampler2D, so bind the OES target explicitly (AND-01 finding).
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, s.tex)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        }
        val readings = HashMap<String, RegionReading>()
        for (r in regions) {
            val bar = readRow(Barcode.barcodeY(r.rect))
            val samples = (0 until 16).map { bar(Barcode.columnX(r.rect, it)) }
            val grey = readRow(Barcode.greyY(r.rect))((r.rect[0] + r.rect[2] / 2).toInt())
            val marker = readRow(Barcode.markerY(r.rect))
            readings[r.name] = RegionReading(Barcode.decode(samples, bg), grey, marker((r.rect[0] + r.rect[2] * 0.25f).toInt()), marker((r.rect[0] + r.rect[2] * 0.75f).toInt()))
        }
        EGLExt.eglPresentationTimeANDROID(display, eglSurface, pts * 1000)
        EGL14.eglSwapBuffers(display, eglSurface)
        composed++
        compositeMs += (System.nanoTime() - started) / 1e6
        frames.add(ProbeFrame(pts, System.nanoTime(), readings))
    }

    private fun readRow(y: Int): (Int) -> Int {
        val glY = (plan.canvasH - 1 - y).coerceIn(0, plan.canvasH - 1)
        row.clear()
        GLES20.glReadPixels(0, glY, plan.canvasW, 1, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, row)
        val copy = ByteArray(plan.canvasW * 4)
        row.get(copy)
        return { x ->
            val i = x.coerceIn(0, plan.canvasW - 1) * 4
            ((copy[i].toInt() and 0xff) shl 16) or ((copy[i + 1].toInt() and 0xff) shl 8) or (copy[i + 2].toInt() and 0xff)
        }
    }

    /**
     * Exact seek through the slot players (contingency path; AND-17's PausedFrameRenderer is the
     * other one): seeks every slot to the rule frame of output frame [k], waits until each active
     * slot has latched that frame, composites once. Returns the latency in ms, or -1 on timeout.
     */
    fun seekExact(k: Long, timeoutMs: Long): Double {
        val started = System.nanoTime()
        val tk = GridTime.timeOfFrame(k, plan.fps)
        val targets = onThread {
            slots.map { s ->
                val i = s.activeAt(tk)
                s.player.playWhenReady = false
                if (i >= 0) {
                    val rule = SpikeCompositionMapper.Companion.SourceFrameTimes.ruleFramePts(context, s.layers[i].uri, s.sourceAt(i, tk))
                    s.player.seekTo(i, (rule - s.clipStart[i]) / 1000)
                    s.stats.seeks++
                    rule
                } else {
                    Long.MIN_VALUE
                }
            }
        }
        val end = SystemClock.elapsedRealtime() + timeoutMs
        while (SystemClock.elapsedRealtime() < end) {
            val done = onThread {
                slots.withIndex().all { (j, s) ->
                    val want = targets[j]
                    s.latchNewest()
                    want == Long.MIN_VALUE || s.latchedPts == want
                }
            }
            if (done) {
                onThread { composite(k) }
                return (System.nanoTime() - started) / 1e6
            }
            Thread.sleep(2)
        }
        return -1.0
    }

    override fun close() {
        try {
            onThread {
                playing = false
                slots.forEach { it.release() }
                slots.clear()
                if (::program.isInitialized) program.delete()
                if (display != EGL14.EGL_NO_DISPLAY) {
                    EGL14.eglMakeCurrent(display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
                    EGL14.eglDestroySurface(display, eglSurface)
                    EGL14.eglDestroyContext(display, eglContext)
                    EGL14.eglTerminate(display)
                }
            }
        } finally {
            thread.quitSafely()
        }
    }

    companion object {
        /** Images held per slot (one bound + up to MAX_IMAGES − 2 queued). */
        const val MAX_IMAGES = 6

        /** Column-major y flip: (s, t) → (s, 1 − t). */
        val FLIP_Y = floatArrayOf(1f, 0f, 0f, 0f, 0f, -1f, 0f, 0f, 0f, 0f, 1f, 0f, 0f, 1f, 0f, 1f)

        /** The place shader of [PlaceShaders] sampling an OES texture through the SurfaceTexture matrix. */
        const val OES_FRAGMENT = """
#extension GL_OES_EGL_image_external : require
precision highp float;
uniform samplerExternalOES uTex;
uniform mat4 uTexMatrix;
uniform vec4 uRect;
uniform vec3 uTint;
uniform float uAlpha;
varying vec2 vPos;
void main() {
  vec2 c = vec2(vPos.x, 1.0 - vPos.y);
  vec2 uv = (c - uRect.xy) / uRect.zw;
  if (uv.x < 0.0 || uv.y < 0.0 || uv.x >= 1.0 || uv.y >= 1.0) {
    gl_FragColor = vec4(0.0);
    return;
  }
  vec2 st = (uTexMatrix * vec4(uv.x, 1.0 - uv.y, 0.0, 1.0)).xy;
  vec4 s = texture2D(uTex, st);
  gl_FragColor = vec4(clamp(s.rgb * uTint, 0.0, 1.0), uAlpha);
}
"""
    }
}
