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

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(url: URL) {
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
    private var fileURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("follow_read.m4a")
    }

    func toggleRecord() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
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
