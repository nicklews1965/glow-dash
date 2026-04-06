import AVFoundation
import SpriteKit
import UIKit

/// Manages sound effects (synthesized) and haptic feedback.
/// Sounds are generated programmatically — no external audio files needed.
@MainActor
final class AudioManager {

    static let shared = AudioManager()

    private(set) var isSoundMuted: Bool {
        didSet { UserDefaults.standard.set(isSoundMuted, forKey: GameConstants.soundMutedKey) }
    }
    private(set) var isHapticMuted: Bool {
        didSet { UserDefaults.standard.set(isHapticMuted, forKey: GameConstants.hapticMutedKey) }
    }

    // Pre-generated audio players for each sound type
    private var flapPlayers: [AVAudioPlayer] = []
    private var scorePlayers: [AVAudioPlayer] = []
    private var hitPlayer: AVAudioPlayer?

    private var flapIndex: Int = 0
    private var scoreIndex: Int = 0

    private init() {
        // Load persisted preferences
        isSoundMuted = UserDefaults.standard.bool(forKey: GameConstants.soundMutedKey)
        isHapticMuted = UserDefaults.standard.bool(forKey: GameConstants.hapticMutedKey)
        configureAudioSession()
        generateSounds()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio will just not work — game still plays fine
        }
    }

    // MARK: - Sound Generation

    private func generateSounds() {
        // Create a pool of players for overlapping sounds
        for _ in 0..<3 {
            if let data = SoundSynthesizer.generateFlapSound() {
                if let player = try? AVAudioPlayer(data: data) {
                    player.volume = GameConstants.soundVolume
                    player.prepareToPlay()
                    flapPlayers.append(player)
                }
            }
        }

        for _ in 0..<3 {
            if let data = SoundSynthesizer.generateScoreSound() {
                if let player = try? AVAudioPlayer(data: data) {
                    player.volume = GameConstants.soundVolume
                    player.prepareToPlay()
                    scorePlayers.append(player)
                }
            }
        }

        if let data = SoundSynthesizer.generateHitSound() {
            hitPlayer = try? AVAudioPlayer(data: data)
            hitPlayer?.volume = GameConstants.soundVolume * 1.2
            hitPlayer?.prepareToPlay()
        }
    }

    // MARK: - Playback

    func playFlap() {
        guard !isSoundMuted, !flapPlayers.isEmpty else { return }
        let player = flapPlayers[flapIndex % flapPlayers.count]
        flapIndex += 1
        player.currentTime = 0
        player.play()
    }

    func playScore() {
        guard !isSoundMuted, !scorePlayers.isEmpty else { return }
        let player = scorePlayers[scoreIndex % scorePlayers.count]
        scoreIndex += 1
        player.currentTime = 0
        player.play()
    }

    func playHit() {
        guard !isSoundMuted else { return }
        hitPlayer?.currentTime = 0
        hitPlayer?.play()
    }

    // MARK: - Haptics

    func playTapHaptic() {
        guard !isHapticMuted else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func playScoreHaptic() {
        guard !isHapticMuted else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func playHitHaptic() {
        guard !isHapticMuted else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func playHighScoreHaptic() {
        guard !isHapticMuted else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Toggles

    func toggleSound() { isSoundMuted = !isSoundMuted }
    func toggleHaptics() { isHapticMuted = !isHapticMuted }
}

// MARK: - Sound Synthesizer

/// Generates simple PCM audio waveforms as WAV-format Data objects.
private enum SoundSynthesizer {

    private static let sampleRate = GameConstants.audioSampleRate

    /// Chirp sweep sound for flapping.
    static func generateFlapSound() -> Data? {
        let duration = GameConstants.flapSoundDuration
        let startFreq = GameConstants.flapSoundFreqStart
        let endFreq = GameConstants.flapSoundFreqEnd
        let sampleCount = Int(sampleRate * duration)

        var samples = [Int16](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let freq = startFreq + (endFreq - startFreq) * progress
            let envelope = 1.0 - progress  // fade out
            let value = sin(2.0 * .pi * freq * t) * envelope * 0.6
            samples[i] = Int16(clamping: Int(value * Double(Int16.max)))
        }
        return wavData(from: samples)
    }

    /// Pleasant two-tone ding for scoring.
    static func generateScoreSound() -> Data? {
        let duration = GameConstants.scoreSoundDuration
        let freq1 = GameConstants.scoreSoundFreq1
        let freq2 = GameConstants.scoreSoundFreq2
        let sampleCount = Int(sampleRate * duration)

        var samples = [Int16](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let envelope = (1.0 - progress) * (1.0 - progress)  // quadratic fade
            let value = (sin(2.0 * .pi * freq1 * t) + sin(2.0 * .pi * freq2 * t)) * 0.35 * envelope
            samples[i] = Int16(clamping: Int(value * Double(Int16.max)))
        }
        return wavData(from: samples)
    }

    /// Low thud for collision / death.
    static func generateHitSound() -> Data? {
        let duration = GameConstants.hitSoundDuration
        let freq = GameConstants.hitSoundFreq
        let sampleCount = Int(sampleRate * duration)

        var samples = [Int16](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let progress = t / duration
            // Exponential decay with some noise
            let envelope = exp(-progress * 8.0)
            let noise = Double.random(in: -0.15...0.15)
            let value = (sin(2.0 * .pi * freq * t) + noise) * envelope * 0.7
            samples[i] = Int16(clamping: Int(value * Double(Int16.max)))
        }
        return wavData(from: samples)
    }

    /// Wraps 16-bit PCM samples into a WAV file Data object.
    private static func wavData(from samples: [Int16]) -> Data? {
        let dataSize = samples.count * 2  // 2 bytes per Int16
        let fileSize = 44 + dataSize

        var data = Data(capacity: fileSize)

        // RIFF header
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46])  // "RIFF"
        data.append(littleEndian: UInt32(fileSize - 8))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45])  // "WAVE"

        // fmt subchunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20])  // "fmt "
        data.append(littleEndian: UInt32(16))                // subchunk size
        data.append(littleEndian: UInt16(1))                 // PCM format
        data.append(littleEndian: UInt16(1))                 // mono
        data.append(littleEndian: UInt32(UInt32(sampleRate)))
        data.append(littleEndian: UInt32(UInt32(sampleRate) * 2))  // byte rate
        data.append(littleEndian: UInt16(2))                 // block align
        data.append(littleEndian: UInt16(16))                // bits per sample

        // data subchunk
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61])  // "data"
        data.append(littleEndian: UInt32(dataSize))

        for sample in samples {
            data.append(littleEndian: sample)
        }

        return data
    }
}

// MARK: - Data Extension for Little-Endian Append

private extension Data {
    mutating func append(littleEndian value: UInt16) {
        var v = value.littleEndian
        append(UnsafeBufferPointer(start: &v, count: 1))
    }

    mutating func append(littleEndian value: UInt32) {
        var v = value.littleEndian
        append(UnsafeBufferPointer(start: &v, count: 1))
    }

    mutating func append(littleEndian value: Int16) {
        var v = value.littleEndian
        append(UnsafeBufferPointer(start: &v, count: 1))
    }
}
