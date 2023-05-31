//
//  VideoPreviewView.swift
//  test4
//
//  Created by 안세진 on 2023/05/18.
//

import UIKit
import AVFoundation

class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        videoPreviewLayer.frame = self.videoPreviewLayer.bounds
//        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        
    }
}
