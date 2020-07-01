//
//  ViewController.m
//  WXUncaughtExceptionHandler
//
//  Created by wangxinxu on 2018/8/15.
//  Copyright © 2018年 wangxinxu. All rights reserved.
//

#import "ViewController.h"
#import "LogUploadService.h"

@interface ViewController ()<UIAlertViewDelegate,LogUploadServiceDelegate>
@property (nonatomic,strong) LogUploadService *logUploadService;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSArray *titleArr = @[@"数组越界", @"空对象", @"正常提示操作"];
    for (int i = 0; i < 3; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake((self.view.frame.size.width - 200) / 2, 200 + 80 * i, 200, 50);
        button.backgroundColor = [UIColor grayColor];
        button.tag = 1000 + i;
        [button setTitle:titleArr[i] forState:UIControlStateNormal];
         [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.view addSubview:button];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)buttonClick:(UIButton *)btn {
    switch (btn.tag - 1000) {
        case 0:
            [self arrayError];
            break;
        case 1:
            [self objectError];
            break;
        case 2:
            [self alertView];
            break;
        default:
            break;
    }
}

-(void)arrayError {
    NSArray *array = @[@"aaaa"];
    NSLog(@"%@",array[10]);
}

-(void)objectError {
    NSString *beaconName = nil;
    NSDictionary *test = @{@"name":@"亦凡空",
                           @"age":beaconName};
    NSLog(@"test == %@",test);
}

-(void)alertView {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"标题" message:@"上传日志!" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
    alert.delegate = self;
    [alert show];
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    #pragma mark 上传本地日志
    self.logUploadService = [[LogUploadService alloc] init];
    self.logUploadService.delegate = self;
    [self.logUploadService uploadLog];
}


-(void)logUploadDidFinish
{//日志上传成功
//    [CKHUDLoadingService.share dismiss];
//    [CKToast.sharedInstance showToastWithText:@""];
}

-(void)logUploadDidFailWithError:(NSError *)error
{//日志上传失败
//    [CKHUDLoadingService.share dismiss];
//    [CKToast.sharedInstance showToastWithText:error.localizedFailureReason];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
