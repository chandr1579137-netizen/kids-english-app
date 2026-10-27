import Foundation
import AVFoundation
import SwiftUI

/// 音频会话统一入口。
///
/// 之前播放器与录音器各自 setCategory：跟读结束若没切回 playback，
/// 外放会停在 playAndRecord（听感明显偏小），表现为「一会儿大声一会儿小声」。
enum AudioSession {
    static func configurePlayback() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    static func configureRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default,
                                 options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)
    }
}

private final class SpeechFallbackDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
}

/// 音频播放器：支持逐词高亮（通过定时器回调当前播放时间）
@Observable
class AudioPlayer {
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private let speech = AVSpeechSynthesizer()
    private let speechDelegate = SpeechFallbackDelegate()
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var onTimeUpdate: ((Double) -> Void)?
    /// 来电/闹钟等中断结束后是否需要恢复播放
    private var interruptionObserver: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?

    init() {
        AudioSession.configurePlayback()
        speech.delegate = speechDelegate
        speechDelegate.onFinish = { [weak self] in self?.isPlaying = false }

        // 中断（来电、闹钟、其他 App 抢音频）：开始时暂停，结束后按系统建议恢复，
        // 否则孩子会以为「点了没反应」，其实播放器卡在中断状态里。
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let self,
                  let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            switch type {
            case .began:
                self.player?.pause()
                self.isPlaying = false
            case .ended:
                let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                if AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                    try? AVAudioSession.sharedInstance().setActive(true)
                    self.player?.play()
                    self.isPlaying = true
                }
            @unknown default:
                break
            }
        }

        // 拔耳机：继续外放会吓到孩子，直接暂停
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let self,
                  let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
            self.player?.pause()
            self.isPlaying = false
        }
    }

    func play(url: URL, rate: Float = 1.0) {
        stop()
        // 录音后立刻播放时，会话可能还停在 playAndRecord：每次播放前都重新声明一次
        AudioSession.configurePlayback()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        duration = 0
        // 时长未知时用 asset 加载
        Task {
            if let d = try? await item.asset.load(.duration) {
                await MainActor.run { self.duration = CMTimeGetSeconds(d) }
            }
        }
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            let t = CMTimeGetSeconds(time)
            self.currentTime = t
            self.onTimeUpdate?(t)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item, queue: .main
        ) { [weak self] _ in
            self?.stop()
            self?.onTimeUpdate?(999999)  // 通知播放结束
        }
        player?.play()
        // 慢速复用同一条音频：AVPlayer 支持变速，不需要预生成文件
        player?.rate = rate
        isPlaying = true
    }

    /// 优先播物理存在的预生成音频；文件不存在或极端离线时无缝自动退回系统原生合成发音（支持中英双语智能分流），杜绝哑音
    func playWord(_ word: String, url: URL?, rate: Float = 1.0) {
        if let url, FileManager.default.fileExists(atPath: url.path) {
            play(url: url, rate: rate)
        } else {
            speak(word, rate: rate)
        }
    }

    func speak(_ text: String, rate: Float = 1.0) {
        stop()
        AudioSession.configurePlayback()
        let utterance = AVSpeechUtterance(string: text)
        let isChinese = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
        utterance.voice = AVSpeechSynthesisVoice(language: isChinese ? "zh-CN" : "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
        speech.speak(utterance)
        duration = 0
        isPlaying = true
    }

    func pause() {
        player?.pause()
        speech.pauseSpeaking(at: .immediate)
        isPlaying = false
    }

    func resume() {
        player?.play()
        if speech.isPaused {
            speech.continueSpeaking()
        }
        isPlaying = true
    }

    func stop() {
        speech.stopSpeaking(at: .immediate)
        if let o = timeObserver {
            player?.removeTimeObserver(o)
            timeObserver = nil
        }
        if let o = endObserver {
            NotificationCenter.default.removeObserver(o)
            endObserver = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
    }

    deinit {
        if let o = timeObserver { player?.removeTimeObserver(o) }
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
    }
}

/// 跟读录音器（按「课文 + 段落」分别保存）
///
/// 之前全 App 只有一个共享临时文件：任何一段的「回放」都播最后录的那一段，
/// 而且录过一次后所有段落都显示可回放。
@Observable
class Recorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var playback: AVAudioPlayer?
    private var currentKey: String?
    private(set) var recordedKeys: Set<String> = []
    var isRecording = false
    var isPlayingBack = false
    /// 麦克风权限被拒：界面据此提示「去设置」，而不是点了没反应
    var permissionDenied = false

    private func fileURL(for key: String) -> URL {
        let safe = key
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("follow_\(safe).m4a")
    }

    func hasRecording(for key: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: key).path)
    }

    func toggleRecord(for key: String) {
        if isRecording && currentKey == key {
            stopRecording()
        } else {
            startRecording(for: key)
        }
    }

    private func startRecording(for key: String) {
        if isRecording { stopRecording() }
        let session = AVAudioSession.sharedInstance()
        if session.recordPermission == .denied {
            permissionDenied = true
            return
        }
        permissionDenied = false
        AudioSession.configureRecording()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
        ]
        currentKey = key
        recorder = try? AVAudioRecorder(url: fileURL(for: key), settings: settings)
        recorder?.delegate = self
        recorder?.record()
        isRecording = true
    }

    private func stopRecording() {
        recorder?.stop()
        isRecording = false
        if let key = currentKey, hasRecording(for: key) {
            recordedKeys.insert(key)
        }
        currentKey = nil
        // 录音会把会话切成 playAndRecord，录完立刻切回播放，否则后面朗读音量偏小
        AudioSession.configurePlayback()
    }

    func playBack(for key: String) {
        guard hasRecording(for: key) else { return }
        AudioSession.configurePlayback()
        playback = try? AVAudioPlayer(contentsOf: fileURL(for: key))
        playback?.play()
        isPlayingBack = true
        let duration = playback?.duration ?? 1
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.3) { [weak self] in
            self?.isPlayingBack = false
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        if flag, let key = currentKey, hasRecording(for: key) {
            recordedKeys.insert(key)
        }
        currentKey = nil
    }
}
