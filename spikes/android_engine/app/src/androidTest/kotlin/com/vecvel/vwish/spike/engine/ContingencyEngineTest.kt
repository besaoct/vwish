@file:OptIn(UnstableApi::class, ExperimentalApi::class)

package com.vecvel.vwish.spike.engine

import android.graphics.PixelFormat
import android.hardware.HardwareBuffer
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import androidx.media3.common.util.ExperimentalApi
import androidx.media3.common.util.UnstableApi
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.vecvel.vwish.spike.engine.Scenarios.json
import java.util.Random
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The AND-16 contingency engine prototype ([ContingencyEngineProto]) on the canonical grid-cut
 * composition that CompositionPlayer 1.11.1 cannot play through (PlayerTopologyTest): playback on
 * the frame clock with per-frame barcode checks, and exact seeks through the slot players.
 * Sizes AND-16 (AND-01.md "Contingency").
 */
@RunWith(AndroidJUnit4::class)
class ContingencyEngineTest {
    private val ctx = TestMedia.target
    private val seqs = listOf(1, 2, 3)

    /** Output surface standing in for the SurfaceProducer; images are consumed and dropped. */
    private class Sink(w: Int, h: Int) : AutoCloseable {
        val thread = HandlerThread("contingency-sink").apply { start() }
        val reader: ImageReader = ImageReader.newInstance(w, h, PixelFormat.RGBA_8888, 3, HardwareBuffer.USAGE_GPU_COLOR_OUTPUT).apply {
            setOnImageAvailableListener({ it.acquireLatestImage()?.close() }, Handler(thread.looper))
        }
        override fun close() {
            reader.close()
            thread.quitSafely()
        }
    }

    /** Source-frame error of each mismatch: decoded barcode minus the rule frame (null = wrong layer/background). */
    private fun errors(plan: SpikePlan, frames: List<ProbeFrame>, times: LongArray): Map<String, Int> {
        val hist = HashMap<String, Int>()
        for (f in frames) {
            val k = GridTime.frameIndexNearest(f.ptsUs, plan.fps)
            for (seq in seqs) {
                val want = Scenarios.expected(plan, seq, k, times)
                val got = f.regions["s$seq"]?.reading
                val key = when {
                    want == null && got == Barcode.Background -> "gapOk"
                    want == null -> "gapShowsContent"
                    got is Barcode.Value -> (got.n - want).toString()
                    else -> "noContent"
                }
                hist.merge(key, 1, Int::plus)
            }
        }
        return hist
    }

    private fun playback(fps: Int, source: ContingencyEngineProto.FrameSource): JSONObject {
        val plan = Scenarios.gridCut(fps)
        val store = ParamStore(plan.gridFps).apply { loadFrom(plan) }
        val times = TestMedia.videoSampleTimesUs("barcode_$fps.mp4")
        Sink(plan.canvasW, plan.canvasH).use { sink ->
            ContingencyEngineProto(ctx, plan, store, Scenarios.regions(1, 2, 3), source).use { e ->
                e.attach(sink.reader.surface)
                val r = e.play(0, plan.durUs / 1000 + 20_000)
                val frames = e.frames.toList()
                val check = Scenarios.check(plan, frames, times, seqs)
                val hist = errors(plan, frames, times)
                val exactLayerFrames = hist["0"] ?: 0
                val layerFrames = hist.filterKeys { it != "gapOk" && it != "gapShowsContent" }.values.sum()
                return JSONObject().put("frameSource", source.name).put("fps", fps).put("ended", r.ended).put("wallMs", r.wallMs)
                    .put("compositionMs", plan.durUs / 1000).put("expectedFrames", plan.durFrames)
                    .put("composedFrames", r.composedFrames).put("skippedOutputFrames", r.skippedFrames)
                    .put("compositeMs", Results.stats(r.compositeMs))
                    .put("sourceFrameErrorHistogram", JSONObject(hist as Map<*, *>))
                    .put("layerFramesExact", exactLayerFrames).put("layerFrames", layerFrames)
                    .put("slots", JSONArray(r.slots.map { JSONObject().put("seq", it.seq).put("seeks", it.seeks).put("driftCorrections", it.driftCorrections).put("latched", it.latched).put("behind", it.behind).put("ahead", it.ahead) }))
                    .put("barcode", check.json())
            }
        }
    }

    @Test
    fun gridCutPlayback_contingency() {
        val runs = JSONArray()
        for (fps in listOf(24, 30, 60)) runs.put(playback(fps, ContingencyEngineProto.FrameSource.IMAGE_READER))
        runs.put(playback(30, ContingencyEngineProto.FrameSource.SURFACE_TEXTURE))
        Results.write("AND16_proto_playback", JSONObject().put("device", android.os.Build.MODEL).put("runs", runs))
        for (i in 0 until runs.length()) {
            val r = runs.getJSONObject(i)
            // Plays through every secondary boundary to the end (the CompositionPlayer stall is gone).
            assertTrue(r.toString(), r.getBoolean("ended"))
            val hist = r.getJSONObject("sourceFrameErrorHistogram")
            // Gating follows the plan: a gap never shows content.
            assertEquals(r.toString(), 0, hist.optInt("gapShowsContent", 0))
        }
    }

    @Test
    fun exactSeek_contingency() {
        val plan = Scenarios.gridCut(30)
        val store = ParamStore(plan.gridFps).apply { loadFrom(plan) }
        val times = TestMedia.videoSampleTimesUs("barcode_30.mp4")
        val rnd = Random(20261010)
        val latencies = ArrayList<Double>()
        val failures = ArrayList<String>()
        var ok = 0
        val n = 60
        Sink(plan.canvasW, plan.canvasH).use { sink ->
            ContingencyEngineProto(ctx, plan, store, Scenarios.regions(1, 2, 3)).use { e ->
                e.attach(sink.reader.surface)
                repeat(n) { i ->
                    val k = rnd.nextInt(plan.durFrames.toInt()).toLong()
                    e.frames.clear()
                    val ms = e.seekExact(k, 10_000)
                    if (ms < 0) {
                        failures += "#$i k=$k timeout"
                        return@repeat
                    }
                    latencies += ms
                    val f = e.frames.lastOrNull()
                    val mm = if (f == null) listOf("k=$k no frame") else Scenarios.checkFrame(plan, k, f.regions, times, seqs)
                    if (mm.isEmpty()) ok++ else failures += mm
                }
            }
        }
        Results.write(
            "AND16_proto_exact_seek",
            JSONObject().put("seeks", n).put("correct", ok).put("latencyMs", Results.stats(latencies)).put("failures", Results.arr(failures.take(20))),
        )
        assertEquals(failures.joinToString("\n"), n, ok)
    }
}
