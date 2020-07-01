//
//  LogUploadService
//  PAQZZ
//
//  Created by Wesley Yang on 2018/1/23.
//  Copyright © 2018年 壹钱包. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol LogUploadServiceDelegate

@required
//上传失败
- (void)logUploadDidFailWithError:(NSError *)error;
//上传成功
- (void)logUploadDidFinish;
@end


/**
 日志上传服务. 上传后到ubas-applog.pinganfu.net/logsearch上下载日志
 */
@interface LogUploadService : NSObject

@property(nonatomic, weak) id <LogUploadServiceDelegate> delegate;

//手机号掩码，可选。用于在平台上查找日志
@property(nonatomic, copy) NSString *userPhoneWithMask;

/**
 开始上传日志。
 */
- (void)uploadLog;

@end
