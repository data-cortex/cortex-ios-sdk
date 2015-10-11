//
//  DataCortex.m
//  cortex-ios-sdk
//
//  Created by Yanko Bolanos on 10/4/15.
//  Copyright (c) 2015 DataCortex. All rights reserved.
//

#import "DataCortex.h"
@import AdSupport;

static int const DELAY_RETRY_INTERVAL = 30;
static int const HTTP_TIMEOUT = 60.0;
static NSString * const API_BASE_URL = @"https://api.data-cortex.com";
static int const TAG_MAX_LENGTH = 62;
static int const CONFIG_VER_MAX_LENGTH = 16;
static int const SERVER_VER_MAX_LENGTH = 16;
static int const GROUP_TAG_MAX_LENGTH = 32;
static int const TAXONOMY_MAX_LENGTH = 32;
static int const BATCH_COUNT = 10;


static NSString * const EVENTS_LIST_KEY = @"data_cortex_events_list";
static NSString * const DEVICE_TAG_KEY = @"data_cortex_deviceTag";

@implementation DataCortex {
    NSLock *runningLock;
    NSLock *eventLock;
    NSString *apiKey;
    NSString *org;
    NSString *baseURL;
    NSString *deviceTag;
    NSString *appVersion;
    NSString *osVersion;
    NSString *deviceFamily;
    NSString *deviceType;
    NSString *language;
    NSString *country;
    NSMutableArray *eventList;
    NSDateFormatter *dateFormatter;
}

@synthesize userTag = _userTag;
@synthesize facebookTag = _facebookTag;
@synthesize twitterTag = _twitterTag;
@synthesize googleTag = _googleTag;
@synthesize gameCenterTag = _gameCenterTag;
@synthesize groupTag = _groupTag;
@synthesize serverVer = _serverVer;
@synthesize configVer = _configVer;

static DataCortex *g_sharedDataCortex = nil;

+ (DataCortex *)sharedInstanceWithAPIKey:(NSString *)apiKey forOrg:(NSString *)org
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedDataCortex = [[self alloc] initWithAPIKey:apiKey forOrg:org];
    });
    return g_sharedDataCortex;
}
+ (DataCortex *)sharedInstance
{
    return g_sharedDataCortex;
}


- (DataCortex *)initWithAPIKey:(NSString *)initApiKey forOrg:(NSString *)initOrg {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self->deviceTag = [defaults objectForKey:DEVICE_TAG_KEY];

        if (!self->deviceTag) {
            ASIdentifierManager *asiManager = [ASIdentifierManager sharedManager];
            self->deviceTag = [[[asiManager advertisingIdentifier] UUIDString] copy];
            [defaults setObject:self->deviceTag forKey:DEVICE_TAG_KEY];
            [defaults synchronize];
        }

        self->appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] copy];
        self->osVersion = [[[UIDevice currentDevice] systemVersion] copy];
        self->deviceFamily = [[UIDevice currentDevice].model copy];
        NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
        self->country = [[currentLocale objectForKey:NSLocaleCountryCode] copy];
        self->language = [[currentLocale objectForKey:NSLocaleLanguageCode] copy];

        struct utsname systemInfo;
        uname(&systemInfo);
        self->deviceType = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

        self->apiKey = [initApiKey copy];
        self->org = [[initOrg lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        self->baseURL = [NSString stringWithFormat:@"%@/%@",API_BASE_URL,self->org];

        self->dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [self->dateFormatter setLocale:enUSPOSIXLocale];
        [self->dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [self->dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

        self->eventLock = [[NSLock alloc] init];
        self->runningLock = [[NSLock alloc] init];

        [self initializeEventList];
        [self sendEvents];
    }

    return self;
}

- (void)dealloc {
    // never called.
}

- (void)initializeEventList {
    [self->eventLock lock];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self->eventList = [[defaults arrayForKey:EVENTS_LIST_KEY] mutableCopy];

    if (!self->eventList) {
        self->eventList = [[NSMutableArray alloc] init];
        [defaults setObject:self->eventList forKey:EVENTS_LIST_KEY];
        [defaults synchronize];
    }

    [self->eventLock unlock];
}


- (void)eventWithProperties:(NSDictionary *)properties forType:(NSString *)type {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];

    for (NSString *key in properties) {
        NSString *value = [properties objectForKey:key];
        if ([value length] > TAXONOMY_MAX_LENGTH) {
            [value substringToIndex:TAXONOMY_MAX_LENGTH-1];
        } else {
            value = [value copy];
        }
        [event setValue:value forKey:key];
    }

    [event setObject:[self getISO8601Date] forKey:@"event_datetime"];
    [event setObject:type forKey:@"type"];

    [self addEvent:event];
}
- (void)eventWithProperties:(NSDictionary *)properties {
    [self eventWithProperties:properties forType:@"event"];
}
- (void)economyWithProperties:(NSDictionary *)properties {
    [self eventWithProperties:properties forType:@"economy"];
}

- (NSString *)getISO8601Date {
    return [self->dateFormatter stringFromDate:[NSDate date]];
}

- (void)sendEvents {

    BOOL acquired = [self->runningLock tryLock];
    if (acquired) {

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        __block NSArray *sendList = [self getSendEvents];

        if ([sendList count] > 0) {
            [self postEvents:sendList completionHandler:^(NSInteger httpStatus) {
                if (httpStatus >= 200 && httpStatus <= 299) {
                    [self removeEvents:sendList];
                    [self->runningLock unlock];
                    [self sendEvents];
                } else {
                    [self->runningLock unlock];
                    [self performSelector:@selector(sendEvents) withObject:nil afterDelay:DELAY_RETRY_INTERVAL];
                }
            }];
        } else {
            [self->runningLock unlock];
        }
    }
}


- (void)addEvent:(NSObject *)event {
    [self->eventLock lock];

    [self->eventList addObject:event];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self->eventList forKey:EVENTS_LIST_KEY];
    [defaults synchronize];

    [self->eventLock unlock];

    [self sendEvents];
}
- (void)removeEvents:(NSArray *)processedEvents {

    [self->eventLock lock];

    for (NSObject *event in processedEvents) {
        [self->eventList removeObject:event];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self->eventList forKey:EVENTS_LIST_KEY];
    [defaults synchronize];

    [self->eventLock unlock];
}
- (NSArray *)getSendEvents {
    NSArray *ret = nil;

    [self->eventLock lock];
    if ([self->eventList count] > BATCH_COUNT)
    {
        ret = [self->eventList subarrayWithRange:NSMakeRange(0,BATCH_COUNT)];
    }
    else
    {
        ret = [self->eventList copy];
    }
    [self->eventLock unlock];
    return ret;
}

- (void)_listEvents {
    NSLog(@"Current Events queued up:");
    for (NSArray *event in self->eventList) {
        NSLog(@"%@", event);
    }
    NSLog(@"end");
}

- (NSDictionary *)generateDCRequestWithEvents:(NSArray *)events {
    NSMutableDictionary *request = [[NSMutableDictionary alloc] init];

    [request setObject:self->apiKey forKey:@"api_key"];
    [request setObject:self->appVersion forKey:@"app_ver"];
    [request setObject:self->deviceFamily forKey:@"device_family"];
    [request setObject:self->osVersion forKey:@"os_ver"];
    [request setObject:self->deviceTag forKey:@"device_tag"];
    [request setObject:self->deviceType forKey:@"device_type"];
    [request setObject:self->language forKey:@"language"];
    [request setObject:self->country forKey:@"country"];
    [request setObject:@"iPhone OS" forKey:@"os"];
    [request setObject:@"iTunes" forKey:@"marketplace"];

    if ([self userTag])
        [request setObject:[self userTag] forKey:@"user_tag"];
    if ([self facebookTag])
        [request setObject:[self facebookTag] forKey:@"facebook_tag"];
    if ([self twitterTag])
        [request setObject:[self twitterTag] forKey:@"twitter_tag"];
    if ([self googleTag])
        [request setObject:[self googleTag] forKey:@"google_tag"];
    if ([self gameCenterTag])
        [request setObject:[self gameCenterTag] forKey:@"game_center_tag"];
    if ([self groupTag])
        [request setObject:[self groupTag] forKey:@"group_tag"];
    if ([self serverVer])
        [request setObject:[self serverVer] forKey:@"server_ver"];
    if ([self configVer])
        [request setObject:[self configVer] forKey:@"config_ver"];

    [request setObject:events forKey:@"events"];

    return request;
}

- (void)postEvents:(NSArray *)events completionHandler:(void (^) (NSInteger))completionHandler {

    NSOperationQueue *parent_queue = [NSOperationQueue currentQueue];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];

    NSDictionary *dcRequest = [self generateDCRequestWithEvents:events];


    NSString *urlString = [NSString stringWithFormat:@"%@/1/track?current_time=%@",
                           self->baseURL, [self getISO8601Date]];

    NSURL *url = [NSURL URLWithString: urlString];

    NSMutableURLRequest *request = [NSMutableURLRequest
                                    requestWithURL:url
                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:HTTP_TIMEOUT];

    //TODO: check error
    NSError *error = nil;
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:dcRequest
                                                          options:0 error:&error];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:requestBody];

    [NSURLConnection
     sendAsynchronousRequest:request
     queue:queue
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {

         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
         NSInteger httpStatus = [httpResponse statusCode];

         if (error != nil)
         {
             if (error.code == NSURLErrorTimedOut)
             {
                 // re-add to queue & retry
                 NSLog(@"timed out");
             }
             NSLog(@"retry later");
         }
         else
         {
             if ([httpResponse statusCode] == 200)
             {
                 NSLog(@"Got OK");
                 NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             }
             else
             {
                 NSLog(@"got %ld", (long)[httpResponse statusCode]);
                 NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             }

         }

        [parent_queue addOperationWithBlock:^{
            completionHandler(httpStatus);
        }];

     }];


}

- (NSString *)userTag {
    return _userTag;
}
- (NSString *)facebookTag {
    return _facebookTag;
}
- (NSString *)twitterTag {
    return _twitterTag;
}
- (NSString *)googleTag {
    return _googleTag;
}
- (NSString *)gameCenterTag {
    return _gameCenterTag;
}
- (NSString *)groupTag {
    return _groupTag;
}
- (NSString *)serverVer {
    return _serverVer;
}
- (NSString *)configVer {
    return _configVer;
}

- (NSString *)_valueCopy:(NSString *)newValue maxLength:(int)maxLength {
    NSString *ret = nil;
    if ([newValue length] > maxLength) {
        ret = [newValue substringToIndex:maxLength-1];
    } else {
        ret = [newValue copy];
    }
    return ret;
}

- (NSString *)_tagCopy:(NSString *)newValue {
    return [self _valueCopy:newValue maxLength:TAG_MAX_LENGTH];
}

- (void)setUserTag:(NSString *)newValue {
    _userTag = [self _tagCopy:newValue];
}
- (void)setFacebookTag:(NSString *)newValue {
    _facebookTag = [self _tagCopy:newValue];
}
- (void)setTwitterTag:(NSString *)newValue {
    _twitterTag = [self _tagCopy:newValue];
}
- (void)setGoogleTag:(NSString *)newValue {
    _googleTag = [self _tagCopy:newValue];
}
- (void)setGameCenterTag:(NSString *)newValue {
    _gameCenterTag = [self _tagCopy:newValue];
}

- (void)setGroupTag:(NSString *)newValue {
    _groupTag = [self _valueCopy:newValue maxLength:GROUP_TAG_MAX_LENGTH];
}

- (void)setServerVer:(NSString * )newValue {
    _serverVer = [self _valueCopy:newValue maxLength:SERVER_VER_MAX_LENGTH];
}
- (void)setConfigVer:(NSString *)newValue {
    _configVer = [self _valueCopy:newValue maxLength:CONFIG_VER_MAX_LENGTH];
}

@end
