# ZHGWaterMarkCameraDIY
自定义水印相机,可以显示日期，名字（此处随便添加的，在项目里是导入的服务器的数据）

自定义水印相机，添加日期水印，logo水印等，代码写的比较low，仅供参考。
**ps(敲黑板了)：如果你的项目仅支持iOS10+，里面的AVCaptureStillImageOutput是废弃的API，使用了AVCapturePhotoOutput（仅限iOS10+），如果最低支持版本小于iOS10，正常使用AVCaptureStillImageOutput就OK**，代码里面有注释

## AVCaptureStillImageOutput 仅支持静态图片捕获，而AVCapturePhotoOutput不仅支持静态图片，还支持Live Photo等，比AVCaptureStillImageOutput更强大，不过还没研究，有待研究

**使用AVCapturePhotoOutput捕获图片需实现以下代理**
```js
#pragma mark - AVCapturePhotoCaptureDelegate

-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error;
```
![image](https://github.com/WangZhGuangDev/ZHGWaterMarkCameraDIY/blob/master/ZHGWaterMarkCameraDIY/ZHGWaterMarkCameraDIY/GifPicture/Untitled.gif)


