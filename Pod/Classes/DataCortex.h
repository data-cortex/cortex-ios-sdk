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

static int const DELAY_RETRY_INTERVAL = 30;
static int const HTTP_TIMEOUT = 60.0;
static NSString* const EVENTS_LIST = @"events_list";
static NSString* const API_BASE_URL = @"https://api.data-cortex.com";
static int const TAG_MAX_LENGTH = 62;
static int const CONFIG_VER_MAX_LENGTH = 16;
static int const SERVER_VER_MAX_LENGTH = 16;
static int const GROUP_TAG_MAX_LENGTH = 32;


@interface DataCortex : NSObject

@property NSString* userTag;
@property NSString* facebookTag;
@property NSString* twitterTag;
@property NSString* googleTag;
@property NSString* gameCenterTag;
@property NSString* groupTag;
@property NSString* serverVer;
@property NSString* configVer;

- (id)initWithAPIKey: (NSString*) apiKey ForOrg:(NSString*)Org;
-(void) eventWithProperties:(NSDictionary*) properties;
-(void) listEvents;
-(void) clearEvents;

@end
