//
//  TencentDownLoadManager.m
//  flutter_tencentplayer
//
//  Created by wilson on 2019/8/16.
//

#import "TencentDownLoadManager.h"

@implementation TencentDownLoadManager


- (instancetype)initWithMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
    _call = call;
    _result = result;
 
//    [_eventChannel setStreamHandler:self];
    NSDictionary* argsMap = _call.arguments;
    _path = argsMap[@"savePath"];
    
    NSLog(@"下载地址 %@", _path);
    _urlOrFileId = argsMap[@"urlOrFileId"];
    if (_tXVodDownloadManager == nil) {
        _tXVodDownloadManager = [TXVodDownloadManager shareInstance];
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask, YES);
//        NSString *docPath = [paths lastObject];
//        NSString *downloadPath = [docPath stringByAppendingString:@"/downloader" ];
////        NSLog(downloadPath);
        [_tXVodDownloadManager setDownloadPath:_path];
    }
    _tXVodDownloadManager.delegate = self;
    return  self;
}

//开始下载
- (void)downLoad{
    //设置下载对象
    NSLog(@"开始下载");
    if([_urlOrFileId hasPrefix: @"http"]){
       _tempMedia = [_tXVodDownloadManager startDownloadUrl:_urlOrFileId resolution:-1 userName:@"default"];
    }else{
        NSDictionary* argsMap = _call.arguments;
        int appId = [argsMap[@"appId"] intValue];
        int quanlity = [argsMap[@"quanlity"] intValue];
        _urlOrFileId = argsMap[@"urlOrFileId"];
        TXPlayerAuthParams *auth = [TXPlayerAuthParams new];
        auth.appId =appId;
        auth.fileId = _urlOrFileId;
        TXVodDownloadDataSource *dataSource = [TXVodDownloadDataSource new];
        dataSource.auth = auth;
        dataSource.templateName = @"HLS-标清-SD";
        if (quanlity == 2) {
            dataSource.templateName = @"HLS-标清-SD";
        } else if (quanlity == 3) {
            dataSource.templateName = @"HLS-高清-HD";
        } else if (quanlity == 4) {
            dataSource.templateName = @"HLS-全高清-FHD";
        }
      _tempMedia =  [_tXVodDownloadManager startDownload:dataSource];
    }
    
}


//停止下载
- (void)stopDownLoad{
    NSLog(@"停止下载");
    [_tXVodDownloadManager stopDownload:_tempMedia];
}

// ---------------通信相关
- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    
    NSLog(@"TencentDownLoadManager停止通信");
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    _eventSink = events;
      NSLog(@"TencentDownLoadManager设置全局通信");
    return nil;
}



//----------------下载回调相关

- (void)onDownloadStart:(TXVodDownloadMediaInfo *)mediaInfo {
    [self dealCallToFlutterData:@"start" mediaInfo:mediaInfo ];
}

- (void)onDownloadProgress:(TXVodDownloadMediaInfo *)mediaInfo {
    
    [self dealCallToFlutterData:@"progress" mediaInfo:mediaInfo ];
}

- (void)onDownloadStop:(TXVodDownloadMediaInfo *)mediaInfo {
    
    [self dealCallToFlutterData:@"stop" mediaInfo:mediaInfo ];
    
}
- (void)onDownloadFinish:(TXVodDownloadMediaInfo *)mediaInfo {
    
    [self dealCallToFlutterData:@"complete" mediaInfo:mediaInfo ];
}

- (void)onDownloadError:(TXVodDownloadMediaInfo *)mediaInfo errorCode:(TXDownloadError)code errorMsg:(NSString *)msg {
    
    NSLog(@"onDownloadError");

    NSString *quality = [NSString stringWithFormat:@"%ld",(long)mediaInfo.dataSource.quality];
    NSString *duration = [NSString stringWithFormat:@"%d",mediaInfo.duration];
    NSString *size = [NSString stringWithFormat:@"%d",mediaInfo.size];
    NSString *downloadSize = [NSString stringWithFormat:@"%d",mediaInfo.downloadSize];
    NSString *progress = [NSString stringWithFormat:@"%f",mediaInfo.progress];
  
    if(self->_eventSink != nil){
        NSMutableDictionary* paramDic = [NSMutableDictionary dictionary];
        [paramDic setValue:@"error" forKey:@"downloadStatus"];
        [paramDic setValue:quality forKey:@"quanlity"];
        [paramDic setValue:duration forKey:@"duration"];
        [paramDic setValue:size forKey:@"size"];
        [paramDic setValue:downloadSize forKey:@"downloadSize"];
        [paramDic setValue:progress forKey:@"progress"];
        [paramDic setValue:mediaInfo.playPath forKey:@"playPath"];
        [paramDic setValue:@(true) forKey:@"isStop"];
        [paramDic setValue:mediaInfo.url forKey:@"url"];
        if (mediaInfo.dataSource != nil) {
            [paramDic setValue:mediaInfo.dataSource.auth.fileId forKey:@"fileId"];
        }
        [paramDic setValue:msg forKey:@"error"];

        self->_eventSink(paramDic);
     }
    
}

- (int)hlsKeyVerify:(TXVodDownloadMediaInfo *)mediaInfo url:(NSString *)url data:(NSData *)data {
    NSLog(@"停止下载");
    return 0;
}

- (void)dealCallToFlutterData:(NSString*)type mediaInfo:(TXVodDownloadMediaInfo *)mediaInfo {
    NSLog(@"下载类型");
  
    NSString *quality = [NSString stringWithFormat:@"%ld",(long)mediaInfo.dataSource.quality];
    NSString *duration = [NSString stringWithFormat:@"%d",mediaInfo.duration];
    NSString *size = [NSString stringWithFormat:@"%d",mediaInfo.size];
    NSString *downloadSize = [NSString stringWithFormat:@"%d",mediaInfo.downloadSize];
    NSString *progress = [NSString stringWithFormat:@"%f",mediaInfo.progress];
   

    if (self->_eventSink != nil) {
        NSMutableDictionary* paramDic = [NSMutableDictionary dictionary];
        [paramDic setValue:type forKey:@"downloadStatus"];
        [paramDic setValue:quality forKey:@"quality"];
        [paramDic setValue:duration forKey:@"duration"];
        [paramDic setValue:size forKey:@"size"];
        [paramDic setValue:downloadSize forKey:@"downloadSize"];
        [paramDic setValue:progress forKey:@"progress"];
        [paramDic setValue:mediaInfo.playPath forKey:@"playPath"];
        [paramDic setValue:@(true) forKey:@"isStop"];
        [paramDic setValue:mediaInfo.url forKey:@"url"];
        [paramDic setValue:@"error" forKey:@"error"];
        if (mediaInfo.dataSource != nil) {
            [paramDic setValue:mediaInfo.dataSource.auth.fileId forKey:@"fileId"];
        }
        
        
        self->_eventSink(paramDic);
     }
    
}





@end
