//
//  ViewController.m
//  LJXAVCaptureDemo
//
//  Created by 栾金鑫 on 2019/8/29.
//  Copyright © 2019年 栾金鑫. All rights reserved.
//

#import "ViewController.h"
#import "AVCaptureController.h"
#import "XDCaptureService.h"

@interface ViewController ()

@property (nonatomic , strong) UIView * contentView;

@property (nonatomic , strong) UILabel* recordstate; // 录制中

@property (nonatomic , strong) UIButton * recordingBtn;

@property (nonatomic , strong) UIButton * changeBtn;

@property (nonatomic , strong) UIButton * stopBtn;

@property (nonatomic, strong) XDCaptureService *service;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.service startRunning];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.recordingBtn.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 100) /2, 400, 100, 40);
    self.changeBtn.frame = CGRectMake(CGRectGetMinX(self.recordingBtn.frame), CGRectGetMaxY(self.recordingBtn.frame) + 30, CGRectGetWidth(self.recordingBtn.frame), CGRectGetHeight(self.recordingBtn.frame));
    self.stopBtn.frame = CGRectMake(CGRectGetMinX(self.recordingBtn.frame), CGRectGetMaxY(self.changeBtn.frame) + 30, CGRectGetWidth(self.recordingBtn.frame), CGRectGetHeight(self.recordingBtn.frame));
    
    self.recordstate.frame = CGRectMake(20, 60, 120, 40);
    
    [self.view addSubview: self.recordingBtn];
    [self.view addSubview: self.changeBtn];
    [self.view addSubview: self.stopBtn];
    
    [self.view addSubview: self.contentView];
    [self.view addSubview: self.recordstate];
}

- (UIButton *)recordingBtn {
    if (!_recordingBtn) {
        _recordingBtn = [UIButton new];
        [_recordingBtn setTitle:@"开始录制" forState:UIControlStateNormal];
        [_recordingBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_recordingBtn addTarget:self action:@selector(beginAction) forControlEvents:UIControlEventTouchDown];
    }
    return _recordingBtn;
}

- (UIButton *)changeBtn {
    if (!_changeBtn) {
        _changeBtn = [UIButton new];
        [_changeBtn setTitle:@"切换摄像头" forState:UIControlStateNormal];
        [_changeBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
         [_changeBtn addTarget:self action:@selector(changeAction) forControlEvents:UIControlEventTouchDown];
    }
    return _changeBtn;
}

- (UIButton *)stopBtn {
    if (!_stopBtn) {
        _stopBtn = [UIButton new];
        [_stopBtn setTitle:@"停止录制" forState:UIControlStateNormal];
        [_stopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_stopBtn addTarget:self action:@selector(stopAction) forControlEvents:UIControlEventTouchDown];

    }
    return _stopBtn;
}

- (UIView *)contentView{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 400)];
        _contentView.backgroundColor = [UIColor redColor];
        
    }
    return _contentView;
}

- (UILabel *)recordstate {
    if (!_recordstate) {
        _recordstate = [UILabel new];
        _recordstate.font = [UIFont systemFontOfSize:22];
        _recordstate.text = @"录制中...";
        _recordstate.textColor = [UIColor yellowColor];
        _recordstate.hidden = YES;
    }
    return _recordstate;
}

- (void) beginAction {
//    [self presentViewController:[AVCaptureController new] animated:YES completion:nil];
    
    [self.service startRecording];
    self.recordstate.hidden = NO;
}

- (void) changeAction {
     [self.service switchCamera];
}

- (void) stopAction {
    self.recordstate.hidden = YES;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"停止录像" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    [self.service stopRecording];
}

//service生命周期
- (void)captureServiceDidStartService:(XDCaptureService *)service {
    NSLog(@"captureServiceDidStartService");
}

- (void)captureService:(XDCaptureService *)service serviceDidFailWithError:(NSError *)error {
    NSLog(@"serviceDidFailWithError:%@",error.localizedDescription);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)captureServiceDidStopService:(XDCaptureService *)service {
    NSLog(@"captureServiceDidStopService");
}

- (void)captureService:(XDCaptureService *)service getPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    if (previewLayer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_contentView.layer addSublayer:previewLayer];
            previewLayer.frame = _contentView.bounds;
        });
    }
}

- (void)captureService:(XDCaptureService *)service outputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
}

//录像相关
- (void)captureServiceRecorderDidStart:(XDCaptureService *)service {
    NSLog(@"captureServiceRecorderDidStart");
}

- (void)captureService:(XDCaptureService *)service recorderDidFailWithError:(NSError *)error {
    NSLog(@"recorderDidFailWithError:%@",error.localizedDescription);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)captureServiceRecorderDidStop:(XDCaptureService *)service {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:service.recordURL options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    CMTime actualTime;
    CGImageRef img = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:nil];
    UIImage *image = [[UIImage alloc] initWithCGImage:img];
    CGImageRelease(img);
    dispatch_async(dispatch_get_main_queue(), ^{
//        _imageView.image = image;
//        _label.text = @"Video";
    });
}

//照片捕获
- (void)captureService:(XDCaptureService *)service capturePhoto:(UIImage *)photo {
    dispatch_async(dispatch_get_main_queue(), ^{
//        _imageView.image = photo;
//        _label.text = @"Photo";
    });
}

@end
