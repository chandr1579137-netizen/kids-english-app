import Foundation
import AVFoundation
import SwiftUI

/// 音频播放器：支持逐词高亮（通过定时器回调当前播放时间）
@Observable
class AudioPlayer {
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var onTimeUpdate: ((Double) -> Void)?
    /// 来电/闹钟等中断结束后是否需要恢复播放
    private var interruptionObserver: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

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

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
    }

    func play(url: URL, rate: Float = 1.0) {
        stop()
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

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
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
    /// 麦克风权限被拒：界面据此提示「去设置」，而不是点了没反应
    var permissionDenied = false
    private var fileURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("follow_read.m4a")
    }

    func toggleRecord() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        if session.recordPermission == .denied {
            permissionDenied = true
            return
        }
        permissionDenied = false
        try? session.setCategory(.playAndRecord, mode: .default)
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
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playBack() {
        guard hasRecording else { return }
        player = try? AVAudioPlayer(contentsOf: fileURL)
        player?.play()
        isPlayingBack = true
        // 简单起见：按录音时长后重置状态
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
