//
//  ViewController.swift
//  RepCountCNN
//
//  Created by 鹿山 敦至 on 2018/01/18.
//  Copyright © 2018年 Ash. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, AVCaptureDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var menuLabel: UILabel!
    @IBOutlet weak var ResetButton: UIButton!

    let avCapture = AVCapture()// カメラ映像取得周りのクラスインスタンス化
    let cnnCounter5 = CNNCounter(interval:5)
    let cnnCounter7 = CNNCounter(interval:7)
    let cnnCounter9 = CNNCounter(interval:9)
    var Value : Double = 0
    var global_counter_id : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        avCapture.delegate = self
        textLabel.text = "counting : 6"
        menuLabel.text = "Push-Up"
        textLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2) // 90°回転
        menuLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2) 
        
        ResetButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        
//        // カウントサーバーを初期化, グローバルカウンターの id を取得
//        Alamofire.request("http://kym.local:8000/repetition_count_server/init").responseJSON{ response in
//
//            guard let object = response.result.value else{
//                return
//            }
//            let json = JSON(object)
//            json.forEach{ (key, val) in
//                if(key=="global_counter_id"){
//                    self.global_counter_id = val.int!
//                }
//            }
//        }
//
//        self.cnnCounter5.global_counter_id = self.global_counter_id
//        self.cnnCounter7.global_counter_id = self.global_counter_id
//        self.cnnCounter9.global_counter_id = self.global_counter_id
    }
    
    @IBAction func ResetButton(_ sender: Any) {
        // カウントサーバーを初期化, グローバルカウンターの id を取得
        Alamofire.request("http://kym.local:8000/repetition_count_server/init").responseJSON{ response in
            
            guard let object = response.result.value else{
                return
            }
            let json = JSON(object)
            json.forEach{ (key, val) in
                if(key=="global_counter_id"){
                    self.global_counter_id = val.int!
                }
            }
        }
        // 画面の表示をResetに変更
        self.textLabel.text = "Reset"
        self.cnnCounter5.global_counter_id = self.global_counter_id
        self.cnnCounter7.global_counter_id = self.global_counter_id
        self.cnnCounter9.global_counter_id = self.global_counter_id
        
    }
    // プロトコル AVCaptureDelegate 内で宣言されている関数の内容定義
    // カメラからフレームを取得した際に呼ばれる captureOutput関数 内で呼ばれる
    func capture(image:UIImage, count:Int){
        imageView.image = image
        print("capture")
        print(self.global_counter_id)
        if (count % 5 == 0){self.cnnCounter5.predict(image:image, frame_count: count)}
        if (count % 7 == 0){self.cnnCounter7.predict(image:image, frame_count: count)}
        if (count % 9 == 0){self.cnnCounter9.predict(image:image, frame_count: count)}
        
        // サーバへ現在のカウント数問い合わせ -> 結果を画面に描画
        if(count%10 == 0){
            let params = ["frame_count": count, "global_counter_id": self.cnnCounter9.global_counter_id]
            Alamofire.request("http://kym.local:8000/repetition_count_server/counter/", method: .get, parameters: params).responseJSON{ response in
                //debugPrint(response.result.value!)
                guard let object = response.result.value else{
                    return
                }
                let json = JSON(object)
                var status : String!
                var global_counter : Int!
                var text : String!
                print(json["status"].string!)
                print("JSON: \(json)")
                
                status = json["status"].string!
                global_counter = json["global_counter"].int!
                if (status == "new hypothesis" || status == "counting" || status == "done"){
                    text = "\(status!) : \(global_counter!)"
                    self.textLabel.text = text
                }else{
                    text = ""
                    self.textLabel.text = text
                }
                
                
//                json.forEach{ (key, val) in
//                    // カウント状態を判別して描画
//                    if(key=="status"){
//                        status = val.string!
//                    }
//                    if(key=="global_counter"){
//                        if (status == "new hypothesis" || status == "counting" || status == "done"){
//                            text = "\(status!) : \(val)"
//                            self.textLabel.text = text
//                        }else{
//                            text = "\(status)"
//                            self.textLabel.text = text
//                        }
//                        //値をメンバ変数に保存，クロージャの外でも値を参照できる
//                        self.Value = val.doubleValue
//                    }
//                }
            }
        }

        // OpenPoseサーバへ画像を送信
        let data = UIImageJPEGRepresentation(image,0.5) // UIImage を JPEGへ圧縮率１で変換

        Alamofire.upload(
            multipartFormData: { multipartFormData in
                // 送信する値の指定をここでします
                multipartFormData.append(data!, withName: "img_file", fileName: "Capture.jpeg", mimeType: "image/jpeg")
            },
//            to: "http://kym.local:4000/send",
            to: "http:10.213.29.19:44400/send",
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        // 成功
                        guard let object = response.result.value else{
                            return
                        }
                        let json = JSON(object)
                        var status : String!
                        var text : String!
                        json.forEach{ (key, val) in
                        
                            if(key=="menu"){
                                if val==0 { status == "Push Up"}
                                if val==1 { status == "Sit up"}
                                if val==2 { status == "No person"}
                                text = "\(key) : \(status)"
                                self.menuLabel.text = text

                            }
                        }
                    }

                case .failure(let encodingError):
                    // 失敗
                    print(encodingError)
                }

        }
        )
    }
}

