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

@interface ViewController ()<ZHGWaterMarkCameraVCDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)goMarkCameraVC:(UIButton *)sender {
    
    if ([self isCameraValid]) {
        ZHGWaterMarkCameraVC *cameraVC = [[ZHGWaterMarkCameraVC alloc] init];
        cameraVC.delegate = self;
        [self presentViewController:cameraVC animated:YES completion:nil];
    } else {
        [self alertWithTitle:@"提示" message:@"无访问相机权限，请去设置里设置" OKTitle:@"确定" isNeedCancel:NO cancelSEL:nil handle:nil];

    }
}


-(void)markCameraController:(ZHGWaterMarkCameraVC *)markCameraVC image:(UIImage *)image {
    [self.imageView setImage:image];
}



- (BOOL)isCameraValid
{
    BOOL isCameraValid = YES;

    //AVAuthorizationStatusNotDetermined = 0,  还未选择
    //AVAuthorizationStatusRestricted,      无权访问
    //AVAuthorizationStatusDenied,          明确拒绝
    //AVAuthorizationStatusAuthorized       允许访问
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) {
        isCameraValid = NO;
    }
    return isCameraValid;
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
