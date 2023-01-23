//
//  SpeechViewController.swift
//  SpeechToTranslationText
//
//  Created by J_Min on 2023/01/23.
//

import UIKit
import AVFoundation
import Speech
import SnapKit
import SwiftGoogleTranslate

class SpeechViewController: UIViewController {

    private let speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "ko"))
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private let speechButton: UIButton = {
        let button = UIButton()
        button.setTitle("말하기", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.lightGray, for: .highlighted)
        
        return button
    }()

    private let speechTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .label
        
        return label
    }()
    
    private let copyButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "doc.on.doc.fill"), for: .normal)
        button.tintColor = .lightGray
        
        return button
    }()
    
    private let speechTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 20
        textView.layer.masksToBounds = true
        textView.textContainerInset = .init(top: 16, left: 16, bottom: 16, right: 16)
        
        return textView
    }()
    
    private var speechTimer: Timer?
    private var speechTimeCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer?.delegate = self
        setSubViews()
        connectTarget()
    }
    
    // MARK: - Target
    private func connectTarget() {
        speechButton.addTarget(self, action: #selector(startSpeech(_:)), for: .touchDown)
        speechButton.addTarget(self, action: #selector(stopSpeech(_:)), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyLabel(_:)), for: .touchUpInside)
    }
    
    @objc private func startSpeech(_ sender: UIButton) {
        print("start speech")
        startSpeechTimer()
        runAudioEngine()
    }
    
    @objc private func stopSpeech(_ sender: UIButton) {
        print("stop speech")
        stopSpeechTimer()
        stopAudioEngine()
    }
    
    @objc private func copyLabel(_ sender: UIButton) {
        UIPasteboard.general.string = speechTextView.text
    }
    
    // MARK: - Method
    private func startSpeechTimer() {
        if speechTimer != nil { return }
        speechTimeCount = 0
        speechTimeLabel.text = secondToMinSec()
        speechTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.speechTimeCount += 1
            self?.speechTimeLabel.text = self?.secondToMinSec()
        }
    }
    
    private func stopSpeechTimer() {
        speechTimer?.invalidate()
        speechTimer = nil
    }

    func secondToMinSec() -> String {
        let min = String(format: "%.2d", speechTimeCount / 60)
        let sec = String(format: "%.2d", speechTimeCount % 60)
        
        return "\(min):\(sec)"
    }
    
    func runAudioEngine() {
        if !audioEngine.isRunning {
            if speechTask != nil {
                speechTask?.cancel()
                speechTask = nil
            }
            
            speechRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let speechRequest = speechRequest else { return }
            let inputNode = audioEngine.inputNode
            speechRequest.shouldReportPartialResults = true
            
            speechTask = speechRecognizer?.recognitionTask(with: speechRequest, resultHandler: { [weak self] result, error in
                guard let self = self else { return }
                var isFinal = false
                if result != nil {
                    let sttResult = result?.bestTranscription.formattedString
                    
                    SwiftGoogleTranslate.shared.translate(
                        sttResult ?? "",
                        "en",
                        "ko") { [weak self] text, error in
                            if let error = error {
                                print(error.localizedDescription)
                            }
                            DispatchQueue.main.async {
                                self?.speechTextView.text = text
                            }
                        }
                    isFinal = result!.isFinal
                }
                
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.speechRequest = nil
                    self.speechTask = nil
                }
            })
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
                self?.speechRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            
            do {
                try audioEngine.start()
            } catch {
                print(error.localizedDescription)
            }
            speechTextView.text = "뭐라는거임ㅡㅡ"
        }
    }
    
    func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            speechRequest?.endAudio()
        }
    }
    
    // MARK: - SetView
    private func setSubViews() {
        view.backgroundColor = .systemBackground
        
        [speechButton, speechTimeLabel, speechTextView, copyButton].forEach {
            view.addSubview($0)
        }
        
        setConstraints()
    }
    
    private func setConstraints() {
        speechButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(100)
        }
        
        speechTimeLabel.snp.makeConstraints {
            $0.top.equalTo(speechButton.snp.bottom).offset(30)
            $0.centerX.equalToSuperview()
        }
        
        speechTextView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.top.equalTo(speechTimeLabel.snp.bottom).offset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
        
        copyButton.snp.makeConstraints {
            $0.trailing.equalTo(speechTextView.snp.trailing)
            $0.centerY.equalTo(speechTimeLabel)
            $0.size.equalTo(40)
        }
    }
}

extension SpeechViewController: SFSpeechRecognizerDelegate {
    
}
