//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCv : NSObject

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

@end
