//
//  ZHGWaterMarkCameraVC.m
//  ZHGWaterMarkCameraDIY
//
//  Created by DDing_Work on 2017/9/5.
//  Copyright © 2017年 DDing_Work. All rights reserved.
//

#import "ZHGWaterMarkCameraVC.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

//#import "NSDate+Category.h"

#define kScreenBounds   [UIScreen mainScreen].bounds
#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#define kSystemVersion [[[UIDevice currentDevice] systemVersion] floatValue]

@interface ZHGWaterMarkCameraVC ()<UIGestureRecognizerDelegate>

//界面控件
@property (strong, nonatomic)  UIButton *flashButton;

/**
 *  切换摄像头按钮
 */
@property (nonatomic, strong) UIButton *switchButton;
/**
 *  拍照按钮
 */
@property (nonatomic, strong) UIButton *cameraButton;
//AVFoundation

//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic)AVCaptureDevice *device;

@property (nonatomic) dispatch_queue_t sessionQueue;
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;
/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;

/**
 *  照片输出流
 */
//@property (nonatomic, strong) AVCapturePhotoOutput* stillImageOutput;

/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;

/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 *  最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;

/** 水印时间 */
@property (nonatomic, strong) NSString *timeString;
/** 水印日期 */
@property (nonatomic, strong) NSString *dateString;

/** 使用 */
@property (nonatomic, strong) UIButton *useImageBtn;
/** 取消/重拍 */
@property (nonatomic, strong) UIButton *leftButon;

/** 获取拍摄的照片 */
@property (nonatomic, strong) UIImage *image;

/** 闪光灯文字 */
@property (nonatomic, strong) UILabel *flashLabel;

@property (nonatomic)UIView *focusView;

/** 拍完照显示生成的照片，保证预览的效果和实际效果一致 */
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *topBlackView;

@end

@implementation ZHGWaterMarkCameraVC {
    
    BOOL isUsingFrontFacingCamera;
}


#pragma mark life circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initAVCaptureSession];
    [self setUpGesture];
    [self customUI];
    isUsingFrontFacingCamera = NO;
    
    self.effectiveScale = self.beginGestureScale = 1.0f;
    
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        
        [self.session stopRunning];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];

//    if (kSystemVersion <= 9.0) {
//        [[UIApplication sharedApplication] setStatusBarHidden:YES];
//    }

}

-(BOOL)prefersStatusBarHidden {
    return YES;
}


-(void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)customUI{
    
    self.topBlackView = [self createTopBlackView];
    [self topMaskViewWithView:self.topBlackView];
    
    UIView *bottomBlackView = [self bottomBlackView];
    [self bottomMaskViewWithView:bottomBlackView];
    
    _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
    _focusView.layer.borderWidth = 1.0;
    _focusView.layer.borderColor =[UIColor orangeColor].CGColor;
    _focusView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_focusView];
    _focusView.hidden = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGesture:)];
    [self.view addGestureRecognizer:tapGesture];
}
/**
 *  顶部黑色view
 */
-(UIView *)createTopBlackView {
    
    UIView *topBlackView = [self viewWithFrame:CGRectMake(0, 0, kScreenWidth, 50)];
    
    /** 切换前置后置摄像头按钮 */
    _switchButton = [self buttonWithTitle:nil imageName:@"cameraBack" target:self action:@selector(switchCameraSegmentedControlClick:)];
    _switchButton.frame = CGRectMake(kScreenWidth-45, 12.5, 30, 23);
    [topBlackView addSubview:_switchButton];
    
    /** 闪光灯操作 */
    _flashButton = [self buttonWithTitle:nil imageName:@"flashLight" target:self action:@selector(flashButtonClick:)];
    _flashButton.frame = CGRectMake(20, 12.5, 13, 21);
    [topBlackView addSubview:_flashButton];
    
    _flashLabel = [self labelWithText:@"自动" fontSize:14 alignment:NSTextAlignmentCenter];
    _flashLabel.frame = CGRectMake(CGRectGetMaxX(_flashButton.frame), CGRectGetMinY(_flashButton.frame), 50, 21);
    [topBlackView addSubview:self.flashLabel];
    
    UIButton *tapButton = [self buttonWithTitle:nil imageName:nil target:self action:@selector(flashButtonClick:)];
    [tapButton setFrame:(CGRectMake(20, 0, 65, 50))];
    [tapButton setBackgroundColor:[UIColor clearColor]];
    [topBlackView addSubview:tapButton];
    
    return topBlackView;
}
/**
 *  顶部蒙版
 */
-(UIImageView *)topMaskViewWithView:(UIView *)view {
    
    UIImageView *topMaskview = [[UIImageView alloc] initWithFrame:(CGRectMake(0, CGRectGetMaxY(view.frame), kScreenWidth, 100))];
    topMaskview.image = [UIImage imageNamed:@"markTopMView"];
    [self.view addSubview:topMaskview];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy.MM.dd hh:mm"];
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];
    
    
    NSString *dateString = [timeStr substringWithRange:NSMakeRange(0, 10)];
    self.timeString = [timeStr substringWithRange:NSMakeRange(11, 5)];
    NSString *weekDay = [self weekdayStringFromDate:[NSDate date]];
    self.dateString = [NSString stringWithFormat:@"%@ %@",dateString,weekDay];
    
    UILabel *label = [self labelWithText:self.timeString fontSize:30 alignment:0];
    label.frame = CGRectMake(20, 20, 100, 30);
    
    UILabel *dateLabel = [self labelWithText:self.dateString fontSize:14 alignment:0];
    dateLabel.frame = CGRectMake(20, CGRectGetMaxY(label.frame)+5, 200, 15);
    
    [topMaskview addSubview:label];
    [topMaskview addSubview:dateLabel];
    return topMaskview;
}
/**
 *  底部黑色view
 */
-(UIView *)bottomBlackView {
    
    UIView *bottomBlackView = [self viewWithFrame:CGRectMake(0, kScreenHeight - 125, kScreenWidth, 125)];
    
    /** 拍照按钮 */
    self.cameraButton = [self buttonWithTitle:nil imageName:@"cameraPress" target:self action:@selector(takePhotoButtonClick:)];
    self.cameraButton.frame = CGRectMake(kScreenWidth*1/2.0-34, 23, 68, 68);
    [bottomBlackView addSubview:self.cameraButton];
    
    /** 取消/重拍 */
    self.leftButon = [self buttonWithTitle:@"取消" imageName:nil target:self action:@selector(cancle:)];
    self.leftButon.frame = CGRectMake(5, 32.5, 60, 60);
    [bottomBlackView addSubview:self.leftButon];
    
    /** 使用照片 */
    self.useImageBtn = [self buttonWithTitle:@"使用" imageName:nil target:self action:@selector(userImage:)];
    self.useImageBtn.frame = CGRectMake(kScreenWidth -65, 32.5, 50, 50);
    self.useImageBtn.hidden = YES;
    [bottomBlackView addSubview:self.useImageBtn];
    return bottomBlackView;
}
/**
 *  底部蒙版
 */
-(UIImageView *)bottomMaskViewWithView:(UIView *)bottomBlackView {
    
    UIImageView *bottomMaskView = [self imageViewWithImageName:@"markBottomMView" superView:self.view frame:CGRectMake(0, CGRectGetMinY(bottomBlackView.frame) - 100, kScreenWidth, 100)];
    
    CGFloat width = [self calculateRowWidth:@"水印相机" fontSize:14 fontHeight:14];
    UILabel *userLabel = [self labelWithText:@"水印相机" fontSize:14 alignment:2];
    userLabel.frame = CGRectMake(bottomMaskView.frame.size.width - width - 20, 35,width, 30);
    
    [self imageViewWithImageName:@"markUser" superView:bottomMaskView frame:CGRectMake(CGRectGetMinX(userLabel.frame)- 15, userLabel.center.y - 6.5, 13, 13)];
    
    [self imageViewWithImageName:@"markLogo" superView:bottomMaskView frame:CGRectMake(kScreenWidth - 103, 65, 83, 20)];
    
    [bottomMaskView addSubview:userLabel];
    
    return bottomMaskView;
}
/**
 *  创建View
 */
-(UIView *)viewWithFrame:(CGRect)frame {
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:view];
    return view;
}
/**
 *  创建ImageView
 */
-(UIImageView *)imageViewWithImageName:(NSString *)imageName superView:(UIView *)superView frame:(CGRect)frame {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.image = [UIImage imageNamed:imageName];
    [superView addSubview:imageView];
    return imageView;
}

/**
 *  创建button
 */
-(UIButton *)buttonWithTitle:(NSString *)title imageName:(NSString *)imageName target:(id)target action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [button setTitle:title forState:(UIControlStateNormal)];
    UIImage *image = [UIImage imageNamed:imageName];
    [button setImage:image forState:(UIControlStateNormal)];
    [button addTarget:target action:action forControlEvents:(UIControlEventTouchUpInside)];
    
    return button;
}
/**
 *  创建label
 */
-(UILabel *)labelWithText:(NSString *)text fontSize:(CGFloat)fontSize alignment:(NSTextAlignment)alignment {
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:fontSize];
    label.text = text;
    label.textAlignment = alignment;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

-(void)userImage:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(cameraViwe:image:)]) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.delegate cameraViwe:self image:self.image];
    }
}

- (void)focusGesture:(UITapGestureRecognizer*)gesture{
    CGPoint point = [gesture locationInView:gesture.view];
    [self focusAtPoint:point];
}
- (void)focusAtPoint:(CGPoint)point{
    CGSize size = self.view.bounds.size;
    if (point.y > kScreenHeight - 125) {
        return;
    }
    if (point.y < 50) {
        return;
    }
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1-point.x/size.width );
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
        _focusView.center = point;
        _focusView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            _focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                _focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                _focusView.hidden = YES;
            }];
        }];
    }
    
}

-(void)cancle:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"取消"]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [sender setTitle:@"取消" forState:(UIControlStateNormal)];
        [self.imageView removeFromSuperview];
        self.cameraButton.hidden = NO;
        self.useImageBtn.hidden = YES;
        self.flashLabel.hidden = NO;
        self.flashButton.hidden = NO;
        self.switchButton.hidden = NO;
        [self.session startRunning];
    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark private method
- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [self.device lockForConfiguration:nil];
    //设置闪光灯为自动
    [self.device setFlashMode:AVCaptureFlashModeAuto];
    [self.device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    //    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = CGRectMake(0, 0,kScreenWidth, kScreenHeight);
    self.view.layer.masksToBounds = YES;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
}


- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

#pragma 创建手势
- (void)setUpGesture{
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
}

#pragma mark gestureRecognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

#pragma mark respone method
//切换镜头
- (void)switchCameraSegmentedControlClick:(UIButton *)sender {
    
    AVCaptureDeviceDiscoverySession *deviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    
//    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    NSUInteger cameraCount = [deviceSession.devices count];

    if (cameraCount > 1) {
        NSError *error;
        
        CATransition *animation = [CATransition animation];
        
        animation.duration = .3f;
        
        animation.type = @"oglFlip";
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        if (position == AVCaptureDevicePositionFront){
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            animation.subtype = kCATransitionFromLeft;
        }
        else {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            animation.subtype = kCATransitionFromRight;
        }
        
        [self.previewLayer addAnimation:animation forKey:nil];
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        if (newInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.videoInput];
            if ([self.session canAddInput:newInput]) {
                [self.session addInput:newInput];
                self.videoInput = newInput;
                
            } else {
                [self.session addInput:self.videoInput];
            }
            
            [self.session commitConfiguration];
            
        } else if (error) {
            NSLog(@"toggle carema failed, error = %@", error);
        }
    }
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
//    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//    for ( AVCaptureDevice *device in devices )
//        if ( device.position == position ) return device;
//    return nil;
    
    AVCaptureDeviceDiscoverySession *deviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    for ( AVCaptureDevice *device in deviceSession.devices )
        if ( device.position == position ) return device;
    return nil;
}

- (void)takePhotoButtonClick:(UIButton *)sender {
    
    self.useImageBtn.hidden = NO;
    self.flashLabel.hidden = YES;
    self.flashButton.hidden = YES;
    self.switchButton.hidden = YES;
    [self.leftButon setTitle:@"重拍" forState:(UIControlStateNormal)];
    sender.hidden = YES;
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (imageDataSampleBuffer == NULL) {
            return ;
        }
        
//        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        NSData *jpegData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:imageDataSampleBuffer previewPhotoSampleBuffer:nil];
        
        UIImage *image = [UIImage imageWithData:jpegData];
        
        self.image = [self drawMarkImage:image martText:nil rect:kScreenBounds];
        
        [self.session stopRunning];
        self.imageView = [[UIImageView alloc]initWithFrame:self.previewLayer.frame];
        [self.view insertSubview:_imageView belowSubview:_topBlackView];
        self.imageView.layer.masksToBounds = YES;
        self.imageView.image = image;
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
                }
            }];
            
        } else {
            //            [SVProgressHUD showWithStatus:@"请在设置界面, 授权访问相册"];
        }
        
    }];
    
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


- (void)flashButtonClick:(UIButton *)sender {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    AVCapturePhotoOutput
    //修改前必须先锁定
    [device lockForConfiguration:nil];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]) {
        
        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
            self.flashLabel.text = @"打开";
        } else if (device.flashMode == AVCaptureFlashModeOn) {
//            AVCapturePhotoSettings.flashMode = AVCaptureFlashModeAuto;
            device.flashMode = AVCaptureFlashModeAuto;
            self.flashLabel.text = @"自动";
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOff;
            self.flashLabel.text = @"关闭";
        }
        
    } else {
        NSLog(@"设备不支持闪光灯");
    }
    [device unlockForConfiguration];
}

//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if ( ! [self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        
        CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
    }
}
/**
 *  绘制带水印的图片
 */
-(UIImage *)drawMarkImage:(UIImage *)image martText:(NSString *)markText rect:(CGRect)rect {
    
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, 0.0);
    [image drawInRect:rect];
    
    /** 顶部蒙版 */
    CGRect rectTopMask = CGRectMake(0, 0, kScreenWidth, 100);
    UIImage *imageTopMask = [UIImage imageNamed:@"markTopMView"];
    [imageTopMask drawInRect:rectTopMask];
    
    /** 时间 */
    CGRect rectTime = CGRectMake(20, 15, 200, 30);
    NSDictionary *dicTime = @{NSFontAttributeName:[UIFont systemFontOfSize:30],NSForegroundColorAttributeName:[UIColor whiteColor]};
    [self.timeString drawInRect:rectTime withAttributes:dicTime];
    
    /** 日期 */
    CGRect rectDate = CGRectMake(20, CGRectGetMaxY(rectTime) + 5, 200, 25);
    NSDictionary *dicDate = @{NSFontAttributeName:[UIFont systemFontOfSize:15],NSForegroundColorAttributeName:[UIColor whiteColor]};
    [self.dateString drawInRect:rectDate withAttributes:dicDate];
    
    /** 底部蒙版 */
    CGRect rectBottomMask = CGRectMake(0, kScreenHeight - 110, kScreenWidth, 110);
    UIImage *imageBottomMask = [UIImage imageNamed:@"markBottomMView"];
    [imageBottomMask drawInRect:rectBottomMask];
    
    /** 盯盯logo */
    UIImage *logo = [UIImage imageNamed:@"markLogo"];
    [logo drawInRect:CGRectMake(kScreenWidth - 103, kScreenHeight - 70, 83,20)];
    
    /** 用户名 */
    CGFloat width1 = [self calculateRowWidth:@"水印相机" fontSize:14 fontHeight:20];
    CGRect rectUserName = CGRectMake(kScreenWidth - width1 - 20, kScreenHeight - 90, width1, 20);
    NSDictionary *dicUserName = @{NSFontAttributeName:[UIFont systemFontOfSize:14],NSForegroundColorAttributeName:[UIColor whiteColor]};
    [@"水印相机" drawInRect:rectUserName withAttributes:dicUserName];
    
    /** 用户图标 */
    UIImage *imageUser = [UIImage imageNamed:@"markUser"];
    CGRect rectUser = CGRectMake(CGRectGetMinX(rectUserName) - 20, CGRectGetMinY(rectUserName), 13, 13);
    [imageUser drawInRect:rectUser];
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newPic;
}


- (CGFloat)calculateRowWidth:(NSString *)string fontSize:(CGFloat)fontSize fontHeight:(CGFloat) fontHeight{
    NSDictionary *dic = @{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]};  //指定字号
    CGRect rect = [string boundingRectWithSize:CGSizeMake(0, fontHeight)/*计算宽度时要确定高度*/ options:NSStringDrawingUsesLineFragmentOrigin |
                   NSStringDrawingUsesFontLeading attributes:dic context:nil];
    return rect.size.width;
}

/**
 *  获取星期几
 */
- (NSString*)weekdayStringFromDate:(NSDate*)inputDate {
    
    NSArray *weekdays = [NSArray arrayWithObjects: [NSNull null], @"星期日", @"星期一", @"星期二", @"星期三", @"星期四", @"星期五", @"星期六", nil];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSTimeZone *timeZone = [[NSTimeZone alloc] initWithName:@"Asia/Shanghai"];
    [calendar setTimeZone: timeZone];
    NSCalendarUnit calendarUnit = NSCalendarUnitWeekday;
    NSDateComponents *theComponents = [calendar components:calendarUnit fromDate:inputDate];
    
    return [weekdays objectAtIndex:theComponents.weekday];
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


@end
