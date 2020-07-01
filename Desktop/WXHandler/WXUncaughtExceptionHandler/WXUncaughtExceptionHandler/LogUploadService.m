//
//  LogUploadService
//  PAQZZ
//
//  Created by Wesley Yang on 2018/1/23.
//  Copyright © 2018年 壹钱包. All rights reserved.
//

#import "LogUploadService.h"
#import <SSZipArchive/SSZipArchive.h>

NSString *const LogUploadServerURL = @"https://ubaslog..com";

@interface LogUploadService ()
@property(nonatomic, strong) NSArray<NSString *> *filesToBeUploaded;
@end

@implementation LogUploadService

-(NSArray *)getCrashFilePaths{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"/Caches/CrashLog"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSArray<NSString *> *allFiles = [fm contentsOfDirectoryAtPath:filePath error:&error];
    
    if (error) {
        return nil;
    }
    NSMutableArray *files = [NSMutableArray array];
    for (NSString *file in allFiles) {
        if([file.pathExtension isEqualToString:@"txt"]){
            [files addObject:file];
        }
    }
    
    NSArray *sortedFiles = [files sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSMutableArray *filePaths = [NSMutableArray array];
    for (NSString *file in sortedFiles) {
        NSString *path = [filePath stringByAppendingPathComponent:file];
        [filePaths addObject:path];
    }
    return filePaths;
}

- (void)uploadLog {
    NSMutableArray *filePaths = [NSMutableArray array];
    NSArray *crashPaths = [self getCrashFilePaths];
    if (crashPaths) {
        [filePaths addObjectsFromArray:crashPaths];
    }

    if (filePaths.count == 0) {
        NSError *error = [NSError errorWithDomain:@"CK" code:1 userInfo:@{NSLocalizedFailureReasonErrorKey:@"没有日志可供上传"}];
        [self onUploadFailedWithError:error];
        return;
    }

    self.filesToBeUploaded = filePaths;

    [self __uploadLeftFiles];
}

- (void)__uploadLeftFiles {
    if (self.filesToBeUploaded.count == 0) {
        [self onUploadComplete];
        return;
    }

    NSFileManager *fm = [NSFileManager defaultManager];

    unsigned long long maxAccSize = 900 * 1024;//max:900kB
    unsigned long long accSize = 0;
    NSMutableArray *filesToUpload = [NSMutableArray array];
    NSMutableArray *filesLeft = [NSMutableArray arrayWithArray:self.filesToBeUploaded];
    for (NSString *filePath in self.filesToBeUploaded) {
        unsigned long long fileSize = [[fm attributesOfItemAtPath:filePath error:nil] fileSize];
        if (fileSize > maxAccSize) {//this is impossible as we set max log file size.
            [filesLeft removeObject:filePath];
            continue;
        }
        if (accSize + fileSize > maxAccSize) {
            break;
        }
        accSize += fileSize;
        [filesToUpload addObject:filePath];
        [filesLeft removeObject:filePath];
    }

    self.filesToBeUploaded = [NSArray arrayWithArray:filesLeft];
    [self __uploadFiles:filesToUpload];
}

- (void)__uploadFiles:(NSArray<NSString *> *)files {
    if (files.count == 0) {
        [self onUploadComplete];
        return;
    }

    NSString *zipFilePath = [self tempZipFilePath];
    BOOL success = [self zipFiles:files to:zipFilePath];

    if (!success || ![[NSFileManager defaultManager] fileExistsAtPath:zipFilePath]) {
        NSError *error = [NSError errorWithDomain:@"CK" code:2 userInfo:@{NSLocalizedFailureReasonErrorKey:@"日志打包失败"}];
        [self onUploadFailedWithError:error];
        return;
    }

    NSError *error;
    NSData *fileData = [NSData dataWithContentsOfFile:zipFilePath options:0 error:&error];

    if (error) {
        [self onUploadFailedWithError:error];
        return;
    }

    __weak typeof(self) wself = self;
    [self uploadFileToURL:LogUploadServerURL headerParams:[self headerInfo] body:fileData completeHander:^(NSURLResponse *response, NSData *data, NSError *error) {
        [wself deleteTempZipFile];
        if (error) {
            [wself onUploadFailedWithError:error];
        } else {
            //if success
            [wself __uploadLeftFiles];
        }
    }];
}


- (NSDictionary *)headerInfo {
//    NSMutableDictionary *header = [NSMutableDictionary dictionary];
//    header[@"platform"] = @"iOS";
//    header[@"uploadDate"] = [CKCarDateTools getGMTTimeWithType:@"yyyy/MM/dd HH:mm:ss"];
//    header[@"userName"] = self.userPhoneWithMask;
//    header[@"deviceToken"] = [UBAAgent trackUUID];
//    header[@"version"] = [CKVersionTools getAppVersion];
//    header[@"uploadDeviceModel"] = [PAFDeviceInfo currentDeviceInfo].deviceModel;
//    header[@"uploadOsVersion"] = [PAFDeviceInfo currentDeviceInfo].osVersion;
//    header[@"buildCommitVersion"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
//    header[@"mgNo"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
//    return header;
    return nil;
}


- (NSString *)tempZipFilePath {
    NSString *tempDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    return [tempDir stringByAppendingPathComponent:@"xlog_temp.zip"];
}

- (void)deleteTempZipFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *zipFilePath = [self tempZipFilePath];
    if ([fm fileExistsAtPath:zipFilePath]) {
        [fm removeItemAtPath:zipFilePath error:NULL];
    }
}

- (BOOL)zipFiles:(NSArray *)files to:(NSString *)zipFilePath {
    NSString *pwd = [self userPhoneWithMask];

    if (!pwd) {
        pwd = @"           ";
    }

    return [SSZipArchive createZipFileAtPath:zipFilePath withFilesAtPaths:files withPassword:pwd];
}

- (void)uploadFileToURL:(NSString *)serverURL headerParams:(NSDictionary *)headerParams body:(NSData *)body completeHander:(void (^)(NSURLResponse *, NSData *, NSError *))completeHander {
    NSURL *URL = [[NSURL alloc] initWithString:serverURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:120];

    request.HTTPMethod = @"POST";
    request.allHTTPHeaderFields = headerParams;

    request.HTTPBody = body;
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long) body.length] forHTTPHeaderField:@"Content-Length"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (completeHander) {
            completeHander(response, data, error);
        }
    }];
    [task resume];
}

#define dispatch_main_async(codeInvoke)\
if ([NSThread isMainThread])\
{\
codeInvoke;\
}\
else\
{\
dispatch_async(dispatch_get_main_queue(), ^{codeInvoke;});\
}

- (void)onUploadComplete {
    dispatch_main_async(
            [self.delegate logUploadDidFinish];
    )
}

- (void)onUploadFailedWithError:(NSError *)error {
    dispatch_main_async(
            [self.delegate logUploadDidFailWithError:error];
    )
}

@end
