#import "PNSBuildModelUtils.h"
#define TX_SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define TX_SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define IS_HORIZONTAL (TX_SCREEN_WIDTH > TX_SCREEN_WIDTH)

#define TX_Alert_NAV_BAR_HEIGHT      55.0
#define TX_Alert_HORIZONTAL_NAV_BAR_HEIGHT      41.0

//竖屏弹窗
#define TX_Alert_Default_Left_Padding         42
#define TX_Alert_Default_Top_Padding          115

/**横屏弹窗*/
#define TX_Alert_Horizontal_Default_Left_Padding      80.0

@implementation PNSBuildModelUtils

+ (TXCustomModel *)buildFullScreenModel {
    TXCustomModel *model = [[TXCustomModel alloc] init];
    
    model.navColor = UIColor.whiteColor;
    model.navTitle = [[NSAttributedString alloc] initWithString:@"" attributes:@{NSForegroundColorAttributeName : UIColor.whiteColor,NSFontAttributeName : [UIFont systemFontOfSize:20.0]}];
    //model.navIsHidden = NO;
    model.navBackImage = [UIImage imageNamed:@"icon_close_gray"];
    //model.hideNavBackItem = NO;
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    // [rightBtn setTitle:@"更多" forState:UIControlStateNormal];
    model.navMoreView = rightBtn;

    model.privacyNavColor = UIColor.whiteColor;
    model.privacyNavBackImage = [UIImage imageNamed:@"icon_nav_back_gray"];
    model.privacyNavTitleFont = [UIFont systemFontOfSize:20.0];
    model.privacyNavTitleColor = UIColor.blackColor;
    
    model.logoImage = [UIImage imageNamed:@"icon_logo"];
    model.logoIsHidden = NO;
    model.logoWidth = 92;
    model.logoHeight = 92;

    model.sloganIsHidden = NO;
    model.sloganText = [[NSAttributedString alloc] initWithString:@"畅读海量正版绘本, 请先登录" attributes:@{NSForegroundColorAttributeName : [self colorWithHex:0xAAAAAA alpha: 1],NSFontAttributeName : [UIFont systemFontOfSize:12.0]}];

    model.numberColor = [self colorWithHex:0x282B31 alpha: 1];
    model.numberFont = [UIFont systemFontOfSize: 30.0];

    model.loginBtnText = [[NSAttributedString alloc] initWithString:@"本机号码一键登录" attributes:@{NSForegroundColorAttributeName : UIColor.whiteColor,NSFontAttributeName : [UIFont systemFontOfSize:16.0]}];
    model.loginBtnBgImgs = @[
      [UIImage imageNamed:@"icon_login_active"],
      [UIImage imageNamed:@"icon_login_unactive"],
      [UIImage imageNamed:@"icon_login_active"]
    ];
    model.loginBtnHeight = 48;
    model.loginBtnLRPadding = 40;
    
    model.autoHideLoginLoading = NO;


    model.privacyOne = @[@"《用户协议》",@"https://xxxxxxxxxx/fox/events/contract"];
    model.privacyTwo = @[@"《隐私协议》",@"https://xxxxxxxxxx/fox/events/privacy"];
    model.privacyColors = UIColor.blackColor;
    model.privacyAlignment = NSTextAlignmentCenter;
    model.privacyFont = [UIFont fontWithName:@"PingFangSC-Regular" size:10.0];
    model.privacyPreText = @"我已阅读同意";
    model.privacyOperatorPreText = @"《";
    model.privacyOperatorSufText = @"》";
    // 是否同意
    model.checkBoxIsChecked = YES;
    model.checkBoxIsHidden = NO;
    model.checkBoxWH = 18.0;
    model.checkBoxImages = @[
      [UIImage imageNamed:@"icon_uncheck"],
      [UIImage imageNamed:@"icon_checked"],
    ];

    // model.changeBtnTitle = [[NSAttributedString alloc] init];
    model.changeBtnTitle = [
       [NSAttributedString alloc] initWithString:@"其他号码登录"
       attributes:@{NSForegroundColorAttributeName: [self colorWithHex:0x676C75 alpha: 1], NSFontAttributeName : [UIFont systemFontOfSize:14.0]}
    ];
    model.changeBtnIsHidden = NO;

    model.prefersStatusBarHidden = NO;
    model.preferredStatusBarStyle = UIStatusBarStyleLightContent;
    //model.presentDirection = PNSPresentationDirectionBottom;
    
    //授权页默认控件布局调整
    //model.navBackButtonFrameBlock =
    //model.navTitleFrameBlock =
    model.navMoreViewFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
        CGFloat width = superViewSize.height;
        CGFloat height = width;
        return CGRectMake(superViewSize.width - 15 - width, 0, width, height);
    };
    model.loginBtnFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
        if ([self isHorizontal:screenSize]) {
            frame.origin.y = 20;
            return frame;
        }
        return frame;
    };
    model.sloganFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
        if ([self isHorizontal:screenSize]) {
            return CGRectZero; //横屏时模拟隐藏该控件
        } else {
            return CGRectMake(0, 140, superViewSize.width, frame.size.height);
        }
    };
    model.numberFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
        if ([self isHorizontal:screenSize]) {
            frame.origin.y = 140;
        }
        return frame;
    };
    model.loginBtnFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
        if ([self isHorizontal:screenSize]) {
            frame.origin.y = 185;
        }
        return frame;
    };
    model.changeBtnFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
        if ([self isHorizontal:screenSize]) {
            return CGRectZero; //横屏时模拟隐藏该控件
        } else {
            return CGRectMake(10, frame.origin.y, superViewSize.width - 20, 30);
        }
    };
    return model;
}

+ (UIColor *)colorWithHex:(NSInteger)hex alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:alpha];
}

/// 是否是横屏 YES:横屏 NO:竖屏
+ (BOOL)isHorizontal:(CGSize)size {
    return size.width > size.height;
}


@end
