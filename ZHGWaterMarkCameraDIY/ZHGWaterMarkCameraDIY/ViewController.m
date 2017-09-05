//
//  ViewController.m
//  ZHGWaterMarkCameraDIY
//
//  Created by DDing_Work on 2017/9/5.
//  Copyright © 2017年 DDing_Work. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/PhotosDefines.h>
#import <Photos/Photos.h>

#import "ZHGWaterMarkCameraVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)goMarkCameraVC:(UIButton *)sender {
    
    if ([self isCameraValid]) {
        ZHGWaterMarkCameraVC *cameraVC = [[ZHGWaterMarkCameraVC alloc] init];
        
        [self presentViewController:cameraVC animated:YES completion:nil];
    } else {
        [self alertWithTitle:@"提示" message:@"无访问相机权限，请去设置里设置" OKTitle:@"确定" isNeedCancel:NO cancelSEL:nil handle:nil];

    }
    
    
    
}



- (BOOL)isCanUsePhotos {
    
    //PHAuthorizationStatusNotDetermined = 0, // 用户还未决定
    //PHAuthorizationStatusRestricted,        // 无权访问
    //PHAuthorizationStatusDenied,            // 用户明确拒绝访问
    //PHAuthorizationStatusAuthorized         // 用户允许访问
    
    // 1. 获取当前App的相册授权状态
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    
    // 2. 判断授权状态
    if (authorizationStatus == PHAuthorizationStatusAuthorized) {
        
        // 2.1 如果已经授权, 保存图片(调用步骤2的方法)
        //            [self saveImageToPhotoAlbum:image];
        
    } else if (authorizationStatus == PHAuthorizationStatusNotDetermined) { // 如果没决定, 弹出指示框, 让用户选择
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            // 如果用户选择授权, 则保存图片
            if (status == PHAuthorizationStatusAuthorized) {
                //                    [self saveImageToPhotoAlbum:image];
            } else {
                
            }
        }];
        
    } else {
        //PHAuthorizationStatusRestricted,        // 无权访问
        //PHAuthorizationStatusDenied,            // 用户明确拒绝访问
        //            [SVProgressHUD showWithStatus:@"请在设置界面, 授权访问相册"];
        [self alertWithTitle:@"提示" message:@"无访问相册权限，请去设置里设置" OKTitle:@"确定" isNeedCancel:NO cancelSEL:nil handle:nil];
    }

    
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusRestricted ||
            status == PHAuthorizationStatusDenied) {
            //无权限
            return NO;
        }
    
    return YES;
    
  
}

- (BOOL)isCameraValid
{
    BOOL isCameraValid = YES;

    //AVAuthorizationStatusNotDetermined = 0,  还未选择
    //AVAuthorizationStatusRestricted,      无权访问
    //AVAuthorizationStatusDenied,          明确拒绝
    //AVAuthorizationStatusAuthorized       允许访问
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
        {
            //无权限
            isCameraValid = NO;
        }
    
    
    return isCameraValid;
}

#pragma - 保存至相册
- (void)saveImageToPhotoAlbum:(UIImage*)savedImage
{
    
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
}
// 指定回调方法

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo

{
    NSString *msg = nil ;
    if(error != NULL){
        msg = @"保存图片失败" ;
    }else{
        msg = @"保存图片成功" ;
    }
    [self alertWithTitle:@"保存图片结果提示" message:msg OKTitle:@"确定" isNeedCancel:NO cancelSEL:nil handle:nil];
}


- (void)alertWithTitle:(NSString *)title message:(NSString *)message OKTitle:(NSString *)okTitle isNeedCancel:(BOOL)isNeedCancel cancelSEL:(void (^)())cancelSEL handle:(void(^)())handler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *action = [UIAlertAction actionWithTitle:okTitle style:(UIAlertActionStyleDefault) handler:handler];
    if (isNeedCancel) {
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleDefault) handler:cancelSEL];
        [alertController addAction:cancel];
    }
    
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(BOOL)prefersStatusBarHidden {
    return NO;
}

@end
