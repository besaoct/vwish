@file:OptIn(UnstableApi::class, ExperimentalApi::class)

package com.vecvel.vwish.spike.engine

import androidx.media3.common.util.ExperimentalApi
import androidx.media3.common.util.UnstableApi
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.vecvel.vwish.spike.engine.Scenarios.json
import java.io.File
import java.util.Random
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * V-N18 grid timing (ARCH §5, D-35): Media3 seek semantics (→ `androidSeekMsRounding`),
 * clock-band pts after seeks and scrubs, secondary-frame selection, and the grid-cut barcode case
 * (cuts at k ≡ 1, 2 mod 3, boundaries anchored at P(k)) in playback, exact seek and export.
 */
@RunWith(AndroidJUnit4::class)
class GridTimingTest {
    private val ctx = TestMedia.target
    private val mapper = SpikeCompositionMapper(ctx)
    private val seqs = listOf(1, 2, 3)

    private fun probeFor(plan: SpikePlan) = ProbeEffect(plan.canvasW, plan.canvasH, plan.bgRgb(), Scenarios.regions(1, 2, 3))

    /** Probe frame for a rendered pts (the latest one processed with that pts after [sinceNs]). */
    private fun probeAt(probe: ProbeEffect, pts: Long, sinceNs: Long): ProbeFrame? =
        probe.frames.filter { it.ptsUs == pts && it.wallNs >= sinceNs }.maxByOrNull { it.wallNs }
            ?: probe.frames.filter { it.ptsUs == pts }.maxByOrNull { it.wallNs }

    @Test
    fun seekSemantics_vn18() {
        val plan = Scenarios.gridCut(30)
        val store = ParamStore(plan.gridFps).apply { loadFrom(plan) }
        val probe = probeFor(plan)
        val times = TestMedia.videoSampleTimesUs("barcode_30.mp4")
        val c = mapper.build(plan, store, Scenarios.videoClock(plan.fps, MapperOptions(probe = probe)))
        val rows = JSONArray()
        var floorHits = 0
        var ceilHits = 0
        var total = 0
        var offGrid = 0
        val mismatches = ArrayList<String>()
        PlayerHarness(ctx, plan.canvasW, plan.canvasH).use { h ->
            h.load(c)
            h.awaitReady()
            val ks = listOf(1L, 2, 4, 5, 13, 14, 37, 38, 40, 41, 62, 64, 91, 92, 100, 101)
            for (k in ks) {
                val p = GridTime.platformTimeOfFrame(k, plan.fps)
                val row = JSONObject().put("k", k).put("P", p)
                for ((name, ms) in listOf("floor" to GridTime.platformMsFloor(k, plan.fps), "ceil" to GridTime.platformMsCeil(k, plan.fps))) {
                    // Move away first so every seek renders a new frame.
                    h.seekAndAwait(if (k > 20) 0 else 3000, 5000)
                    val t0 = System.nanoTime()
                    val got = h.seekAndAwait(ms, 5000) ?: error("no frame after seek to $ms ms")
                    val kGot = GridTime.frameIndexNearest(got.first.ptsUs, plan.fps)
                    if (Math.abs(got.first.ptsUs - GridTime.platformTimeOfFrame(kGot, plan.fps)) > 1000) offGrid++
                    probeAt(probe, got.first.ptsUs, t0)?.let { f ->
                        mismatches += Scenarios.checkFrame(plan, kGot, f.regions, times, seqs)
                    } ?: mismatches.add("k=$kGot no probe frame for pts ${got.first.ptsUs}")
                    row.put(name, JSONObject().put("ms", ms).put("pts", got.first.ptsUs).put("k", kGot).put("latencyMs", got.second))
                    if (name == "floor" && kGot == k) floorHits++
                    if (name == "ceil" && kGot == k) ceilHits++
                }
                total++
                rows.put(row)
            }
        }
        val rounding = when {
            floorHits == total && ceilHits == total -> "either"
            floorHits == total -> "floor"
            ceilHits == total -> "ceil"
            else -> "inconsistent"
        }
        Results.write(
            "VN18_seek_semantics",
            JSONObject().put("cases", rows).put("floorHits", floorHits).put("ceilHits", ceilHits).put("total", total)
                .put("androidSeekMsRounding", rounding).put("ptsOffGridOver1ms", offGrid)
                .put("secondaryMismatches", Results.arr(mismatches)),
        )
        assertTrue("seek semantics inconsistent: floor $floorHits ceil $ceilHits of $total", rounding != "inconsistent")
        assertEquals(0, offGrid)
        assertTrue(mismatches.joinToString("\n"), mismatches.isEmpty())
    }

    @Test
    fun exactSeek200_vn18() {
        val plan = Scenarios.gridCut(30)
        val store = ParamStore(plan.gridFps).apply { loadFrom(plan) }
        val probe = probeFor(plan)
        val times = TestMedia.videoSampleTimesUs("barcode_30.mp4")
        val c = mapper.build(plan, store, Scenarios.videoClock(plan.fps, MapperOptions(probe = probe)))
        val rnd = Random(20261008)
        var acked = 0
        var ackedIn500 = 0
        val latencies = ArrayList<Double>()
        val failures = ArrayList<String>()
        var last = -1L
        PlayerHarness(ctx, plan.canvasW, plan.canvasH).use { h ->
            h.load(c)
            h.awaitReady()
            repeat(200) { i ->
                var k: Long
                do { k = rnd.nextInt(plan.durFrames.toInt()).toLong() } while (k == last)
                last = k
                val ms = seekMs(k, plan.fps)
                val t0 = System.nanoTime()
                val got = h.seekAndAwait(ms, 3000) { GridTime.frameIndexNearest(it.ptsUs, plan.fps) == k }
                if (got == null) {
                    failures += "#$i k=$k ms=$ms: no ack"
                    return@repeat
                }
                latencies += got.second
                if (got.second <= 500) ackedIn500++
                val f = probeAt(probe, got.first.ptsUs, t0)
                val mm = if (f == null) listOf("k=$k no probe frame") else Scenarios.checkFrame(plan, k, f.regions, times, seqs)
                if (mm.isEmpty()) acked++ else failures += mm
            }
        }
        Results.write(
            "VN18_exact_seek_200",
            JSONObject().put("seeks", 200).put("ackedAndCorrect", acked).put("ackedWithin500ms", ackedIn500)
                .put("rounding", SEEK_ROUNDING).put("latencyMs", Results.stats(latencies))
                .put("failures", Results.arr(failures.take(20))),
        )
        assertEquals(failures.joinToString("\n"), 200, acked)
    }

    @Test
    fun scrubThenExactSeek_vn18() {
        val plan = Scenarios.gridCut(30)
        val store = ParamStore(plan.gridFps).apply { loadFrom(plan) }
        val probe = probeFor(plan)
        val times = TestMedia.videoSampleTimesUs("barcode_30.mp4")
        val c = mapper.build(plan, store, Scenarios.videoClock(plan.fps, MapperOptions(probe = probe)))
        val mismatches = ArrayList<String>()
        var offGrid = 0
        var scrubFrames = 0
        PlayerHarness(ctx, plan.canvasW, plan.canvasH).use { h ->
            h.load(c)
            h.awaitReady()
            val t0 = System.nanoTime()
            h.run { h.player.setScrubbingModeEnabled(true) }
            var pos = 0L
            while (pos < plan.durUs / 1000 - 100) {
                h.run { h.player.seekTo(pos) }
                Thread.sleep(30)
                pos += 47 // off-grid positions on purpose
            }
            Thread.sleep(500)
            h.run { h.player.setScrubbingModeEnabled(false) }
            val scrubbed = h.rendered.filter { it.wallNs >= t0 }
            scrubFrames = scrubbed.size
            for (r in scrubbed) {
                val k = GridTime.frameIndexNearest(r.ptsUs, plan.fps)
                if (Math.abs(r.ptsUs - GridTime.platformTimeOfFrame(k, plan.fps)) > 1000) offGrid++
                probeAt(probe, r.ptsUs, t0)?.let { mismatches += Scenarios.checkFrame(plan, k, it.regions, times, seqs) }
            }
            // Exact seek after the scrub lands on the grid.
            for (k in listOf(38L, 64L, 7L)) {
                val got = h.seekAndAwait(seekMs(k, plan.fps), 3000) { GridTime.frameIndexNearest(it.ptsUs, plan.fps) == k }
                if (got == null) mismatches += "post-scrub exact seek to $k not acked"
            }
        }
        Results.write(
            "VN18_scrub",
            JSONObject().put("scrubRenderedFrames", scrubFrames).put("ptsOffGridOver1ms", offGrid)
                .put("mismatches", mismatches.size).put("firstMismatches", Results.arr(mismatches.take(12))),
        )
        assertTrue("no frames rendered while scrubbing", scrubFrames > 0)
        assertEquals(0, offGrid)
        assertTrue(mismatches.joinToString("\n"), mismatches.isEmpty())
    }

    /**
     * Grid-cut playback in CompositionPlayer. Media3 1.11.1 stalls at the first item/gap boundary
     * of a secondary sequence (PlayerTopologyTest, AND-01 R1 no-go), so this records how far
     * playback composites and checks every composited frame against the rule; the 100% playback
     * case is carried by the contingency prototype (ContingencyEngineTest).
     */
    private fun playback(fps: Int) {
        val plan = Scenarios.gridCut(fps)
        val store = ParamStore(plan.gridFps).apply { loadFrom(plan) }
        val probe = probeFor(plan)
        val times = TestMedia.videoSampleTimesUs("barcode_$fps.mp4")
        val c = mapper.build(plan, store, Scenarios.videoClock(fps, MapperOptions(probe = probe)))
        PlayerHarness(ctx, plan.canvasW, plan.canvasH).use { h ->
            h.load(c)
            h.awaitReady()
            probe.clear()
            val t0 = System.nanoTime()
            val ended = h.playToEnd(plan.durUs / 1000 + 15_000)
            val wallMs = (System.nanoTime() - t0) / 1e6
            val check = Scenarios.check(plan, probe.frames.toList(), times, seqs)
            val rendered = h.rendered.filter { it.wallNs >= t0 }
            val maxK = GridTime.frameIndexNearest(probe.frames.maxOfOrNull { it.ptsUs } ?: -1, fps)
            // First secondary boundary (any layer edge after 0 in sequences 1..3).
            val firstEdge = plan.layers.flatMap { listOf(it.k0, it.k1) }.filter { it in 1 until plan.durFrames }.min()
            Results.write(
                "VN18_playback_$fps",
                JSONObject().put("fps", fps).put("ended", ended).put("wallMs", wallMs)
                    .put("compositionMs", plan.durUs / 1000)
                    .put("renderedFrames", rendered.size).put("expectedFrames", plan.durFrames)
                    .put("maxComposedK", maxK).put("firstSecondaryBoundaryK", firstEdge)
                    .put("droppedFrames", h.dropped.get()).put("barcode", check.json()),
            )
            assertTrue(check.mismatches.joinToString("\n"), check.mismatches.isEmpty())
            assertEquals(0, check.offGrid)
            if (ended) {
                assertEquals("every output frame composited", plan.durFrames.toInt(), check.distinctK)
            } else {
                // The documented stall: composition stops within half a second before the first
                // secondary boundary (a gap→item boundary stalls a few frames early).
                assertTrue("stall at $maxK, first boundary $firstEdge", maxK in firstEdge - fps / 2 until firstEdge)
            }
        }
    }

    /**
     * Grid-cut Transformer export with the ARCH image clock band. [gapFill] GAP is `addGap`;
     * TRANSPARENT_IMAGE fills secondary gaps with transparent image items at the output fps
     * (AND-01 finding: Media3 gap frames are sparser than the 60 fps grid, so its nearest
     * secondary-frame selection shows an item's first frame one output frame early).
     */
    private fun export(fps: Int, gapFill: GapFill = GapFill.GAP, epsilon: EpsilonMode = EpsilonMode.SHIFT_START_500, name: String = "VN18_export_$fps") {
        val plan = Scenarios.gridCut(fps)
        val store = ParamStore(plan.gridFps).apply { loadFrom(plan) }
        val probe = probeFor(plan)
        val times = TestMedia.videoSampleTimesUs("barcode_$fps.mp4")
        val c = mapper.build(plan, store, MapperOptions(probe = probe, gapFill = gapFill, epsilon = epsilon))
        val out = ExportHarness(ctx).export(c, File(TestMedia.outDir, "$name.mp4"))
        val composed = Scenarios.check(plan, probe.frames.toList(), times, seqs)
        // The encoded file decoded again through the same probe (catches encoder/muxer timing).
        val decodedProbe = probeFor(plan)
        val decoded = ExportHarness(ctx).probeFile(out.file, decodedProbe)
        val decodedCheck = Scenarios.check(plan, decoded, times, seqs)
        Results.write(
            name,
            JSONObject().put("fps", fps).put("gapFill", gapFill.name).put("epsilon", epsilon.name)
                .put("exportFrames", out.result.videoFrameCount).put("wallMs", out.wallMs)
                .put("composed", composed.json()).put("decodedOutput", decodedCheck.json()),
        )
        assertEquals(plan.durFrames.toInt(), out.result.videoFrameCount)
        assertTrue(composed.mismatches.joinToString("\n"), composed.mismatches.isEmpty())
        assertTrue(decodedCheck.mismatches.joinToString("\n"), decodedCheck.mismatches.isEmpty())
        assertEquals(plan.durFrames.toInt(), decodedCheck.distinctK)
    }

    @Test fun playbackBarcode24_vn18() = playback(24)
    @Test fun playbackBarcode30_vn18() = playback(30)
    @Test fun playbackBarcode60_vn18() = playback(60)
    @Test fun exportBarcode24_vn18() = export(24)
    @Test fun exportBarcode30_vn18() = export(30)
    @Test fun exportBarcode60_vn18() = export(60)

    /** The mechanisms AND-08/AND-11 adopt: transparent-image gap fill + rule-frame clip starts. */
    @Test fun exportBarcode24_gapFill_vn18() = export(24, GapFill.TRANSPARENT_IMAGE, EpsilonMode.SNAP_TO_RULE_FRAME, "VN18_export_gapfill_24")
    @Test fun exportBarcode30_gapFill_vn18() = export(30, GapFill.TRANSPARENT_IMAGE, EpsilonMode.SNAP_TO_RULE_FRAME, "VN18_export_gapfill_30")
    @Test fun exportBarcode60_gapFill_vn18() = export(60, GapFill.TRANSPARENT_IMAGE, EpsilonMode.SNAP_TO_RULE_FRAME, "VN18_export_gapfill_60")

    companion object {
        /** Measured by [seekSemantics_vn18]; becomes frame_grid.json's `androidSeekMsRounding` (ENG-06). */
        const val SEEK_ROUNDING = "floor"

        fun seekMs(k: Long, fps: Int): Long =
            if (SEEK_ROUNDING == "ceil") GridTime.platformMsCeil(k, fps) else GridTime.platformMsFloor(k, fps)
    }
}
