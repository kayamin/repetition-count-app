//
//  CNNCounter.swift
//  RepCountCNN
//
//  Created by 鹿山 敦至 on 2018/01/18.
//  Copyright © 2018年 Ash. All rights reserved.
//

import Foundation
import AVFoundation
import Alamofire
import CoreML

class CNNCounter {
    
    let openCv = OpenCv()
    var converted_image: UIImage?
    let RepCountCNN = RepetitionCounting() // coremlmodel のインスタンス化
    var output = Dictionary<String, Double>()
    var prediction : RepetitionCountingOutput!
    var std :Double!
    var interval :Double
    var global_counter_id : Int
    var m = MultiArray<Double>(shape: [1,1,20,50,50])
    var pixArray : [UInt8]!
    
    init(interval:Double){
        openCv.init_vec()
        self.interval = interval
        self.global_counter_id = 0
    }
    
    func predict(image:UIImage, frame_count:Int){
        
        converted_image = openCv.filter(image)
        m = makeMultiArrayFromImage(image: converted_image!)
        
        std = openCv.cur_std
        prediction = runRepCountCNN(data: m)
        
        // 辞書配列に推定結果を格納
        for (key,value) in prediction.output{
        output.updateValue(value, forKey: key)
        }
        output.updateValue(std, forKey: "cur_std")
        output.updateValue(interval, forKey: "interval")
        output.updateValue(Double(self.global_counter_id), forKey: "global_counter_id")
        output.updateValue(Double(frame_count), forKey: "frame_count")
        print("value inside")
        print(self.global_counter_id)
        print(Double(self.global_counter_id))
        
        // JSON形式で 辞書配列データを HTTP通信（POST)
        Alamofire.request("http://kym.local:8000/repetition_count_server/counter/", method: .post, parameters: output, encoding: JSONEncoding.default, headers: nil)
//        Alamofire.request("http://kym.local:4000/cnn_output", method: .post, parameters: output, encoding: JSONEncoding.default, headers: nil)
//        Alamofire.request("http://wang.local:5000/api/test", method: .post, parameters: output, encoding: JSONEncoding.default, headers: nil)
    }
    
    
    func UIImage2CVIPB(image:UIImage) -> CVPixelBuffer?{
        var pixelbuffer: CVPixelBuffer? = nil
        
        CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_OneComponent8, nil, &pixelbuffer)
        CVPixelBufferLockBaseAddress(pixelbuffer!, CVPixelBufferLockFlags(rawValue:0))
        
        let colorspace = CGColorSpaceCreateDeviceGray()
        let bitmapContext = CGContext(data: CVPixelBufferGetBaseAddress(pixelbuffer!), width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelbuffer!), space: colorspace, bitmapInfo: 0)!
        
        bitmapContext.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        return pixelbuffer
        
    }
    
    func runRepCountCNN(data:MultiArray<Double>) -> RepetitionCountingOutput{
        
//        var input : CVPixelBuffer?
//        input = UIImage2CVIPB(image:image)
        let coreMLArray : MLMultiArray = data.array
        let prob = try! RepCountCNN.prediction(data:coreMLArray)
        
        return prob
        
    }
    
    func makeMultiArrayFromImage(image: UIImage) -> MultiArray<Double>{
        
        pixArray = getByteArrayFromImage(imageRef: image.cgImage!)
        
        // opencv の処理よっては pixArray における C,W,H の順番が変わってくるのでデータを見て暫定対処する
        for i in 0..<20{
            for j in 0..<50{
                for k in 0..<50{
                    m[0,0,i,j,k] = Double(pixArray![50*50*i + 50*j + k])
                }
            }
        }
        
        return m
    }
    
    func getByteArrayFromImage(imageRef: CGImage) -> [UInt8] {
        
        let data = imageRef.dataProvider!.data
        let length = CFDataGetLength(data)
        var rawData = [UInt8](repeating: 0, count: length)
        CFDataGetBytes(data, CFRange(location: 0, length: length), &rawData)
        
        return rawData
    }
    
}
