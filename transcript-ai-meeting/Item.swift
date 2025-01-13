//
//  Item.swift
//  transcript-ai-meeting
//
//  Created by Ali Siddique on 1/13/25.
//

import Foundation
import SwiftData
import SwiftUI
import AVFoundation
// MARK: - Response Models
struct AudioUploadResponse: Codable {
    let success: Bool
    let data: AudioResponseData
}
struct AudioFile: Identifiable, Codable {
    let id: UUID
    let studySetId: UUID
    let title: String
    let description: String?
    let fileUrl: String
    let storagePath: String
    let transcription: String?
    let createdAt: Date
    let transcript_array: [AudiTranscriptLine]?


    enum CodingKeys: String, CodingKey {
        case id
        case studySetId = "study_set_id"
        case title
        case description
        case fileUrl = "file_url"
        case storagePath = "storage_path"
        case transcription
        case createdAt = "created_at"
        case transcript_array
    }
}

struct AudiTranscriptLine: Codable, Hashable {
    let text: String
    let timestamp: [Double]
    
    enum CodingKeys: String, CodingKey {
        case text
        case timestamp = "timestamp"
    }
}
struct AudioResponseData: Codable {
    let id: String
    let title: String
    let description: String?
    let file_url: String
    let transcription: String?
    let transcript_array: [AudiTranscriptLine]?
}


extension AudioFile {
    init(from response: AudioResponseData, studySetId: UUID) {
        self.id = UUID(uuidString: response.id)!
        self.studySetId = studySetId
        self.title = response.title
        self.description = response.description
        self.fileUrl = response.file_url
        self.storagePath = response.file_url // Using file_url as storage path since it's not in response
        self.transcription = response.transcription
        self.createdAt = Date() // Using current date since it's not in response
        self.transcript_array = response.transcript_array
    }
}

// MARK: - Audio Recording ViewModel
class AudioRecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isUploading = false
    @Published var recordingTitle = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showMinimumTimeAlert = false
    @Published var showAudioDetail = false
    @Published var uploadedAudio: AudioFile?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let minimumRecordingTime: TimeInterval = 20
    private let studySetId: UUID
    private let backendURL = "\(AppConfiguration.backendURL)/upload"
    
    init(studySetId: UUID) {
        self.studySetId = studySetId
        setupAudioSession()
        setupAudioRecorder()
        requestMicrophonePermission()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func toggleRecording() {
        if isRecording {
            if recordingTime < minimumRecordingTime {
                showMinimumTimeAlert = true
                return
            }
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
            recordingTime = 0
            startTimer()
        } catch {
            alertMessage = "Failed to start recording: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
    }
    
    func playRecording() {
        guard let url = audioRecorder?.url else { return }
        
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            do {
                if audioPlayer == nil {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    duration = audioPlayer?.duration ?? 0
                }
                
                audioPlayer?.play()
                isPlaying = true
                startPlaybackTimer()
            } catch {
                alertMessage = "Failed to play recording: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    func uploadRecording() {
        guard let audioURL = audioRecorder?.url else { return }
        isUploading = true
        
        var request = URLRequest(url: URL(string: backendURL)!)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        do {
            let audioData = try Data(contentsOf: audioURL)
            var body = Data()
            
            // Add metadata fields
            let metadata = [
                "studySetId": studySetId.uuidString,
                "title": recordingTitle,
                "description": ""
            ]
            
            // Add metadata fields to form data
            for (key, value) in metadata {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
            
            // Add audio file
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            URLSession.shared.uploadTask(with: request, from: body) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.isUploading = false
                    
                    if let error = error {
                        self?.alertMessage = "Upload failed: \(error.localizedDescription)"
                        self?.showAlert = true
                        return
                    }
                    
                    guard let data = data else {
                        self?.alertMessage = "No data received from server"
                        self?.showAlert = true
                        return
                    }
                    
                    // Replace the response handling section in uploadRecording()
                    do {
                        // Log raw response for debugging
                        if let rawResponse = String(data: data, encoding: .utf8) {
                            print("Raw API Response:", rawResponse)
                        }
                        
                        let response = try JSONDecoder().decode(AudioUploadResponse.self, from: data)
                        if response.success {
                            let audioFile = AudioFile(from: response.data, studySetId: self!.studySetId)
                            self?.uploadedAudio = audioFile
                            self?.showAudioDetail = true
                        } else {
                            self?.alertMessage = "Error saving audio recording"
                            self?.showAlert = true
                        }
                    } catch {
                        print("Decoding error:", error)
                        // Detailed error logging
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, _):
                                print("Missing key:", key)
                            case .typeMismatch(_, let context):
                                print("Type mismatch:", context)
                            case .valueNotFound(_, let context):
                                print("Value not found:", context)
                            default:
                                print("Other decoding error:", decodingError)
                            }
                        }
                        self?.alertMessage = "Failed to process response: \(error.localizedDescription)"
                        self?.showAlert = true
                    }
                }
            }.resume()
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isUploading = false
                self?.alertMessage = "Failed to prepare audio for upload: \(error.localizedDescription)"
                self?.showAlert = true
            }
        }
    }
    
    func skipForward() {
        guard let player = audioPlayer else { return }
        let newTime = min(duration, currentTime + 10)
        player.currentTime = newTime
        currentTime = newTime
    }
    
    func skipBackward() {
        guard let player = audioPlayer else { return }
        let newTime = max(0, currentTime - 10)
        player.currentTime = newTime
        currentTime = newTime
    }
    
    private func setupAudioRecorder() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            alertMessage = "Failed to setup audio recorder: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            if !allowed {
                self?.alertMessage = "Microphone access is required to record audio"
                self?.showAlert = true
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startPlaybackTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            
            self.currentTime = player.currentTime
            if !player.isPlaying {
                timer.invalidate()
                self.isPlaying = false
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - Audio Recorder View
struct AudioRecorderViewss: View {
    @StateObject private var viewModel: AudioRecordingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(studySetId: UUID) {
        _viewModel = StateObject(wrappedValue: AudioRecordingViewModel(studySetId: studySetId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0A0A1E").ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Title Input
                    TextField("Recording Title", text: $viewModel.recordingTitle)
                         .padding(.horizontal)
                    
                    // Timer Display
                    Text(timeString(from: viewModel.recordingTime))
                        .font(.system(size: 48, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                    
                    // Record Button
                    Button(action: viewModel.toggleRecording) {
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: viewModel.isRecording ? 4 : 40)
                                    .fill(viewModel.isRecording ? Color.white : Color.red)
                                    .frame(width: viewModel.isRecording ? 30 : 70,
                                           height: viewModel.isRecording ? 30 : 70)
                            )
                    }
                    .disabled(viewModel.isUploading)
                    
                    // Audio Waveform
                                   AudioWaveform(isRecording: $viewModel.isRecording)
                                       .padding(.horizontal)
                    
                    if !viewModel.isRecording && viewModel.duration > 0 {
                        // Playback Controls
                        VStack(spacing: 20) {
                            // Progress Slider
                            Slider(value: $viewModel.currentTime, in: 0...viewModel.duration)
                                .accentColor(.white)
                            
                            HStack {
                                Text(timeString(from: viewModel.currentTime))
                                Spacer()
                                Text(timeString(from: viewModel.duration))
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                            
                            // Playback Buttons
                            HStack(spacing: 40) {
                                Button(action: viewModel.skipBackward) {
                                    Image(systemName: "gobackward.10")
                                        .font(.title2)
                                }
                                
                                Button(action: viewModel.playRecording) {
                                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 54))
                                }
                                
                                Button(action: viewModel.skipForward) {
                                    Image(systemName: "goforward.10")
                                        .font(.title2)
                                }
                            }
                            .foregroundColor(.white)
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Upload Button
                    Button(action: viewModel.uploadRecording) {
                        HStack {
                            if viewModel.isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(viewModel.isUploading ? "Uploading..." : "Upload Recording")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                    }
                    .disabled(viewModel.isUploading || viewModel.recordingTitle.isEmpty)
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Record Audio")
            .navigationBarItems(trailing: dismissButton)
            .alert("Error", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
//            .sheet(isPresented: $viewModel.showAudioDetail) {
//                if let audioFile = viewModel.uploadedAudio {
//                    AudioDetailView(audioFile: audioFile)
//                }
//            }
            .alert("Recording Too Short", isPresented: $viewModel.showMinimumTimeAlert) {
                Button("Continue Recording", role: .cancel) { }
            } message: {
                Text("Please record for at least 20 seconds")
            }
        }
    }
    
    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
import SwiftUI
import Charts

import SwiftUI
import Charts

struct AudioSample: Identifiable {
    let id: Int
    var amplitude: Double
}

struct AudioWaveform: View {
    let numberOfSamples: Int
    @Binding var isRecording: Bool
    
    // Store our animated sample values
    @State private var samples: [AudioSample] = []
    
    // Timer for animation updates
    @State private var timer: Timer?
    
    init(numberOfSamples: Int = 30, isRecording: Binding<Bool>) {
        self.numberOfSamples = numberOfSamples
        self._isRecording = isRecording
        
        // Initialize samples with zeros
        self._samples = State(initialValue: (0..<numberOfSamples).map { AudioSample(id: $0, amplitude: 0) })
    }
    
    var body: some View {
        Chart(samples) { sample in
            BarMark(
                x: .value("Position", sample.id),
                y: .value("Amplitude", sample.amplitude)
            )
            .foregroundStyle(Color.white.opacity(0.8))
        }
        .frame(height: 100)
        .chartYScale(domain: 0...1)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .onChange(of: isRecording) { newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func startAnimation() {
        // Reset samples to initial state
        samples = (0..<numberOfSamples).map { AudioSample(id: $0, amplitude: 0.1) }
        
        // Create a timer that updates the samples
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                updateSamples()
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        
        // Reset samples to zero
        withAnimation(.linear(duration: 0.2)) {
            samples = (0..<numberOfSamples).map { AudioSample(id: $0, amplitude: 0) }
        }
    }
    
    private func updateSamples() {
        var newSamples = samples
        
        // Simulate audio input by generating random heights
        for i in 0..<samples.count {
            if isRecording {
                // Generate random values between 0.1 and 1.0
                // Use sine wave to make it look more natural
                let baseAmplitude = 0.5 + 0.3 * sin(Double(Date().timeIntervalSince1970 * 2 + Double(i)))
                let randomVariation = Double.random(in: -0.2...0.2)
                let newAmplitude = min(max(baseAmplitude + randomVariation, 0.1), 1.0)
                newSamples[i] = AudioSample(id: i, amplitude: newAmplitude)
            } else {
                newSamples[i] = AudioSample(id: i, amplitude: 0)
            }
        }
        
        samples = newSamples
    }
}


extension Color {
    static let customBlack = Color(hex: "#0e0e0e")
    static let customLightBlue = Color(hex: "#72d7f0")
    static let customDarkGray = Color(hex: "#2d2d2d")
    static let customMediumGray = Color(hex: "#686868")
    static let customSom = Color(hex: "#131720")
    static let customOrange = Color(hex: "#ffab2e")
    static let customYellow = Color(hex: "#ffff00")
    static let customLightGray = Color(hex: "#f6f6f2")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
