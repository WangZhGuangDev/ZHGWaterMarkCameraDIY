//
//  ZHGWaterMarkCameraVC.h
//  ZHGWaterMarkCameraDIY
//
//  Created by DDing_Work on 2017/9/5.
//  Copyright © 2017年 DDing_Work. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZHGWaterMarkCameraVC;

@protocol ZHGWaterMarkCameraVCDelegate <NSObject>

@optional
-(void)cameraViwe:(ZHGWaterMarkCameraVC *)cameraViwe image:(UIImage *)image;

@end

@interface ZHGWaterMarkCameraVC : UIViewController

/** 代理 */
@property (nonatomic, weak) id<ZHGWaterMarkCameraVCDelegate> delegate;

@end
