//
//  OpenCV.m
//  RepCountCNN
//
//  Created by 鹿山 敦至 on 2018/01/18.
//  Copyright © 2018年 Ash. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>
//#import "RepCountCNN-Bridging-Header.h"
#import "OpenCv.h"
#include <vector>


@implementation OpenCv : NSObject

@synthesize cur_std = _cur_std;

- (id) init {
    if (self = [super init]) {
        self.adaptiveThreshold0 = 2;
        self.adaptiveThreshold1 = 2;
        std::deque<cv::Mat> deq;
        std::vector<cv::Mat> vec;
        int test;
        cv::Mat dst;
        double _cur_std;
        
    }
    return self;
}

- (void) init_vec {
    for(int i = 0; i<20; i++){
        vec.push_back(cv::Mat::zeros(120, 160, CV_8UC1));
    }
}

-(UIImage *)Filter:(UIImage *)image {
    
    // 方向を修正
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    /* 入力画像からROIを検出し切り出し -> 50X50 の画像にして返す*/
    
    cv::Mat mat;
    cv::Mat mat_trans;
    cv::Mat target;
    cv::Mat v1;
    cv::Mat v2;
    cv::Mat v3;
    cv::Mat v4;
    cv::Mat stdv;
    cv::Mat E1;
    cv::Mat E2;
    double th;
    cv::Mat filt = cv::Mat::ones(10,10,CV_32FC1);
    cv::Mat locations;
    const int array_size = 120*160;
    int x_array[array_size] = {};
    int y_array[array_size] = {};
    int cnt=0;
    int th_up, th_low;
    int x1, x2, y1, y2;
    cv::Mat ROIim;
    cv::Mat ROIim_flatten;
    std::vector<cv::Mat> frame;
    cv::Mat arr[vec.size()];
    std::copy(vec.begin(), vec.end(), arr);
    
    //UIImageをcv::Mat (CV_8UC1 グレースケール1ch 0~255)に変換
    UIImageToMat(image, mat);
    cv::cvtColor(mat,mat,CV_BGR2GRAY);
    
    // 240x320 にリサイズ (hieght, width) 指定なことに注意
    cv::resize(mat, mat_trans, cv::Size(160, 120));
    
//    std::cout << "テスト";
//    std::cout << vec.size() << std::endl;
//    test += 1;
//    std::cout << "カウンター: "<< test << std::endl;
    
    
    // ベクターに入っている２０frame中先頭の物を削除し，最後尾に現在のフレーム追加 -> (160*20)x120 (1ch) 画像作成
    vec.erase(vec.begin());
    vec.push_back(mat_trans);

//    cv::vconcat(mat_trans, mat_trans, dst);
//    cv::vconcat(arr, 20, dst);
    
//    // テスト用にベクトルを初期化
//    for(int i = 0; i<20; i++){
//        vec.erase(vec.begin());
//        //vec.push_back(cv::Mat::ones(160, 120, CV_8UC1) * i);
//
//        // 正方形の黒いい四角が移動していく画像を追加
//        cv::Mat whole = cv::Mat::zeros(120, 160, CV_8UC1);
//        std::cout << "i " << i << std::endl;
//        //cv::Mat part = cv::Mat(whole, cv::Rect (14 * i, 100, 40, 40)); // (x, y, width, height) なので注意 行，列 とは逆
//        cv::Mat part = cv::Mat(whole, cv::Rect (7 * i, 50, 20, 20));
//        part = cv::Scalar(255);
//
//        std::cout << "四角画像"<<whole.row(50) << std::endl;
//        std::cout << "四角画像"<<whole.row(69) << std::endl;
//        std::cout << "四角画像"<<whole.row(70) << std::endl;
//
//
//        vec.push_back(whole);
//    }
//    std::cout << "テスト用に初期化したベクトル"<<vec[19].row(0) << std::endl;
//    // テスト用の初期化終了’
    
    cv::vconcat(vec, dst); // 20フレームの 240x320 の画像を結合して (240*20)x320 の画像を作成
    
//    //テスト作成されたcvmat の確認
//    std::cout << "結合結果"<<dst.row(100) << std::endl;
//    std::cout << "結合結果"<<dst.row(139) << std::endl;
//    std::cout << "結合結果"<<dst.row(1600) << std::endl;
//    // 確認終了
    
    // (240*20)x320 の画像を作成 -> 20x(240*320) に reshape すると１行が１つの画像に無事変換される
    
    mat_trans = dst.reshape(1, 20);
    
//    // テスト出力
//    std::cout << "reshape結果" << mat_trans.row(1) << std::endl;
//    std::cout << "reshape結果" << mat_trans.row(10) << std::endl;
    
    // 型を変換しておかないと後の計算で値が飽和する, sqrtも計算できない (最後に CV_8UC1 に戻してUIImageに変換する)
    mat_trans.convertTo(mat_trans, CV_32FC1, 1.0/255);
    
    // 各ピクセル 20ch フレームでの標準偏差を算出, 平均値で閾値処理
    cv::reduce(mat_trans, v1, 0, CV_REDUCE_AVG);    //各列平均計算
    cv::repeat(v1, 20, 1, v2);                      //平均値行列作成
    cv::subtract(mat_trans, v2, v3);                //平均値を引く
    cv::multiply(v3, v3, v3);                       //各要素２乗
    cv::reduce(v3, v4, 0, CV_REDUCE_AVG);           //各列平均計算
    cv::sqrt(v4, stdv);                             //各要素平方根計算
    
    // Scalar は 4つの要素を持つ配列 先頭要素に平均値が入っている
    th = cv::mean(stdv)[0]; //全要素平均値計算
    cv::threshold(stdv, E1, th, 1, CV_THRESH_BINARY);  // th を閾値にstdevを0, 0.01 で二値化した E1 を作成
    
    
    //畳み込み前に 1chx160x120形式に戻す
    E1 = E1.reshape(1, 120);
    //境界の処理は BORDER_DEFAULT になっており，同じサイズのcv::Matを返す
    cv::filter2D(E1, v1, -1, filt); // E1 を 10x10 の値1 正方カーネルfilt で畳み込んだ v1 を作成
    cv::threshold(v1, E2, 80, 1.0, CV_THRESH_BINARY); // 80/255 を閾値に v1 を二値化した E2 を作成
    
    //E2内で1が入っている座標を取得，座標内で上位97%, 下位3%の値をboudingBoxの値とする
    for(int y = 0 ; y < E2.rows; y++){
        for(int x = 0 ; x < E2.cols; x++){
            if (E2.at<float>(y,x) == 1){
                x_array[cnt] = x;
                y_array[cnt] = y;
                cnt+=1;
            };
        }
    }
    
    // 順位で下位3%, 上位97%の境界値を求める
    th_up = floor(cnt*0.98);
    th_low = ceil(cnt*0.02);
    //値を代入したところまでで昇順ソート
    std::sort(x_array, x_array+cnt);
    std::sort(y_array, y_array+cnt);
    
    x1 = x_array[th_low];
    x2 = x_array[th_up];
    y1 = y_array[th_low];
    y2 = y_array[th_up];
    
    
    
    /////////////////// 作成したバウンディングボックスで画像を切り出す　///////////////////
    
    cv::merge(vec, target); // 20chx240x320 の画像を作成
//    std::cout << "チャネル数" << target.channels() << std::endl;
//    std::cout << "１フレーム目" << vec[0].row(0) << std::endl;
    
    // 絞り込んだ領域の高さもしくは幅が 0 だった場合　ー> 画像全体を 50x50 にリサイズ， 20フレームを１つの画像にまとめて返す
    if (x2-x1<1 || y2-y1<1){
        cv::resize(target, ROIim, cv::Size(50,50));
        split(ROIim, frame); // ch 方向をvector 各要素に分割
        cv::vconcat(frame, ROIim); // (50*20)x50 の画像を作成
        ROIim_flatten = ROIim.reshape(1, 20); //20x(50*50) の画像を作成
        
        return MatToUIImage(ROIim_flatten);
    }
    
    // バウンディングボックスで画像を切り出し
    ROIim = target(cv::Range(y1,y2), cv::Range(x1,x2));
//    std::cout << "リサイズ前" << ROIim.row(0) << std::endl;
    // 切り出した 20ch x ROIy x ROIx のデータを 20chx50x50にリサイズ, scipyの bilinear補間 と若干挙動は異なるが良しとする
    cv::resize(ROIim, ROIim, cv::Size(50,50));
    
//    std::cout << "リサイズ後 \n" << ROIim << std::endl;
    
    // (50*20)x 50 の画像を作成 -> 20x(50*50) に reshape すると１行が１つの画像に無事変換される
    split(ROIim, frame); // ch 方向をvector 各要素に分割
    cv::vconcat(frame, ROIim); // (50*20)x50 の画像を作成
    ROIim_flatten = ROIim.reshape(1, 20);
//    std::cout << "一行位置画像になっているか\n " << ROIim_flatten.row(0) << std::endl; //
//    std::cout << "一行位置画像になっているか\n " << ROIim_flatten.row(1) << std::endl; //

    // 切り出したROIim での各ピクセル値の標準偏差の平均値を計算

    ROIim_flatten.convertTo(v1, CV_32FC1, 1.0/255);
    cv::reduce(v1, v2, 0, CV_REDUCE_AVG);
    cv::repeat(v2, 20, 1, v3);
    cv::subtract(v1, v3, v4);
    cv::multiply(v4, v4, v4);
    cv::reduce(v4, v2, 0, CV_REDUCE_AVG);
    cv::sqrt(v2, stdv);
    _cur_std = cv::mean(stdv)[0]*255;
    //printf("cur_std: %f\n", _cur_std);
    
    // CNNモデル出力のテスト用にサンプルデータを作成
    
    // 1ch x 20 x (50*50) の画像をUIImageに変換して返す
    
    // 出力をすべての画素値が１のテンソルに置き換えてテスト
    // 20フレームを１つの画像にした結果の計算結果が正しいか確認
    
//    ROIim_flatten = cv::Mat::ones(20,2500,CV_8UC1);
    // テスト用に画像を用意
//    for(int i = 0; i<20; i++){
//        vec.erase(vec.begin());
//        cv::Mat whole = cv::Mat::ones(1, 2500, CV_8UC1) * i;
//        vec.push_back(whole);
//    }
//    cv::vconcat(vec, ROIim_flatten);
//    std::cout << "1行目 \n" <<ROIim_flatten.row(0) << std::endl;
//    std::cout << "20行目 \n" <<ROIim_flatten.row(19) << std::endl;
    
//    // テスト用に画像を用意
//    for(int i = 0; i<20; i++){
//        vec.erase(vec.begin());
//        // cv::Mat whole = (cv::Mat_<int8_t>(2,2) << 1, 2, 3, 4) * i;
//        cv::Mat whole = cv::Mat::ones(50, 50, CV_8UC1) * i;
//        vec.push_back(whole);
//    }
//    cv::merge(vec, ROIim_flatten);
    
    return MatToUIImage(ROIim);
}

@end


