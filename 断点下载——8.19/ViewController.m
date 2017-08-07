//
//  ViewController.m
//  断点下载——8.19
//
//  Created by zhangwenjin on 15-8-20.
//  Copyright (c) 2015年 张文进. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *sliderView;//进度条
@property (weak, nonatomic) IBOutlet UILabel *progress;
@property (nonatomic,strong)AFHTTPRequestOperation *operation;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //创建存放临时文件的路径
    NSString *txtTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mvTemp/mv.txt"];
    // 创建文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSLog(@"%@",fileManager);
    if ([fileManager fileExistsAtPath:txtTempPath]) {
        // 如果下载的时候，可以看下载的进度
        _sliderView.progress = [[NSString stringWithContentsOfFile:txtTempPath encoding:NSUTF8StringEncoding error:nil] floatValue];
    }
    _sliderView.progress = 0;
    _progress.text = [NSString stringWithFormat:@"%.2f%%",_sliderView.progress*100];
    
    NSLog(@"%@",NSHomeDirectory());
    
    
    // Do any additional setup after loading the view from its nib.
}
- (IBAction)startDownload:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"开始下载"]) {
        // 设置点击的时候button更改为暂停下载
        [sender setTitle:@"暂停下载" forState:UIControlStateNormal];
        // 创建url对象
        NSURL *url = [NSURL URLWithString:@"http://www.demaxiya.com/app/index.php?m=play&vid=29996&quality=1"];
        // 获取cache文件夹路径
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)firstObject];
        // 创建文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 给cache文件夹拼接一个路径,用来存放mv文件（存放视频的文件）
        NSString *folderPath = [cachePath stringByAppendingPathComponent:@"mv"];
        // 创建临时文件夹路径(存放视频的缓存文件)
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mvTemp"];
        // 判断缓存文件夹和视频文件夹是否存在。如果不存在。就创建一个文件夹
        if (![fileManager fileExistsAtPath:folderPath]) {
            [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if (![fileManager fileExistsAtPath:tempPath]) {
            [fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        //拼接缓存文件的路径
        NSString *tempFilePath = [tempPath stringByAppendingPathComponent:@"mv.temp"];
        // 拼接存放mv文件的路径
        NSString *mvFilePath = [folderPath stringByAppendingPathComponent:@"mv.mp4"];
        // 保存重启程序下载的进度
        NSString *txtFilePath = [tempPath stringByAppendingPathComponent:@"mv.txt"];
        unsigned long long downloadedBytes = 0;
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        // 如果存在，说明存在缓存文件
        if ([fileManager fileExistsAtPath:tempFilePath]) {
            // 计算文件的大小
            downloadedBytes = [self fileSizeAtPath:tempFilePath];
            //将不可变的URLRequest对象转化为可变的
            NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
            // 把上次下载的文件转化为字符串的形式
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-",downloadedBytes];
          // 把每次下载下来的数据添加到请求
            [mutableURLRequest setValue:requestRange forHTTPHeaderField:@"Range"];
            request = mutableURLRequest;
        }
        // 如果还没有下载，则开始下载
        if (![fileManager fileExistsAtPath:mvFilePath]) {
            // 移除之前的请求，请求剩下的数据。之前的数据就不需要下载了
            [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
            // 重新请求数据
            self.operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
        // 接着上面的数据继续写入文件
            [_operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:tempFilePath append:YES]];
            [_operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                _sliderView.progress = [[NSString stringWithFormat:@"%.3f",((float)totalBytesRead + downloadedBytes)/(totalBytesExpectedToRead + downloadedBytes)] floatValue];
            NSLog(@"*+**+*+*+*+*+*+*%lld",totalBytesExpectedToRead);
            _progress.text = [NSString stringWithFormat:@"%.2f%%",_sliderView.progress * 100];
            NSString *progress = [NSString stringWithFormat:@"%.3f",((float)totalBytesRead + downloadedBytes)/(totalBytesExpectedToRead + downloadedBytes)];
            [progress writeToFile:txtFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
        }];
            // 保存到下载mv的文件路径中
          [_operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
              // 把下载完成的文件转移到保存的路径
              [fileManager moveItemAtPath:tempFilePath toPath:mvFilePath error:nil];
              // 删除保存进度的txt文件
              [fileManager removeItemAtPath:txtFilePath error:nil];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
          }];
            [_operation start];
            
        }else{
        }
    }else{
        [sender setTitle:@"开始下载" forState:UIControlStateNormal];
        [self.operation cancel];
        self.operation = nil;
    }
}







- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// 计算缓存文件大小的方法
- (unsigned long long)fileSizeAtPath:(NSString *)fileAbsolutePath{
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new];
    if ([fileManager fileExistsAtPath:fileAbsolutePath]) {
        NSError *error = nil;
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:fileAbsolutePath error:nil];
        if (!error && fileDic) {
            fileSize = [fileDic fileSize];
        }
    }
    return fileSize;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
