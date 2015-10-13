//
//  DataCortex.h
//  cortex-ios-sdk
//
//  Created by Yanko Bolanos on 10/4/15.
//  Copyright (c) 2015 DataCortex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@interface DataCortex : NSObject

@property NSString *userTag;
@property NSString *facebookTag;
@property NSString *twitterTag;
@property NSString *googleTag;
@property NSString *gameCenterTag;
@property NSString *groupTag;
@property NSString *serverVer;
@property NSString *configVer;

+ (DataCortex *)sharedInstance;
+ (DataCortex *)sharedInstanceWithAPIKey:(NSString *)apiKey forOrg:(NSString *)org;

- (void)eventWithProperties:(NSDictionary *)properties;

- (void)economyWithProperties:(NSDictionary *)properties
    spendCurrency:(NSString *)spendCurrency
    spendAmount:(NSNumber *)spendAmount;

- (void)economyWithProperties:(NSDictionary *)properties
    spendCurrency:(NSString *)spendCurrency
    spendAmount:(NSNumber *)spendAmount
    spendType:(NSString *)spendType;

@end
