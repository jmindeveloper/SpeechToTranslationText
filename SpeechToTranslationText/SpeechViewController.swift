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

class SpeechViewController: UIViewController {

    private let speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: "ko"))
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private let speechButton: UIButton = {
        let button = UIButton()
        button.setTitle("말하기", for: .normal)
        button.setTitleColor(.label, for: .normal)
        
        return button
    }()

    private let speechTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .label
        
        return label
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
                    self.speechTextView.text = result?.bestTranscription.formattedString
                    
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
        
        [speechButton, speechTimeLabel, speechTextView].forEach {
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
    }
}

extension SpeechViewController: SFSpeechRecognizerDelegate {
    
}
