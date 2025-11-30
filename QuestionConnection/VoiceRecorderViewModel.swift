import Foundation
import AVFoundation
import Combine

class VoiceRecorderViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioData: Data? = nil
    @Published var permissionGranted = false
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            permissionGranted = true
        case .denied:
            permissionGranted = false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    self.permissionGranted = allowed
                }
            }
        @unknown default:
            break
        }
    }
    
    func startRecording() {
        guard permissionGranted else { return }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        let fileName = "temp_recording.m4a"
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = docPath.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            audioData = nil
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.recordingTime += 0.1
            }
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        isRecording = false
        
        guard let url = audioRecorder?.url else { return }
        
        do {
            let data = try Data(contentsOf: url)
            self.audioData = data
            print("Recording finished. Data size: \(data.count) bytes")
        } catch {
            print("Failed to load audio data: \(error)")
        }
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        isRecording = false
        recordingTime = 0
        audioData = nil
        
        if let url = audioRecorder?.url {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
        }
    }
}
