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
- (void)economyWithProperties:(NSDictionary *)properties;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class
    order:(NSString *)order
    family:(NSString *)family
    genus:(NSString *)genus
    species:(NSString *)species
    float1:(NSNumber *)float1
    float2:(NSNumber *)float2
    float3:(NSNumber *)float3
    float4:(NSNumber *)float4;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class
    order:(NSString *)order
    family:(NSString *)family
    genus:(NSString *)genus
    species:(NSString *)species
    float1:(NSNumber *)float1
    float2:(NSNumber *)float2
    float3:(NSNumber *)float3;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class
    order:(NSString *)order
    family:(NSString *)family
    genus:(NSString *)genus
    species:(NSString *)species
    float1:(NSNumber *)float1
    float2:(NSNumber *)float2;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class
    order:(NSString *)order
    family:(NSString *)family
    genus:(NSString *)genus
    species:(NSString *)species
    float1:(NSNumber *)float1;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class
    order:(NSString *)order
    family:(NSString *)family
    genus:(NSString *)genus
    species:(NSString *)species;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class
    order:(NSString *)order
    family:(NSString *)family
    genus:(NSString *)genus;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class
    order:(NSString *)order
    family:(NSString *)family;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class
    order:(NSString *)order;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum
    class:(NSString *)class;

- (void)eventWithKingdom:(NSString *)kingdom
    phylum:(NSString *)phylum;

- (void)eventWithKingdom:(NSString *)kingdom;


@end
