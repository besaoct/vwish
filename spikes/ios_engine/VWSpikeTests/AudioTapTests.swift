import AVFoundation
import XCTest

@testable import VWSpikeHost

/// V-N21 / D-37: an `MTAudioProcessingTap` on a composition audio track sees composition-time
/// ranges after `scaleTimeRange`, and a gain of 2.0 measures +6.02 ± 0.1 dB, both through
/// `AVAssetReaderAudioMixOutput` (export) and in `AVPlayer` (preview).
final class AudioTapTests: XCTestCase {
  static let toneDbfs = -12.0
  /// RMS of a sine at peak −12 dBFS: −12 − 3.0103 dB.
  static let toneRmsDb = toneDbfs - 10 * log10(2)
  static let expectedGainDb = 20 * log10(2.0)  // 6.0206

  private func tone() throws -> URL {
    try MediaFactory.tone(name: "tone_1k_m12.wav", hz: 1000, dbfs: Self.toneDbfs, seconds: 8)
  }

  /// Checks the ranges handed to the tap: contiguous, starting at 0, covering the 4 s composition
  /// (source times would jump to 3 s and 6 s and cover 4 s of source in other places).
  private func checkCompositionRanges(_ calls: [GainTapProbe.Call], total: Double) -> [String] {
    var problems: [String] = []
    guard let first = calls.first else { return ["tap never called"] }
    if abs(first.start.seconds) > 0.001 { problems.append("first range starts at \(first.start.seconds)") }
    var expectedStart = first.start
    for c in calls {
      guard c.start.isNumeric else {
        problems.append("non-numeric range")
        continue
      }
      if abs(CMTimeSubtract(c.start, expectedStart).seconds) > 0.0005 {
        problems.append(String(format: "gap/jump at %.4f (expected %.4f)", c.start.seconds, expectedStart.seconds))
      }
      expectedStart = CMTimeAdd(c.start, c.duration)
      if c.start.seconds > total + 0.05 { problems.append("range beyond composition: \(c.start.seconds)") }
    }
    if abs(expectedStart.seconds - total) > 0.05 {
      problems.append(String(format: "ranges end at %.4f, composition is %.1f s", expectedStart.seconds, total))
    }
    return Array(problems.prefix(10))
  }

  func testTapInAssetReaderAudioMixOutput() async throws {
    let url = try tone()
    func run(gain: Float) async throws -> ([Float], GainTapProbe) {
      let probe = GainTapProbe(gain: gain)
      let (comp, mix) = try await AudioCompositionSpec.build(
        tone: url, segments: AudioCompositionSpec.standard, tap: probe.makeTap())
      return (try AudioCompositionSpec.readMix(comp, mix: mix), probe)
    }
    let (unity, _) = try await run(gain: 1)
    let (doubled, probe) = try await run(gain: 2)
    XCTAssertEqual(unity.count, doubled.count)
    XCTAssertEqual(Double(doubled.count) / 48_000, 4, accuracy: 0.01)

    // Level: the 1× segment [0.1, 0.9) s, and the 0.5×/2× segments too.
    func db(_ x: [Float], _ a: Double, _ b: Double) -> Double {
      AudioCompositionSpec.rmsDb(x[Int(a * 48_000)..<Int(b * 48_000)])
    }
    var deltas: [String: Double] = [:]
    for (name, a, b) in [("1x", 0.1, 0.9), ("2x", 1.1, 1.9), ("0.5x", 2.1, 3.9)] {
      let d = db(doubled, a, b) - db(unity, a, b)
      deltas[name] = Stats.round2(d * 1000) / 1000
      XCTAssertEqual(d, Self.expectedGainDb, accuracy: 0.1, "\(name) segment gain \(d) dB")
    }
    let segLevels: [String: [Double]] = Dictionary(uniqueKeysWithValues: [("1x", 0.1, 0.9), ("2x", 1.1, 1.9), ("0.5x", 2.1, 3.9)].map {
      ($0.0, [Stats.round2(db(unity, $0.1, $0.2)), Stats.round2(db(doubled, $0.1, $0.2))])
    })
    let detail = probe.calls.filter { (0.95...1.12).contains($0.start.seconds) || (1.95...2.08).contains($0.start.seconds) }
      .map { c in
        "s=\(String(format: "%.5f", c.start.seconds)) d=\(String(format: "%.5f", c.duration.seconds)) req=\(c.requested) got=\(c.provided) f=\(c.flags)"
      }
    let absolute = db(doubled, 0.1, 0.9)
    XCTAssertEqual(absolute, Self.toneRmsDb + Self.expectedGainDb, accuracy: 0.1)
    let peak = doubled.map { abs($0) }.max() ?? 0
    let problems = checkCompositionRanges(probe.calls, total: 4)
    XCTAssertEqual(problems, [])
    Metrics.record(
      "V-N21.reader",
      [
        "gainDeltaDb": deltas, "absoluteRmsDb1x": Stats.round2(absolute),
        "expectedRmsDb": Stats.round2(Self.toneRmsDb + Self.expectedGainDb),
        "peakLinear": Stats.round2(Double(peak)), "tapCalls": probe.calls.count,
        "tapMaxFrames": probe.maxFrames, "tapSampleRate": probe.format.mSampleRate,
        "tapChannels": probe.format.mChannelsPerFrame,
        "tapFloat": probe.format.mFormatFlags & kAudioFormatFlagIsFloat != 0,
        "tapNonInterleaved": probe.format.mFormatFlags & kAudioFormatFlagIsNonInterleaved != 0,
        "firstRanges": probe.calls.prefix(3).map { [Stats.round2($0.start.seconds * 1000), Stats.round2($0.duration.seconds * 1000)] },
        "rangeProblems": problems, "segmentRmsDb[unity,doubled]": segLevels, "callsNearSeams": detail,
        "frames[unity,doubled]": [unity.count, doubled.count],
      ])
  }

  /// AVPlayer preview: what the tap sees while the composition plays in real time (time ranges,
  /// flags) and the level it hands on: the input arrives at the source level (nothing attenuates
  /// before the tap) and leaves +6.02 dB louder. Run for post-effects and pre-effects taps.
  func testTapInAVPlayer() async throws {
    var results: [String: Any] = [:]
    for pre in [false, true] {
      let r = try await playThroughAVPlayer(preEffects: pre)
      results[pre ? "preEffects" : "postEffects"] = r
    }
    Metrics.record("V-N21.avplayer", results)
  }

  private func playThroughAVPlayer(preEffects: Bool) async throws -> [String: Any] {
    let url = try tone()
    let probe = GainTapProbe(gain: 2, preEffects: preEffects)
    let (comp, mix) = try await AudioCompositionSpec.build(
      tone: url, segments: AudioCompositionSpec.standard, tap: probe.makeTap())
    let item = AVPlayerItem(asset: comp)
    item.audioMix = mix
    item.audioTimePitchAlgorithm = .spectral
    let player = AVPlayer(playerItem: item)
    player.automaticallyWaitsToMinimizeStalling = false
    player.volume = 0.05  // output volume is applied after the mix; keeps the test quiet
    let deadline = Date().addingTimeInterval(10)
    while item.status != .readyToPlay, Date() < deadline { try await Task.sleep(nanoseconds: 10_000_000) }
    XCTAssertEqual(item.status, .readyToPlay)
    let host0 = mach_absolute_time()
    player.play()
    var clock: [(host: UInt64, item: Double)] = []
    while CMTimeGetSeconds(item.currentTime()) < 3.0, Date() < deadline.addingTimeInterval(6) {
      clock.append((mach_absolute_time(), item.currentTime().seconds))
      try await Task.sleep(nanoseconds: 20_000_000)
    }
    player.pause()
    let calls = probe.calls
    XCTAssertFalse(calls.isEmpty, "tap not called in AVPlayer")
    let valid = calls.filter { $0.start.isNumeric }
    // Level over the steady state (skip the first 5 calls of the ramp-up).
    let steady = calls.dropFirst(5).filter { $0.samples > 0 }
    let preSum = steady.reduce(0) { $0 + $1.preSumSq }
    let postSum = steady.reduce(0) { $0 + $1.postSumSq }
    let n = Double(steady.reduce(0) { $0 + $1.samples })
    let preDb = 10 * log10(preSum / max(n, 1))
    let postDb = 10 * log10(postSum / max(n, 1))
    XCTAssertEqual(postDb - preDb, Self.expectedGainDb, accuracy: 0.1)
    XCTAssertEqual(preDb, Self.toneRmsDb, accuracy: 0.5, "tap input is not at the source level")
    // How far ahead of the player clock the tap runs (frames counted from the first call).
    var info: [String: Any] = [
      "calls": calls.count, "validRanges": valid.count,
      "firstRanges": calls.prefix(4).map { "\($0.start.isNumeric ? String(format: "%.4f", $0.start.seconds) : "invalid")+\($0.duration.isNumeric ? String(format: "%.4f", $0.duration.seconds) : "invalid") req=\($0.requested) got=\($0.provided) f=\($0.flags)" },
      "flagsSeen": Array(Set(calls.map(\.flags))).sorted(),
      "gainDeltaDb": Stats.round2(postDb - preDb), "tapInputRmsDb": Stats.round2(preDb),
      "expectedInputRmsDb": Stats.round2(Self.toneRmsDb),
      "framesPerCall": calls.dropFirst(5).first?.requested ?? 0,
    ]
    if !valid.isEmpty {
      let starts = valid.map(\.start.seconds)
      info["maxStart"] = Stats.round2(starts.max() ?? 0)
      info["monotonic"] = zip(starts, starts.dropFirst()).allSatisfy { $1 >= $0 }
      info["callsIn2xSegment"] = valid.filter { $0.start.seconds >= 1 && $0.start.seconds < 2 }.count
    }
    // Tap lead over the player clock: samples processed by the tap vs item time at that host time.
    var timebase = mach_timebase_info()
    mach_timebase_info(&timebase)
    func secs(_ h: UInt64) -> Double { Double(h - host0) * Double(timebase.numer) / Double(timebase.denom) / 1e9 }
    var processed = 0.0
    var leads: [Double] = []
    for c in calls {
      processed += Double(c.provided) / 48_000
      if let near = clock.min(by: { abs(secs($0.host) - secs(c.hostTime)) < abs(secs($1.host) - secs(c.hostTime)) }),
        near.item > 0.3, near.item < 0.9
      {
        leads.append((processed - near.item) * 1000)
      }
    }
    info["tapLeadMsP50(1x segment)"] = Stats.round2(Stats.percentile(leads, 50))
    return info
  }

  /// The pre-D-37 path: does AVAudioMix volume above 1 amplify in AVAssetReaderAudioMixOutput?
  func testMixVolumeAboveOneIsNotApplied() async throws {
    let url = try tone()
    let (comp, mix) = try await AudioCompositionSpec.build(
      tone: url, segments: [AudioCompositionSpec.standard[0]], tap: nil)
    let unity = try AudioCompositionSpec.readMix(comp, mix: mix)
    let params = mix.inputParameters.first as! AVMutableAudioMixInputParameters
    params.setVolume(2, at: .zero)
    let loud = try AudioCompositionSpec.readMix(comp, mix: mix)
    let d =
      AudioCompositionSpec.rmsDb(loud[4800..<43200]) - AudioCompositionSpec.rmsDb(unity[4800..<43200])
    // Fact finding (no assertion on the direction): D-37 assumed volume > 1 is not applied.
    Metrics.record("D-37.mixVolume2", ["deltaDb": Stats.round2(d), "amplifies": d > 1])
  }
}
