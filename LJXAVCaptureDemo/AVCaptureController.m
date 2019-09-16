//
//  AVCaptureController.m
//  LJXAVCaptureDemo
//
//  Created by 栾金鑫 on 2019/8/29.
//  Copyright © 2019年 栾金鑫. All rights reserved.
//

#import "AVCaptureController.h"
#import <AVFoundation/AVFoundation.h>
#import "LJXAVCaptureView.h"

@interface AVCaptureController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic , strong) LJXAVCaptureView * captureView;

@property (nonatomic , strong) UIButton * backBtn;

@property (nonatomic, strong) AVCaptureDevice *captureDevice;   // 输入设备
@property (nonatomic , strong) AVCaptureVideoDataOutput * videoOutPut;
@property (nonatomic , strong) AVCaptureSession * ljxSession;
@property (nonatomic , strong) AVCaptureMovieFileOutput * captureMovieOutPut;
@property (nonatomic , strong) UIView * ljxDisPlayView;
@property (nonatomic, assign) AVCaptureDevicePosition position;//设置焦点
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput; // 输入源
@end

@implementation AVCaptureController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![self.ljxSession isRunning]) {
        [self.ljxSession startRunning];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.backBtn.frame = CGRectMake(20, 30, 60, 60);
    
    [self.view addSubview: self.backBtn];
    
    [self.view addSubview:self.captureView];
    [self.captureView startCapture];
//    [self initCapture];
}

- (void) initCapture {
    NSError * error = nil;
    // 设置分辨率
    AVCaptureSession * session = [[AVCaptureSession alloc] init];
    if ([session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        session.sessionPreset = AVCaptureSessionPreset1920x1080;
    } else {
        session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    // 初始化相机
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput * deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error || !deviceInput) {
        NSLog(@"get input device error...");
        return;
    }
    // 输出流
    self.videoOutPut = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput: self.videoOutPut];
    
    self.videoOutPut.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    self.videoOutPut.alwaysDiscardsLateVideoFrames = NO;
    
    dispatch_queue_t video_queue = dispatch_queue_create("LJXVideoQueue", DISPATCH_QUEUE_CONCURRENT);
    // 代理
    [self.videoOutPut setSampleBufferDelegate:self queue:video_queue];
    
    CMTime frameDuration = CMTimeMake(1, 30);
    BOOL frameRatesupported = NO;
    
    for (AVFrameRateRange *range in [device.activeFormat videoSupportedFrameRateRanges]) {
        if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) && CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
            frameRatesupported = YES;
        }
    }
    
    if (frameRatesupported && [device lockForConfiguration:&error]) {
        [device setActiveVideoMaxFrameDuration:frameDuration];
        [device setActiveVideoMinFrameDuration:frameDuration];
        [device unlockForConfiguration];
    }
    
    [self adjustVideoStabilization];
    
    self.ljxSession = session;
    
    CALayer *previewViewLayer = [self.ljxDisPlayView layer];
    previewViewLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    AVCaptureVideoPreviewLayer * newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.ljxSession];
    newPreviewLayer.frame = [UIApplication sharedApplication].keyWindow.bounds;
    
    [newPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [previewViewLayer insertSublayer:newPreviewLayer atIndex:0];
    
}
/* 调整视频稳定性 */
- (void) adjustVideoStabilization {
    NSArray * devices = [AVCaptureDevice devices];
    for (AVCaptureDevice * device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeAuto]) {
                for (AVCaptureConnection * connection in self.videoOutPut.connections) {
                    for (AVCaptureInputPort *port in [connection inputPorts]) {
                        if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                            if (connection.supportsVideoStabilization) {
                                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeStandard;
                                 NSLog(@"now videoStabilizationMode = %ld",(long)connection.activeVideoStabilizationMode);
                            } else {
                                NSLog(@"connection does not support video stablization");                           }
                        }
                    }
                }
            }else{
                NSLog(@"device does not support video stablization");
            }
        }
    }
}

#pragma mark - delegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"%s",__func__);
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
     NSLog(@"MediaIOS: 丢帧...");
}

#pragma mark - 获取焦点
-(AVCaptureDevicePosition)position{
    if (!_position) {
        _position = AVCaptureDevicePositionFront;
    }
    return _position;
}

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton new];
        [_backBtn setTitle:@"返回" forState:UIControlStateNormal];
        [_backBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchDown];
    }
    return _backBtn;
}

#pragma mark - 初始化设备输出对象，用于获得输出数据
- (AVCaptureMovieFileOutput *)captureMovieOutPut {
    if(_captureMovieOutPut == nil) {
        _captureMovieOutPut = [[AVCaptureMovieFileOutput alloc]init];
    }
    return _captureMovieOutPut;
}

- (void) backAction {
    
    [self dismissViewControllerAnimated:self completion:^{
        if ([self.ljxSession isRunning]) {
            [self.ljxSession stopRunning];
        }
    }];
}

- (void) startCapture {
    // 正在播放
    if ([self.captureMovieOutPut isRecording]) {
        return;
    }
}

#pragma mark - 切换前后摄像头
- (void)cameraPosition:(NSString *)camera{
    if ([camera isEqualToString:@"前置"]) {
        if (self.captureDevice.position != AVCaptureDevicePositionFront) {
            self.position = AVCaptureDevicePositionFront;
        }
    }
    else if ([camera isEqualToString:@"后置"]){
        if (self.captureDevice.position != AVCaptureDevicePositionBack) {
            self.position = AVCaptureDevicePositionBack;
        }
    }
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:self.position];
    if (device) {
        self.captureDevice = device;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
        [self.ljxSession beginConfiguration];
        [self.ljxSession removeInput:self.captureDeviceInput];
        if ([self.ljxSession canAddInput:input]) {
            [self.ljxSession addInput:input];
            self.captureDeviceInput = input;
            [self.ljxSession commitConfiguration];
        }
    }
}

- (LJXAVCaptureView *)captureView {
    if (!_captureView) {
        _captureView = [LJXAVCaptureView new];
    }
    return _captureView;
}

@end
