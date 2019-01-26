//
//  AvCapture.swift
//  RepCountCNN
//
//  Created by 鹿山 敦至 on 2018/01/18.
//  Copyright © 2018年 Ash. All rights reserved.
//

import Foundation
import AVFoundation


protocol AVCaptureDelegate {
    func capture(image: UIImage, count: Int) //UIImage は myGekiga~.h でUIKit をimportしているのでOK?不明
}

class AVCapture:NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession!
    var delegate: AVCaptureDelegate?
    
    var count = 0 //更に処理を少なくする
    
    override init(){
        super.init()
        
        captureSession = AVCaptureSession()
        
        // 解像度
        captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540
        //AVCaptureSessionPresetMedium
        //AVCaptureSessionPreset1920x1080 1/5
        //AVCaptureSessionPreset1280x720 1/5
        //AVCaptureSessionPreset640x480
        //AVCaptureSessionPresetLow
        
        let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) // カメラ
        videoDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)// 1/30秒(１秒間に30フレーム)
        
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice)
        captureSession.addInput(videoInput)
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        // ピクセルフォーマット(32bit BGRA)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = false // 処理中の場合は、フレームを破棄する
        captureSession.addOutput(videoDataOutput)
        
        //let videoConnection:AVCaptureConnection = (videoDataOutput.connection(withMediaType: AVMediaTypeVideo))!
        //videoConnection.videoOrientation = .portrait
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    // 新しいキャプチャの追加で呼ばれる(1/30秒に１回)
    // プロトコルAVCaptureVideoDataOutputSampleBufferDelegate内の関数をオーバーライドしている
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        if(self.count%2)==0{
            if (self.count % 5 == 0 || self.count % 7 == 0 || self.count % 9 == 0 ){
                let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
                delegate?.capture(image: image, count: Int(self.count))
            }
        }
        self.count += 1
    }
    
    // imagebuffer から UIImage の作成
    func imageFromSampleBuffer(sampleBuffer :CMSampleBuffer) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // イメージバッファのロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // 画像情報を取得
        let base = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        let bytesPerRow = UInt(CVPixelBufferGetBytesPerRow(imageBuffer))
        let width = UInt(CVPixelBufferGetWidth(imageBuffer))
        let height = UInt(CVPixelBufferGetHeight(imageBuffer))
        
        // ビットマップコンテキスト作成
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerCompornent = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        let newContext = CGContext(data: base, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerCompornent), bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: bitmapInfo.rawValue)! as CGContext
        
        // 画像作成
        let imageRef = newContext.makeImage()!
        let image = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        // イメージバッファのアンロック
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return image
    }
}

