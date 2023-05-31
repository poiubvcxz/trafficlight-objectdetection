//
//  CaptureSessionController.swift
//  test4
//
//  Created by 안세진 on 2023/05/18.
//
enum CameraType {
    case ultrawide
    case wide
    case telephoto
}
import Foundation
import AVFoundation
import Vision
import CoreML
import UIKit

struct DetectedObject {
    let label: String
    let boundingBox: CGRect
}
protocol CaptureSessionControllerDelegate: AnyObject {
    func didDetectObjects(_ objects: [DetectedObject], withLabels labels: [String])
}

class CaptureSessionController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    weak var delegate: CaptureSessionControllerDelegate?
    
    public var captureSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var zoomState = ZoomState.ultrawide
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var objectDetectionModel: VNCoreMLModel?

    
    init(previewView: UIView) {
        super.init()
       
        
        initializeCaptureSession()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let previewLayer = previewLayer else {
            fatalError("Failed to create AVCaptureViewPreviewLayer")
        }
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        previewView.layer.addSublayer(previewLayer)
        
        guard let model = try? VNCoreMLModel(for: trffic_light_3().model) else {
            fatalError("Failed to load ML model")
        }
        objectDetectionModel = model
        setVideoZoomFactor()
    }
    
    func startSession() {
        captureSession.startRunning()
    }

    func stopSession() {
        captureSession.stopRunning()
    }
    
 
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    
    func setZoomState(zoomState: ZoomState) {
        self.zoomState = zoomState
        setVideoZoomFactor()
    }
    
    func getSupportCameratypes() -> [CameraType]? {
        guard let captureDevice = captureDevice else { return nil }
        switch captureDevice.deviceType {
        case .builtInTripleCamera:
            return [.ultrawide, .wide, .telephoto]
        case .builtInDualWideCamera:
            return [.ultrawide, .wide]
        case .builtInDualCamera:
            return [.wide, .telephoto]
        case .builtInWideAngleCamera:
            return [.wide]
        default:
            return nil
        }
    }
    

}

extension CaptureSessionController {
    func getVideoCaptureDevice() -> AVCaptureDevice? {
        
        if let tripleCamera = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return tripleCamera
        }
        
        if let dualWideCamera = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            return dualWideCamera
        }
        if let dualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return dualCamera
        }
        if let wideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return wideAngleCamera
        }
        return nil
    }
    
    func setVideoCaptureDeviceZoom(videoZoomFactor: CGFloat, animated: Bool = false, rate: Float = 0) {
        guard let captureDevice = captureDevice else { return }
        do {
            try captureDevice.lockForConfiguration()
        } catch let error {
            print("Failed to get lock configuration on capture device with error \(error)")
            return
        }
        if animated {
            captureDevice.ramp(toVideoZoomFactor: 5, withRate: rate)
        } else {
            if zoomState == .wide {
                captureDevice.videoZoomFactor = 3
            }
            else if zoomState == .ultrawide {
                captureDevice.videoZoomFactor = 2
            }
            else {
                captureDevice.videoZoomFactor = 5
            }
        }
        captureDevice.unlockForConfiguration()
    }
    func getVideoZoomFactor() -> CGFloat {
        switch zoomState {
        case .ultrawide:
            return 1
        case .wide:
            return getWideVideoZoomFactor()
        case .telephoto:
            return getTelephotoVideoZoomFactor()
        }
        
    }
    
    func getCaptureDeviceInput(captureDevice: AVCaptureDevice) -> AVCaptureDeviceInput? {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            return captureDeviceInput
        } catch let error {
            print("Failed to get capture device input with error \(error)")
        }
        return nil
    }
    func initializeCaptureSession() {
        guard let captureDevice = getVideoCaptureDevice() else { return }
        self.captureDevice = captureDevice
        guard let captureDeviceInput = getCaptureDeviceInput(captureDevice: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
//        startSession()
//        setVideoZoomFactor()
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.alwaysDiscardsLateVideoFrames = true
        
        let videoOutputQueue = DispatchQueue(label: "VideoOutputqueue")
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))
        
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("카메라 세션에 입력 및 출력을 추가할 수 없음")
        }
    }
    
    
    func getWideVideoZoomFactor() -> CGFloat {
        guard let captureDevice = captureDevice else { return 1 }
        switch captureDevice.deviceType {
        case .builtInTripleCamera:
            return 2
        case .builtInDualWideCamera:
            return 2
        default:
            return 1
        }
    }
    
    func getTelephotoVideoZoomFactor() -> CGFloat {
        guard let captureDevice = captureDevice else { return 2 }
        switch captureDevice.deviceType {
        case .builtInTripleCamera:
            return 3
        case .builtInDualCamera:
            return 2
        default:
            return 2
        }
    }
    
    func setVideoZoomFactor() {
        let videoZoomFactor = getVideoZoomFactor()
        setVideoCaptureDeviceZoom(videoZoomFactor: videoZoomFactor)
    }
}

extension CaptureSessionController {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        guard let model = objectDetectionModel else {
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.processDetectionResults(for: request, error: error)
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("물체 감지 오류: \(error)")
        }
    }
    
    private func processDetectionResults(for request: VNRequest, error: Error?) {
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                return
            }
            
            let detectedObjects = results.map { observation -> DetectedObject in
                let boundingBox = observation.boundingBox
                let label = observation.labels.first?.identifier ?? ""

                return DetectedObject(label: label, boundingBox: boundingBox)
               
            }
        let labels = detectedObjects.map { $0.label }
        delegate?.didDetectObjects(detectedObjects, withLabels: labels)
        }
}
