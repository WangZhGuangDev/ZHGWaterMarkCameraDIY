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
-(void)markCameraController:(ZHGWaterMarkCameraVC *)markCameraVC image:(UIImage *)image;

@end

@interface ZHGWaterMarkCameraVC : UIViewController

/** 代理 */
@property (nonatomic, weak) id<ZHGWaterMarkCameraVCDelegate> delegate;

/** 是否需要12小时制处理，default is NO */
@property (nonatomic, assign) BOOL isTwelveHandle;

@end
