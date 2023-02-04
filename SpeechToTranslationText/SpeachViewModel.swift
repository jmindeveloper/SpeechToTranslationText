//
//  SpeachViewModel.swift
//  SpeechToTranslationText
//
//  Created by J_Min on 2023/02/04.
//

import Speech
import SwiftGoogleTranslate
import AVFoundation
import Foundation
import Combine

enum LocaleCode {
    case korean, japan
    
    var code: String {
        switch self {
        case .korean:
            return "ko"
        case .japan:
            return "ja"
        }
    }
}

final class SpeechViewModel: NSObject {
    
    private var input = LocaleCode.korean
    private var output = LocaleCode.japan
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()

    let textPublihser = CurrentValueSubject<String?, Never>(nil)
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: input.code))
        speechRecognizer?.delegate = self
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
                    self.textPublihser.send(sttResult)
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
//            speechTextView.text = "뭐라는거임ㅡㅡ"
            textPublihser.send("뭐라는거임ㅡㅡ")
        }
    }
    
    func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            speechRequest?.endAudio()
            SwiftGoogleTranslate.shared.translate(
                textPublihser.value ?? "",
                output.code,
                input.code
            ) { [weak self] text, error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    DispatchQueue.main.async {
                        self?.textPublihser.send(text)
                    }
                }
        }
    }
    
    func toggleLanguage() {
        swap(&input, &output)
        speechRecognizer = SFSpeechRecognizer(locale: .init(identifier: input.code))
        speechRecognizer?.delegate = self
    }
}

extension SpeechViewModel: SFSpeechRecognizerDelegate { }
