//
//  SpeechViewController.swift
//  SpeechToTranslationText
//
//  Created by J_Min on 2023/01/23.
//

import UIKit
import SnapKit
import Combine

class SpeechViewController: UIViewController {

    private let inputLanguageLabel: UILabel = {
        let label = UILabel()
        label.text = "한국어"
        
        return label
    }()
    
    private let outputLanguageLabel: UILabel = {
        let label = UILabel()
        label.text = "일본어"
        
        return label
    }()
    
    private let toggleButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        button.setImage(UIImage(systemName: "arrow.left"), for: .selected)
        button.tintColor = .label
        
        return button
    }()
    
    private let languageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 10
        
        return stackView
    }()
    
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
    
    private let cameraButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "camera"), for: .normal)
        button.tintColor = .label
        
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
    private let viewModel = SpeechViewModel()
    private var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSubViews()
        connectTarget()
        binding()
    }
    
    // MARK: - Target
    private func connectTarget() {
        speechButton.addTarget(self, action: #selector(startSpeech(_:)), for: .touchDown)
        speechButton.addTarget(self, action: #selector(stopSpeech(_:)), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyLabel(_:)), for: .touchUpInside)
        toggleButton.addTarget(self, action: #selector(toggleButtonAction(_:)), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraButtonAction(_:)), for: .touchUpInside)
    }
    
    @objc private func toggleButtonAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        viewModel.toggleLanguage()
    }
    
    @objc private func startSpeech(_ sender: UIButton) {
        print("start speech")
        startSpeechTimer()
        viewModel.runAudioEngine()
    }
    
    @objc private func stopSpeech(_ sender: UIButton) {
        print("stop speech")
        stopSpeechTimer()
        viewModel.stopAudioEngine()
    }
    
    @objc private func copyLabel(_ sender: UIButton) {
        UIPasteboard.general.string = speechTextView.text
    }
    
    @objc private func cameraButtonAction(_ sender: UIButton) {
        let vc = ImageTranstlationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Method
    private func binding() {
        viewModel.textPublihser
            .sink { [weak self] text in
                self?.speechTextView.text = text
            }.store(in: &subscriptions)
    }
    
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
    
    // MARK: - SetView
    private func setSubViews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "speech"
        
        [languageStackView, speechButton, speechTimeLabel, speechTextView, copyButton, cameraButton].forEach {
            view.addSubview($0)
        }
        
        [inputLanguageLabel, toggleButton, outputLanguageLabel].forEach {
            languageStackView.addArrangedSubview($0)
        }
        
        setConstraints()
    }
    
    private func setConstraints() {
        languageStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        toggleButton.snp.makeConstraints {
            $0.size.equalTo(40)
        }
        
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
        
        cameraButton.snp.makeConstraints {
            $0.leading.equalTo(speechTextView.snp.leading)
            $0.centerY.equalTo(speechTimeLabel)
            $0.size.equalTo(40)
        }
    }
}
