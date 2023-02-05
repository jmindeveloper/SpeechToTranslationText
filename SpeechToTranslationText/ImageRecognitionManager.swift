//
//  ImageRecognitionManager.swift
//  SpeechToTranslationText
//
//  Created by J_Min on 2023/02/04.
//

import UIKit
import SwiftGoogleTranslate
import MLKitTextRecognitionCommon
import MLKitTextRecognitionKorean
import MLKitTextRecognitionJapanese
import MLKitTextRecognition
import MLKitVision

protocol ImageRecognitionDelegate: AnyObject {
    var imageViewRect: CGRect { get }
    var imageSize: CGSize { get }
    func frameView(view: UIView)
}

final class ImageRecognitionManager {
    
    enum DetectType {
        case Korean, Japanese
    }
    
    weak var delegate: ImageRecognitionDelegate?
    var textRecognizer: TextRecognizer?
    var detectType: DetectType {
        didSet {
            setTextRecognizer()
        }
    }
    
    init(detectType: DetectType) {
        self.detectType = detectType
        setTextRecognizer()
    }
    
    private func setTextRecognizer() {
        var recognitionOption: CommonTextRecognizerOptions
        
        switch detectType {
        case.Korean:
            recognitionOption = KoreanTextRecognizerOptions()
        case .Japanese:
            recognitionOption = JapaneseTextRecognizerOptions()
        }
        
        textRecognizer = TextRecognizer.textRecognizer(options: recognitionOption)
    }
    
    func startDetect(image: UIImage?) {
        guard let image = image else { return }
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        detect(image: visionImage)
    }
    
    private func detect(image: VisionImage) {
        textRecognizer?.process(image) { [weak self] result, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self?.getText(detectText: result)
        }
    }
    
    private func getText(detectText: Text?) {
        guard let detectText = detectText else {
            return
        }
        
        for block in detectText.blocks {
            let transformRect = block.frame.applying(transformMatrix())
//            addRectangle(
//                transformRect,
//                color: .purple
//            )
            for line in block.lines {
                let transformRect = line.frame.applying(transformMatrix())
                addRectangle(
                    transformRect,
                    color: .black
                )
                
                SwiftGoogleTranslate.shared.translate(
                    line.text,
                    "ko",
                    "ja") { [weak self] text, error in
                        DispatchQueue.main.async {
                            let label = UILabel(frame: transformRect)
                            label.text = text
                            label.adjustsFontSizeToFitWidth = true
                            self?.delegate?.frameView(view: label)
                        }
                    }
                
//                for element in line.elements {
//                    let transformRect = element.frame.applying(transformMatrix())
//                    addRectangle(
//                        transformRect,
//                        color: .green
//                    )
//                    print(element.text)
//                }
            }
        }
    }
    
    private func transformMatrix() -> CGAffineTransform {
        guard let delegate = delegate else {
            return CGAffineTransform()
        }
        
        let imageViewWidth = delegate.imageViewRect.width
        let imageViewHeight = delegate.imageViewRect.height
        let imageWidth = delegate.imageSize.width
        let imageHeight = delegate.imageSize.height
        
        let imageViewAspectRatio = imageViewWidth / imageViewHeight
        let imageAspectRatio = imageWidth / imageHeight
        let scale =
        (imageViewAspectRatio > imageAspectRatio)
        ? imageViewHeight / imageHeight : imageViewWidth / imageWidth
        
        // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
        // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
        let scaledImageWidth = imageWidth * scale
        let scaledImageHeight = imageHeight * scale
        let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
        let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)
        
        var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
        transform = transform.scaledBy(x: scale, y: scale)
        return transform
    }
    
    func addRectangle(_ rectangle: CGRect, color: UIColor) {
        guard rectangle.isValid() else { return }
        let rectangleView = UIView(frame: rectangle)
        rectangleView.layer.cornerRadius = 10
        rectangleView.alpha = 0.8
        rectangleView.backgroundColor = color
        rectangleView.isAccessibilityElement = true
        
        delegate?.frameView(view: rectangleView)
    }
}

extension CGRect {
    /// Returns a `Bool` indicating whether the rectangle's values are valid`.
    func isValid() -> Bool {
        return !(origin.x.isNaN || origin.y.isNaN || width.isNaN || height.isNaN || width < 0 || height < 0)
    }
}
