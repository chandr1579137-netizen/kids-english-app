import Foundation
import AVFoundation
import SwiftUI

/// 把系统朗读结束回调从播放器本体拆出来，避免 @Observable 去继承 NSObject。
private final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.onFinish?()
        }
    }
}

/// 全局只有一个播放器：新的播放会停掉上一段，页面消失时调用 stop()。
/// 本地 mp3 会等 AVPlayerItem 就绪再出声；缺失或解码失败时用系统语音兜底。
/// 慢速用 rate 0.75，并用 timeDomain 尽量保住音高。
@Observable
final class AudioPlayer {
    static let shared = AudioPlayer()

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var statusObs: NSKeyValueObservation?
    private let synth = AVSpeechSynthesizer()
    private let speechDelegate = SpeechDelegate()
    private var generation = 0
    private var inTick = false
    private var wantedRate: Float = 1

    private var lineQueue: [String] = []
    private var lineCursor = 0
    private var lineCallback: ((Int) -> Void)?
    private var speechSlow = false

    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var onTimeUpdate: ((Double) -> Void)?
    var onFinish: (() -> Void)?

    private init() {
        synth.delegate = speechDelegate
        activateSession()
    }

    // MARK: - 对外

    /// 播放本地文件。文件不存在或失败时朗读 spokenFallback。
    func play(url: URL?, rate: Float = 1.0, spokenFallback: String? = nil) {
        let finish = onFinish
        let tick = onTimeUpdate
        teardown()
        onFinish = finish
        onTimeUpdate = tick
        wantedRate = rate
        if let url, FileManager.default.fileExists(atPath: url.path) {
            beginFile(url, rate: rate, spokenFallback: spokenFallback)
        } else if let spokenFallback, !spokenFallback.isEmpty {
            beginSpeech(spokenFallback, rate: rate)
        }
    }

    func speak(_ text: String, rate: Float = 1) {
        let finish = onFinish
        teardown()
        onFinish = finish
        beginSpeech(text, rate: rate)
    }

    /// 逐行朗读（儿歌没有 mp3 时）。onLine 在每一行开始时回调。
    func playLines(_ lines: [String], slow: Bool = false, onLine: ((Int) -> Void)? = nil, onFinish: (() -> Void)? = nil) {
        teardown()
        let clean = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !clean.isEmpty else {
            onFinish?()
            return
        }
        lineQueue = clean
        lineCursor = 0
        lineCallback = onLine
        speechSlow = slow
        self.onFinish = onFinish
        speechDelegate.onFinish = { [weak self] in
            self?.advanceLine()
        }
        beginSpeechLine()
    }

    func pause() {
        player?.pause()
        synth.pauseSpeaking(at: .immediate)
        isPlaying = false
    }

    func resume() {
        if player != nil {
            player?.playImmediately(atRate: wantedRate)
            isPlaying = true
        } else if synth.isPaused {
            synth.continueSpeaking()
            isPlaying = true
        }
    }

    func stop() {
        teardown()
    }

    // MARK: - 文件

    private func beginFile(_ url: URL, rate: Float, spokenFallback: String?) {
        activateSession()
        generation += 1
        let gen = generation
        let item = AVPlayerItem(url: url)
        item.audioTimePitchAlgorithm = .timeDomain
        let av = AVPlayer(playerItem: item)
        av.automaticallyWaitsToMinimizeStalling = false
        player = av
        duration = 0
        currentTime = 0

        Task { @MainActor in
            if let d = try? await item.asset.load(.duration) {
                let seconds = CMTimeGetSeconds(d)
                if seconds.isFinite { self.duration = seconds }
            }
        }

        statusObs = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self, self.generation == gen else { return }
                if item.status == .readyToPlay {
                    av.playImmediately(atRate: rate)
                    self.isPlaying = true
                } else if item.status == .failed {
                    let text = spokenFallback
                    let finish = self.onFinish
                    let tick = self.onTimeUpdate
                    self.teardown()
                    self.onFinish = finish
                    self.onTimeUpdate = tick
                    if let text, !text.isEmpty {
                        self.beginSpeech(text, rate: rate)
                    }
                }
            }
        }

        timeObserver = av.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self, self.generation == gen else { return }
            self.inTick = true
            let t = CMTimeGetSeconds(time)
            if t.isFinite {
                self.currentTime = t
                self.onTimeUpdate?(t)
            }
            self.inTick = false
            self.flushDeferredTeardown()
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.generation == gen else { return }
                let cb = self.onFinish
                self.teardown()
                cb?()
            }
        }
    }

    // MARK: - 语音

    private func beginSpeech(_ text: String, rate: Float) {
        activateSession()
        generation += 1
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = speechRate(for: rate)
        speechDelegate.onFinish = { [weak self] in
            guard let self else { return }
            let cb = self.onFinish
            self.isPlaying = false
            self.onFinish = nil
            cb?()
        }
        synth.speak(utterance)
        isPlaying = true
    }

    private func beginSpeechLine() {
        guard lineCursor < lineQueue.count else {
            let cb = onFinish
            onFinish = nil
            lineCallback = nil
            speechDelegate.onFinish = nil
            isPlaying = false
            cb?()
            return
        }
        activateSession()
        lineCallback?(lineCursor)
        let utterance = AVSpeechUtterance(string: lineQueue[lineCursor])
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = speechSlow ? 0.34 : 0.48
        synth.speak(utterance)
        isPlaying = true
    }

    private func advanceLine() {
        guard !lineQueue.isEmpty else { return }
        lineCursor += 1
        beginSpeechLine()
    }

    private func speechRate(for rate: Float) -> Float {
        rate < 0.9 ? 0.34 : 0.48
    }

    // MARK: - 停止

    private var deferredPlayer: AVPlayer?
    private var deferredObserver: Any?

    private func teardown() {
        generation += 1
        speechDelegate.onFinish = nil
        lineQueue = []
        lineCursor = 0
        lineCallback = nil
        synth.stopSpeaking(at: .immediate)
        statusObs?.invalidate()
        statusObs = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let timeObserver {
            if inTick {
                deferredPlayer = player
                deferredObserver = timeObserver
            } else {
                player?.removeTimeObserver(timeObserver)
            }
            self.timeObserver = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        onFinish = nil
        onTimeUpdate = nil
    }

    private func flushDeferredTeardown() {
        if let obs = deferredObserver {
            deferredPlayer?.removeTimeObserver(obs)
        }
        deferredObserver = nil
        deferredPlayer = nil
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    deinit {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
        }
        if let obs = deferredObserver {
            deferredPlayer?.removeTimeObserver(obs)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        player?.pause()
        synth.stopSpeaking(at: .immediate)
    }
}

/// 跟读录音器
@Observable
class Recorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    var isRecording = false
    var hasRecording = false
    var isPlayingBack = false
    private var fileURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("follow_read.m4a")
    }

    func toggleRecord() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        AudioPlayer.shared.stop()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
        ]
        recorder = try? AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.delegate = self
        recorder?.record()
        isRecording = true
        hasRecording = false
    }

    private func stopRecording() {
        recorder?.stop()
        isRecording = false
        hasRecording = FileManager.default.fileExists(atPath: fileURL.path)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playBack() {
        guard hasRecording else { return }
        AudioPlayer.shared.stop()
        player = try? AVAudioPlayer(contentsOf: fileURL)
        player?.play()
        isPlayingBack = true
        let dur = player?.duration ?? 1
        DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.3) { [weak self] in
            self?.isPlayingBack = false
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        hasRecording = flag
    }
}
