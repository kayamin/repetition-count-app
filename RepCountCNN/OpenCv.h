//
//  OpenCV.h
//  RepCountCNN
//
//  Created by 鹿山 敦至 on 2018/01/18.
//  Copyright © 2018年 Ash. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>
#import <deque>
#import <vector>



@interface OpenCv : NSObject {
    std::deque<cv::Mat> deq;
    std::vector<cv::Mat> vec;
    cv::Mat dst;
    double _cur_std;
    int test;
    
}

- (UIImage *)Filter:(UIImage *)image;
- (void)init_vec;

@property bool useBlur;
@property int blur0;
@property int blur1;
@property bool useTreshold;
@property bool useAdaptiveTreshold;
@property int adaptiveThreshold0;
@property int adaptiveThreshold1;
@property double cur_std; /*クラス変数に外部からアクセスする際に定義しておくと便利*/
@property int test;

@end

