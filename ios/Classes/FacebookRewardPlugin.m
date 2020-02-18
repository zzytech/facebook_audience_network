//
//  FacebookRewardPlugin.m
//  admob_flutter
//
//  Created by Suteki on 2020/2/17.
//

#import "FacebookRewardPlugin.h"
#import "FBAudienceNetwork.h"
//#import <FBAudienceNetwork/FBAudienceNetwork.h>

@interface FacebookRewardPluginDelegate : NSObject<FBRewardedVideoAdDelegate> {
    FlutterMethodChannel* _channel;
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel;

@end


@implementation FacebookRewardPluginDelegate

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _channel = channel;
    }
    return self;
}

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    NSDictionary *dictionary = @{
           @"placement_id" : rewardedVideoAd.placementID,
           @"invalidated" : @(rewardedVideoAd.isAdValid),
           @"error_code" : @(error.code),
           @"error_message" : error.localizedDescription,
       };
    [_channel invokeMethod:@"error" arguments:dictionary];
}


- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
    NSDictionary *dictionary = @{
         @"placement_id" : rewardedVideoAd.placementID,
         @"invalidated" : @(rewardedVideoAd.isAdValid),
     };
    [_channel invokeMethod:@"loaded" arguments:dictionary];
}

//- (void)rewardedVideoAdServerRewardDidFail:(FBRewardedVideoAd *)rewardedVideoAd {
//    NSDictionary *dictionary = @{
//           @"placement_id" : rewardedVideoAd.placementID,
//           @"invalidated" : @(rewardedVideoAd.isAdValid),
//           @"error_code" : @(999),
//           @"error_message" : @"server reward did fail",
//       };
//    [_channel invokeMethod:@"error" arguments:dictionary];
//}
//- (void)rewardedVideoAdServerRewardDidSucceed:(FBRewardedVideoAd *)rewardedVideoAd {
//    [_channel invokeMethod:@"rewarded_complete" arguments:@1];
//}

- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
    NSDictionary *dictionary = @{
         @"placement_id" : rewardedVideoAd.placementID,
         @"invalidated" : @(rewardedVideoAd.isAdValid),
     };
    [_channel invokeMethod:@"clicked" arguments:dictionary];
}

- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
    [_channel invokeMethod:@"rewarded_closed" arguments:@1];
}

- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
    [_channel invokeMethod:@"rewarded_complete" arguments:@1];
}

- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
    NSDictionary *dictionary = @{
         @"placement_id" : rewardedVideoAd.placementID,
         @"invalidated" : @(rewardedVideoAd.isAdValid),
     };
    [_channel invokeMethod:@"logging_impression" arguments:dictionary];
}

@end


@implementation FacebookRewardPlugin {
    NSObject<FlutterPluginRegistrar>* _registrar;
    FlutterMethodChannel* _channel;
    FacebookRewardPluginDelegate *_delegate;
    FBRewardedVideoAd *_rewardVideo;
}

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel =
        [FlutterMethodChannel methodChannelWithName:@"fb.audience.network.io/rewardedAd"
                                    binaryMessenger:[registrar messenger]];
    FacebookRewardPlugin *instance = [[FacebookRewardPlugin alloc] initWithRegistrar:registrar channel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar
                          channel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _registrar = registrar;
        _channel = channel;
        _delegate = [[FacebookRewardPluginDelegate alloc] initWithChannel:channel];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"showRewardedAd" isEqualToString:call.method]) {
        if (_rewardVideo == nil || !_rewardVideo.isAdValid) {
             result([FlutterError errorWithCode:@"1" message:@"ad is not valid" details:nil]);
             return;
         }
         UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
         [_rewardVideo showAdFromRootViewController:vc animated:YES];
         result(nil);
    } else if ([@"loadRewardedAd" isEqualToString:call.method]) {
//        NSString *idStr = @"YOUR_PLACEMENT_ID";
        NSString* idStr = call.arguments[@"id"];
         if (idStr == (id)[NSNull null]) {
             idStr = @"";
         }
        NSString *userId = call.arguments[@"userId"];
        if (userId == (id)[NSNull null]) {
            userId = @"";
        }
        NSString *currency = call.arguments[@"currency"];
        if (currency == (id)[NSNull null]) {
            currency = @"";
        }
        if (_rewardVideo == nil) {
            _rewardVideo = [[FBRewardedVideoAd alloc] initWithPlacementID:idStr
                                                               withUserID:userId
                                                             withCurrency:currency];
            _rewardVideo.delegate = _delegate;
        }
        if (!_rewardVideo.isAdValid) {
            [_rewardVideo loadAd];
        }
        result(nil);
    } else if ([@"destroyRewardedAd" isEqualToString:call.method]) {
        result(nil);
    }  else {
        result(FlutterMethodNotImplemented);
    }
}

@end
