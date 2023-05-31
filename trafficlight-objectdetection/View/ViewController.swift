//
//  ViewController.swift
//  text9
//
//  Created by 안세진 on 2023/05/19.
//

import UIKit
import Vision
import AVFoundation
import AVKit
import CoreML

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var bufferSize: CGSize = .zero
    @IBOutlet private weak var videoPreviewView: VideoPreviewView!
    @IBOutlet private weak var switchZoomView: SwitchZoomView!
    @IBOutlet private weak var labelText: UILabel!
    @IBOutlet private weak var labelText2: UILabel!
    @IBOutlet weak var imageView: UIImageView!
//    @IBOutlet private weak var boxesView: DrawingBoundingBoxView!
    
    private var captureSessionController: CaptureSessionController?
    private lazy var videoPreviewViewF = VideoPreviewView()
    private let session = AVCaptureSession()
//    private var objectDetectionModel: ddddd_5?
//    private var objectDetectinModel: traffic_ligth?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        videoPreviewView.videoPreviewLayer.session = captureSessionController?.getCaptureSession()
//        videoPreviewView.layer.addSublayer(videoPreviewViewF.videoPreviewLayer)
        
        
//        let previewView = UIView(frame: view.bounds)
//        view.addSubview(previewView)
        
        captureSessionController = CaptureSessionController(previewView: videoPreviewView)
        videoPreviewView.layer.addSublayer(videoPreviewViewF.videoPreviewLayer)
        captureSessionController?.delegate = self
        captureSessionController?.startSession()
        setupSwitchZoomView()
    
    }
    override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)
           
        captureSessionController?.stopSession()
       }
  
}

extension ViewController {
    func setupSwitchZoomView() {
        switchZoomView.delegate = self
    }
}

extension ViewController: SwitchZoomViewDelegate {
    func switchZoomTapped(state: ZoomState) {
        captureSessionController?.setZoomState(zoomState: state)
    }
   
}
extension ViewController: CaptureSessionControllerDelegate {
    func didDetectObjects(_ objects: [DetectedObject], withLabels labels: [String]) {
            // 객체 감지 결과 처리
        for (object, label) in zip(objects, labels) {
            print("객체 레이블: \(label), 경계 상자: \(object.boundingBox)")
            
            // 추가적인 처리 로직을 구현할 수 있습니다.
            DispatchQueue.main.async {
                // UILabel의 text 값을 객체 감지 결과의 label 값으로 변경
                if label == "red" {
                    self.labelText.text = label
                    self.labelText.textColor = UIColor.black
                    self.labelText2.textColor = UIColor.white
                    self.imageView.image = UIImage(named: "2")
                    self.labelText.numberOfLines = 0
                } else if label == "green" {
                    self.labelText2.text = label
                    self.labelText2.textColor = UIColor.black
                    self.labelText.textColor = UIColor.white
                    self.imageView.image = UIImage(named: "1")
                    self.labelText2.numberOfLines = 0
                }
            }
        }
                
        }
}
