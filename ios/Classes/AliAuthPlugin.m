#import "AliAuthPlugin.h"

#import <UIKit/UIKit.h>

#import <ATAuthSDK/ATAuthSDK.h>
//#import "ProgressHUD.h"
#import "PNSBuildModelUtils.h"

@implementation AliAuthPlugin {
  FlutterEventSink _eventSink;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  AliAuthPlugin* instance = [[AliAuthPlugin alloc] init];
  
  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"ali_auth" binaryMessenger: [registrar messenger]];

  [registrar addMethodCallDelegate:instance channel: channel];
}


#pragma mark - flutter调用 oc eventChannel start
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
   // SDK 初始化
  if ([@"init" isEqualToString:call.method]) {
      NSDictionary *dic = call.arguments;
      if ([dic isKindOfClass:[NSDictionary class]]) {
        NSString *secret =dic[@"sk"];

        __weak typeof(self) weakSelf = self;
        [[TXCommonHandler sharedInstance] setAuthSDKInfo:secret complete:^(NSDictionary * _Nonnull resultDic) {
          [weakSelf showResult:resultDic result:result];
        }];
        
        //显示版本信息
        NSLog(@"foxlogsdk version：%@；cm sdk version：5.7.1.beta；ct sdk version：3.6.2.1；cu sdk version：4.0.1 IR02B1030",
          [[TXCommonHandler sharedInstance] getVersion]
        );

      }
  }
  else if ([@"checkVerifyEnable" isEqualToString:call.method]) {
    [self checkVerifyEnable:call result:result];
  }
  else  if ([@"login" isEqualToString:call.method]) {
    [self getLoginTokenFullVertical:call result:result];
  }
  else  if ([@"preLogin" isEqualToString:call.method]) {
    [self getPreLogin:call result:result];
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

#pragma mark  ======在view上添加UIViewController========
- (UIViewController *)findCurrentViewController{
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    UIViewController *topViewController = [window rootViewController];
    while (true) {
        if (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        } else if ([topViewController isKindOfClass:[UINavigationController class]] && [(UINavigationController*)topViewController topViewController]) {
            topViewController = [(UINavigationController *)topViewController topViewController];
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    return topViewController;
}


/** SDK 判断网络环境是否支持 */
- (void)checkVerifyEnable:(FlutterMethodCall*)call result:(FlutterResult)result {
    __weak typeof(self) weakSelf = self;
  
    bool bool_true = true;
    bool bool_false = false;
  
    [[TXCommonHandler sharedInstance] checkEnvAvailableWithComplete:^(NSDictionary * _Nullable resultDic) {

        if ([PNSCodeSuccess isEqualToString:[resultDic objectForKey:@"resultCode"]] == NO) {
            [weakSelf showResult:resultDic result:result];
            result(@(bool_false));
            return;
        } else {
            result(@(bool_true));
        }
    }];
}

// 一键登录(竖屏全屏)
- (void)getLoginTokenFullVertical:(FlutterMethodCall*)call result:(FlutterResult)result{
    TXCustomModel *model = [PNSBuildModelUtils buildFullScreenModel];
    model.supportedInterfaceOrientations = UIInterfaceOrientationMaskPortrait;
    [self startLoginWithModel:model call:call result:result complete:^{}];
}
// 一键登录预取号
- (void)getPreLogin:(FlutterMethodCall*)call result:(FlutterResult)result{
    TXCustomModel *model = [PNSBuildModelUtils buildFullScreenModel];
    model.supportedInterfaceOrientations = UIInterfaceOrientationMaskPortrait;
    [self accelerateLogin:model call:call result:result complete:^{}];
}

/**
   * 函数名: accelerateLoginPageWithTimeout
  * @brief 加速一键登录授权页弹起，防止调用 getLoginTokenWithTimeout:controller:model:complete: 等待弹起授权页时间过长
   * @param timeout：接口超时时间，单位s，默认3.0s，值为0.0时采用默认超时时间
   * @param complete 结果异步回调，成功时resultDic=@{resultCode:600000, msg:...}，其他情况时"resultCode"值请参考PNSReturnCode
*/
#pragma mark - action 一键登录预取号
- (void)accelerateLogin:(TXCustomModel *)model call:(FlutterMethodCall*)call result:(FlutterResult)result complete:(void (^)(void))completion {
    float timeout = 5.0; //self.tf_timeout.text.floatValue;
    __weak typeof(self) weakSelf = self;
    
    //1. 调用check接口检查及准备接口调用环境
    [[TXCommonHandler sharedInstance] checkEnvAvailableWithComplete:^(NSDictionary * _Nullable resultDic) {

        if ([PNSCodeSuccess isEqualToString:[resultDic objectForKey:@"resultCode"]] == NO) {
            [weakSelf showResult:resultDic result:result];
            return;
        }
        
        //2. 调用取号接口，加速授权页的弹起
        [[TXCommonHandler sharedInstance] accelerateLoginPageWithTimeout:timeout complete:^(NSDictionary * _Nonnull resultDic) {
            if ([PNSCodeSuccess isEqualToString:[resultDic objectForKey:@"resultCode"]] == NO) {
                NSString *code = [resultDic objectForKey:@"resultCode"];
                [weakSelf showResult:resultDic result:result];
                NSDictionary *dict = @{
                    @"returnCode": code,
                    @"returnMsg" : [resultDic objectForKey:@"msg"],
                    @"returnData" : [resultDic objectForKey:@"token"]?:@""
                };
                result(dict);
                return ;
            }
            
            [weakSelf showResult:resultDic result:result];
        }];
    }];
}

#pragma mark - action 一键登录公共方法
- (void)startLoginWithModel:(TXCustomModel *)model call:(FlutterMethodCall*)call result:(FlutterResult)result complete:(void (^)(void))completion {
    float timeout = 5.0; //self.tf_timeout.text.floatValue;
    __weak typeof(self) weakSelf = self;
    UIViewController *_vc = [self findCurrentViewController];
    
    //1. 调用check接口检查及准备接口调用环境
    [[TXCommonHandler sharedInstance] checkEnvAvailableWithComplete:^(NSDictionary * _Nullable resultDic) {

        if ([PNSCodeSuccess isEqualToString:[resultDic objectForKey:@"resultCode"]] == NO) {
            [weakSelf showResult:resultDic result:result];
            return;
        }

        //2. 调用取号接口，加速授权页的弹起
        [[TXCommonHandler sharedInstance] accelerateLoginPageWithTimeout:timeout complete:^(NSDictionary * _Nonnull resultDic) {

            if ([PNSCodeSuccess isEqualToString:[resultDic objectForKey:@"resultCode"]] == NO) {
                NSString *code = [resultDic objectForKey:@"resultCode"];
                [weakSelf showResult:resultDic result:result];
                NSDictionary *dict = @{
                    @"returnCode": @"600002",
                    @"returnMsg" : [resultDic objectForKey:@"msg"],
                    @"returnData" : [resultDic objectForKey:@"token"]?:@""
                };
                result(dict);
                return ;
            }

            //3. 调用获取登录Token接口，可以立马弹起授权页
            [[TXCommonHandler sharedInstance] getLoginTokenWithTimeout:timeout controller:_vc model:model complete:^(NSDictionary * _Nonnull resultDic) {
                NSString *code = [resultDic objectForKey:@"resultCode"];

                 NSLog(@"foxlog resultDic: %@", resultDic);

                if ([PNSCodeSuccess isEqualToString:code]) {
                    //点击登录按钮获取登录Token成功回调
                    // NSString *token = [resultDic objectForKey:@"token"];
                    
                    // NSLog( @"获取到token---->>>%@<<<-----", token );
                    
                    // NSLog( @"打印全部数据日志---->>>%@", resultDic );
                  
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
                    });
                    NSDictionary *dict = @{
                        @"returnCode": code,
                        @"returnMsg" : [resultDic objectForKey:@"msg"],
                        @"returnData" : [resultDic objectForKey:@"token"]?:@""
                    };
                    result(dict);
                } else if ([PNSCodeLoginControllerClickCancel isEqualToString:code]) {
                    NSDictionary *dict = @{
                        @"returnCode": code,
                        @"returnMsg" : [resultDic objectForKey:@"msg"],
                        @"returnData" : [resultDic objectForKey:@"token"]?:@""
                    };
                    result(dict);
                } else if ([PNSCodeLoginControllerClickChangeBtn isEqualToString:code]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
                    });
                     NSDictionary *dict = @{
                         @"returnCode": code,
                         @"returnMsg" : [resultDic objectForKey:@"msg"],
                         @"returnData" : [resultDic objectForKey:@"token"]?:@""
                 };
                    result(dict);
                 }
                [weakSelf showResult:resultDic result:result];
            }];
        }];
    }];
}

#pragma mark -  格式化数据utils
- (void)showResult:(id __nullable)showResult result:(FlutterResult)result  {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *desc = nil;
        if ([showResult isKindOfClass:NSString.class]) {
            desc = (NSString *)showResult;
        } else {
            desc = [showResult description];
            // if (desc != nil) {
            //     desc = [NSString stringWithCString:[desc cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
            // }
        }
        NSLog( @"foxlog打印日志---->>%@", desc );
    });
}

@end
