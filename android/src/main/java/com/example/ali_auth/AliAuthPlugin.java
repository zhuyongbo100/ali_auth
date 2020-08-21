package com.example.ali_auth;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import androidx.annotation.NonNull;

import android.app.Activity;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.os.Build;
import android.util.Log;
import android.widget.ImageView;
import android.view.View;


import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.mobile.auth.gatewayauth.AuthRegisterViewConfig;
import com.mobile.auth.gatewayauth.AuthRegisterXmlConfig;
import com.mobile.auth.gatewayauth.AuthUIConfig;
import com.mobile.auth.gatewayauth.AuthUIControlClickListener;
import com.mobile.auth.gatewayauth.CustomInterface;
import com.mobile.auth.gatewayauth.PhoneNumberAuthHelper;
import com.mobile.auth.gatewayauth.PreLoginResultListener;
import com.mobile.auth.gatewayauth.TokenResultListener;
import com.mobile.auth.gatewayauth.model.TokenRet;
import com.mobile.auth.gatewayauth.ui.AbstractPnsViewDelegate;

import static com.example.ali_auth.AppUtils.dp2px;

/**
 * AliAuthPlugin
 */
public class AliAuthPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

    private static final int SERVICE_TYPE_AUTH = 1;//号码认证
    private static final int SERVICE_TYPE_LOGIN = 2;//一键登录
    private final String TAG = "MainPortraitActivity";

    private MethodChannel channel;

    private static Activity activity;
    private static Context mContext;

    private PhoneNumberAuthHelper mAlicomAuthHelper;
    private TokenResultListener mTokenListener;
    private MethodChannel.Result loginResult;
    private static String token;


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "ali_auth");

        mContext = flutterPluginBinding.getApplicationContext();
        channel.setMethodCallHandler(this);
    }

    public static void registerWith(Registrar registrar) {
        mContext = registrar.context();
        activity = registrar.activity();
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "ali_auth");
        channel.setMethodCallHandler(new AliAuthPlugin());
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "init":
                init(call, result);
                break;
            case "preLogin":
                preLogin(call, result);
                break;
            case "login":
                login(call, result);
                break;
            case "checkVerifyEnable":
                checkVerifyEnable(call, result);
                break;
            default:
                throw new IllegalArgumentException("Unkown operation" + call.method);

        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    ///activity 生命周期
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
        activity = activityPluginBinding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding activityPluginBinding) {
    }

    @Override
    public void onDetachedFromActivity() {
    }


    private void init(final MethodCall call, final MethodChannel.Result methodResult) {
        String SK = call.argument("sk");

        mTokenListener = new TokenResultListener() {
            @Override
            public void onTokenSuccess(final String ret) {
                activity.runOnUiThread(new Runnable() {

                    @Override
                    public void run() {
                        Log.e("xxxxxx", "onTokenSuccess:" + ret);
                        TokenRet tokenRet = null;

                        try {
                            tokenRet = JSON.parseObject(ret, TokenRet.class);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }

                        JSONObject jsonObject = new JSONObject();

                        if (tokenRet != null && ("600024").equals(tokenRet.getCode())) {
                            jsonObject.put("returnCode", tokenRet.getCode());
                            jsonObject.put("returnMsg", "终端自检成功！");
                            jsonObject.put("returnData", "");
                        }

                        if (tokenRet != null && ("600001").equals(tokenRet.getCode())) {
                            jsonObject.put("returnCode", tokenRet.getCode());
                            jsonObject.put("returnMsg", "唤起授权页成功！");
                            jsonObject.put("returnData", "");
                        }

                        if (tokenRet != null && ("600000").equals(tokenRet.getCode())) {
                            token = tokenRet.getToken();
                            mAlicomAuthHelper.quitLoginPage();
                            jsonObject.put("returnCode", tokenRet.getCode());
                            jsonObject.put("returnMsg", "获取token成功！");
                            jsonObject.put("returnData", token);

                            if (loginResult != null) {
                                loginResult.success(jsonObject);
                            }
                        }
                    }
                });
            }

            @Override
            public void onTokenFailed(final String ret) {
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Log.e("xxxxxx", "onTokenFailed:" + ret);

                        TokenRet tokenRet = null;

                        try {
                            tokenRet = JSON.parseObject(ret, TokenRet.class);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }

                        // 处理飞行模式、获取token失败、手机欠费、运营商服务异常、IO异常、等特殊情况
                        if (tokenRet != null && !(("700000").equals(tokenRet.getCode()))) {
                            token = tokenRet.getToken();
                            JSONObject jsonObject = new JSONObject();
                            jsonObject.put("returnCode", "600002");
                            jsonObject.put("returnMsg", tokenRet.getMsg());
                            jsonObject.put("returnData", "");
                            if (loginResult != null) {
                                loginResult.success(jsonObject);
                            }
                        }
                    }
                });
            }
        };


        mAlicomAuthHelper = PhoneNumberAuthHelper.getInstance(mContext, mTokenListener);

        mAlicomAuthHelper.setAuthSDKInfo(SK);

        mAlicomAuthHelper.checkEnvAvailable(SERVICE_TYPE_LOGIN);

        preLogin(call, methodResult);
    }


    /**
     * 检查运营商是否合规，不支持境外卡一键登录
     */
    public boolean checkCarrierName() {

        boolean isTrue = false;

        String currentCarrierName;

        if (mAlicomAuthHelper != null) {
            currentCarrierName = mAlicomAuthHelper.getCurrentCarrierName();
            Log.d("currentCarrierName", "" + currentCarrierName);
            isTrue = currentCarrierName == "CMCC" || currentCarrierName == "CUCC" || currentCarrierName == "CTCC";
        }

        return isTrue;
    }

    /**
     * SDK 判断网络环境是否支持
     */
    public boolean checkVerifyEnable(MethodCall call, MethodChannel.Result result) {

        boolean checkEnvAvailable = false;

        if (mAlicomAuthHelper != null) {
            checkEnvAvailable = mAlicomAuthHelper.checkEnvAvailable() && checkCarrierName();
        }

        result.success(checkEnvAvailable);
        return checkEnvAvailable;
    }

    /**
     * SDK 一键登录预取号
     */
    public void preLogin(MethodCall call, final MethodChannel.Result result) {
        int timeOut = 5000;
        if (call.hasArgument("timeOut")) {
            int value = call.argument("timeOut");
            timeOut = value;
        }

        mAlicomAuthHelper.accelerateLoginPage(timeOut, new PreLoginResultListener() {
            @Override
            public void onTokenSuccess(final String vendor) {
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Log.d(TAG, vendor + "预取号成功！");
                        JSONObject jsonObject = new JSONObject();
                        jsonObject.put("returnCode", "600001");
                        jsonObject.put("returnMsg", "预取号成功！");
                        jsonObject.put("returnData", "");
                        result.success(jsonObject);
                    }
                });
            }

            @Override
            public void onTokenFailed(final String vendor, final String ret) {
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Log.d(TAG, vendor + "预取号失败:" + ret);
                        JSONObject jsonObject = new JSONObject();
                        jsonObject.put("returnCode", "600012");
                        jsonObject.put("returnMsg", "预取号失败");
                        jsonObject.put("returnData", "");
                        result.success(jsonObject);
                    }
                });
            }
        });
    }


    // 监听点击授权页UI
    public void listenUIClick(final MethodCall call, final MethodChannel.Result methodResult) {
        mAlicomAuthHelper.setUIClickListener(new AuthUIControlClickListener() {
            @Override
            public void onClick(String code, Context context, JSONObject jsonObj) {
                JSONObject jsonObject = new JSONObject();
                if (code == "700001") {
                    jsonObject.put("returnCode", code);
                    jsonObject.put("returnMsg", "用户切换其他登录方式");
                    jsonObject.put("returnData", "");
                    mAlicomAuthHelper.quitLoginPage();
                    methodResult.success(jsonObject);
                }
            }
        });
    }

    // 正常登录
    public void login(final MethodCall call, final MethodChannel.Result methodResult) {
        loginResult = methodResult;
        configLoginTokenPort(call, methodResult);
        listenUIClick(call, methodResult);
        mAlicomAuthHelper.getLoginToken(mContext, 5000);
    }


    // ⼀键登录授权⻚⾯
    private void configLoginTokenPort(final MethodCall call, final MethodChannel.Result methodResult) {
        int authPageOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT;
        if (Build.VERSION.SDK_INT == 26) {
            authPageOrientation = ActivityInfo.SCREEN_ORIENTATION_BEHIND;
        }
        mAlicomAuthHelper.setAuthUIConfig(
                new AuthUIConfig.Builder()
                        // 状态栏背景色
                        .setStatusBarColor(Color.WHITE)
                        .setLightColor(true)
                        .setStatusBarHidden(false)
                        // 导航栏设置
                        .setNavColor(Color.WHITE)
                        .setNavReturnImgPath("icon_close")
                        .setNavReturnImgWidth(28)
                        .setNavReturnImgHeight(28)
                        .setNavReturnScaleType(ImageView.ScaleType.FIT_CENTER)
                        .setWebNavReturnImgPath("icon_back")
                        .setWebNavColor(Color.WHITE)
                        .setWebNavTextColor(Color.parseColor("#444444"))
                        .setWebNavTextSize(20)
                        .setWebViewStatusBarColor(Color.WHITE)
                        // logo设置
                        .setLogoImgPath("icon_logo")
                        .setLogoWidth(92)
                        .setLogoHeight(92)
                        .setLogoScaleType(ImageView.ScaleType.FIT_CENTER)
                        // slogan 设置
                        .setSloganText("畅读海量正版绘本, 请先登录")
                        .setSloganTextColor(Color.parseColor("#AAAAAA"))
                        .setSloganTextSize(12)
                        // 号码设置
                        .setNumberColor(Color.parseColor("#282B31"))
                        .setNumberSize(24)
                        // 按钮设置
                        .setLogBtnText("本机号码一键登录")
                        .setLogBtnTextSize(16)
                        .setLogBtnBackgroundPath("icon_login_active")
                        .setLogBtnWidth(295)
                        .setLogBtnHeight(48)
                        .setVendorPrivacyPrefix("《")
                        .setVendorPrivacySuffix("》")
                        // 切换到其他登录方式
                        .setSwitchAccTextColor(Color.parseColor("#676C75"))
                        .setSwitchAccText("其他号码登录")
                        .setSwitchAccTextSize(14)
                        .setScreenOrientation(authPageOrientation)
                        // 动画效果
//                        .setAuthPageActIn("in_activity", "out_activity")
//                        .setAuthPageActOut("in_activity", "out_activity")
                        // 勾选框
                        .setCheckboxHidden(false)
                        .setCheckBoxWidth(18)
                        .setCheckBoxHeight(18)
                        .setCheckedImgPath("icon_checked")
                        .setUncheckedImgPath("icon_unchecked")
                        // 勾选框后方文字
                        .setPrivacyState(true)
                        .setAppPrivacyColor(Color.parseColor("#AAAAAA"), Color.parseColor("#69A2E9"))
                        .setAppPrivacyOne("《用户协议》", "https://xxxxxxxxxx/fox/events/contract")
                        .setAppPrivacyTwo("《隐私协议》", "https://xxxxxxxxxx/fox/events/privacy")
                        .setLogBtnToastHidden(false)
                        .create()
        );
    }
}
