//
//  ImageTranstlationViewController.swift
//  SpeechToTranslationText
//
//  Created by J_Min on 2023/02/04.
//

import UIKit
import Photos
import PhotosUI

final class ImageTranstlationViewController: UIViewController {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    private let annotationView: UIView = {
        let view = UIView()
        
        return view
    }()
    
    private let translateButton: UIButton = {
        let button = UIButton()
        button.setTitle("번역", for: .normal)
        button.tintColor = .label
        
        return button
    }()
    
    private let imageRecognitionManager = ImageRecognitionManager(detectType: .Japanese)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSubViews()
        connectTarget()
        imageRecognitionManager.delegate = self
    }
    
    // MARK: - Target
    private func connectTarget() {
        translateButton.addTarget(self, action: #selector(translateButtonAction(_:)), for: .touchUpInside)
    }
    
    @objc private func cameraButtonAction(_ sender: UIButton) {
        presentImagePickerActionSheet()
    }
    
    @objc private func translateButtonAction(_ sender: UIButton) {
        let image = imageView.image
        clear()
        imageRecognitionManager.startDetect(image: image)
    }
    
    // MARK: - Method
    private func presentImagePickerActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
            self?.openCamera()
        }
        let albumAction = UIAlertAction(title: "사진앨범", style: .default) { [weak self] _ in
            self?.openAlbum()
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(cameraAction)
        alert.addAction(albumAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
    
    private func openCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    private func openAlbum() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    private func clear() {
        annotationView.subviews.forEach {
            $0.removeFromSuperview()
        }
    }
    
    // MARK: - UI
    private func setNavigationBarButtonItem() {
        let cameraButton = UIBarButtonItem(
            image: UIImage(systemName: "camera"),
            style: .plain,
            target: self,
            action: #selector(cameraButtonAction(_:))
        )
        
        navigationItem.rightBarButtonItem = cameraButton
    }
    
    private func setSubViews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Image"
        setNavigationBarButtonItem()
        
        view.addSubview(imageView)
        view.addSubview(translateButton)
        imageView.addSubview(annotationView)
        
        setConstraints()
    }
    
    private func setConstraints() {
        imageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(30)
            $0.horizontalEdges.equalToSuperview()
        }
        
        annotationView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        translateButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            $0.top.equalTo(imageView.snp.bottom).offset(15)
            $0.centerX.equalToSuperview()
        }
    }
}

extension ImageTranstlationViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        imageView.image = selectedImage
        clear()
    }
}

extension ImageTranstlationViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProvider = results.first?.itemProvider
        if let itemProvider = itemProvider,
           itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] selectedImage, error in
                guard let selectedImage = selectedImage as? UIImage else { return }
                DispatchQueue.main.async {
                    print(selectedImage)
                    self?.imageView.image = selectedImage
                    self?.clear()
                }
            }
        }
    }
}


extension ImageTranstlationViewController: UINavigationControllerDelegate { }

extension ImageTranstlationViewController: ImageRecognitionDelegate {
    var imageViewRect: CGRect {
        return imageView.frame
    }
    
    var imageSize: CGSize {
        return imageView.image?.size ?? .zero
    }
    
    func frameView(view: UIView) {
        annotationView.addSubview(view)
    }
}
