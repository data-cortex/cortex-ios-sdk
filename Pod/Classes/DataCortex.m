//
//  DataCortex.m
//  cortex-ios-sdk
//
//  Created by Yanko Bolanos on 10/4/15.
//  Copyright (c) 2015 DataCortex. All rights reserved.
//

#import "DataCortex.h"
@import AdSupport;

static int const DELAY_RETRY_INTERVAL = 30.0;
static int const HTTP_TIMEOUT = 60.0;
static NSString * const API_BASE_URL = @"https://api.data-cortex.com";
static int const TAG_MAX_LENGTH = 62;
static int const CONFIG_VER_MAX_LENGTH = 16;
static int const SERVER_VER_MAX_LENGTH = 16;
static int const GROUP_TAG_MAX_LENGTH = 32;
static int const TAXONOMY_MAX_LENGTH = 32;
static int const BATCH_COUNT = 10;


static NSString * const EVENT_LIST_KEY = @"data_cortex_eventList";
static NSString * const DEVICE_TAG_KEY = @"data_cortex_deviceTag";
static NSString * const USER_TAG_PREFIX_KEY = @"data_cortex_userTag";
static NSString * const INSTALL_SENT_KEY = @"data_cortex_installSent";
static NSString * const LAST_DAU_SEND_KEY = @"data_cortex_lastDAUSend";

@implementation DataCortex {
    dispatch_queue_t sendQueue;

    BOOL isSendRunning;
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
    NSDictionary *userTags;
    NSDate *lastDAUSend;
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

- (void)errorWithFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
    [self error:s];
    va_end(args);
}
- (void)error:(NSString *)s {
    NSLog(@"DC Error: %@",s);
}


+ (DataCortex *)sharedInstanceWithAPIKey:(NSString *)apiKey forOrg:(NSString *)org {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedDataCortex = [[self alloc] initWithAPIKey:apiKey forOrg:org];
    });
    return g_sharedDataCortex;
}
+ (DataCortex *)sharedInstance {
    if (!g_sharedDataCortex) {
         NSLog(@"DC Error: Dont call sharedInstance before sharedInstanceWithAPIKey:forOrg:");
    }
    return g_sharedDataCortex;
}

- (NSString *)getSavedUserTagWithName:(NSString *)name {
    NSString *key = [NSString stringWithFormat:@"%@_%@",USER_TAG_PREFIX_KEY,name];
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (DataCortex *)initWithAPIKey:(NSString *)initApiKey forOrg:(NSString *)initOrg {
    if (self = [super init]) {
        self->sendQueue = dispatch_queue_create("com.data-cortex.sendQueue",NULL);
        self->isSendRunning = FALSE;

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        self->lastDAUSend = [defaults objectForKey:LAST_DAU_SEND_KEY];
        if (!self->lastDAUSend) {
            self->lastDAUSend = [NSDate distantPast];
        }
        self->_userTag = [self getSavedUserTagWithName:@"userTag"];
        self->_facebookTag = [self getSavedUserTagWithName:@"facebookTag"];
        self->_twitterTag = [self getSavedUserTagWithName:@"twitterTag"];
        self->_googleTag = [self getSavedUserTagWithName:@"googleTag"];
        self->_gameCenterTag = [self getSavedUserTagWithName:@"gameCenterTag"];

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

        [self initializeEventList];

        if (![defaults boolForKey:INSTALL_SENT_KEY]) {
            [self eventWithProperties:@{ @"kingdom": @"organic" } forType:@"install"];
            [defaults setBool:TRUE forKey:INSTALL_SENT_KEY];
            [defaults synchronize];
        }
        [self maybeAddDAU];

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
    self->eventList = [[defaults arrayForKey:EVENT_LIST_KEY] mutableCopy];

    if (!self->eventList) {
        self->eventList = [[NSMutableArray alloc] init];
        [defaults setObject:self->eventList forKey:EVENT_LIST_KEY];
        [defaults synchronize];
    }

    [self->eventLock unlock];
}

- (void)maybeAddDAU {
    if ([self->lastDAUSend timeIntervalSinceNow] < -24*60*60) {
        self->lastDAUSend = [NSDate date];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self->lastDAUSend forKey:LAST_DAU_SEND_KEY];

        [self eventWithProperties:@{} forType:@"dau"];
    }
}

- (NSString *)getISO8601Date {
    return [self->dateFormatter stringFromDate:[NSDate date]];
}

- (void)sendEvents {
    dispatch_async(self->sendQueue, ^{
      if (!self->isSendRunning) {
          self->isSendRunning = true;
          __block NSArray *sendList = [self getSendEvents];

          if ([sendList count] > 0) {
              [self postEvents:sendList completionHandler:^(NSInteger httpStatus) {
                  dispatch_async(self->sendQueue, ^{
                      BOOL sendDelayed = FALSE;
                      if (httpStatus >= 200 && httpStatus <= 299) {
                          [self removeEvents:sendList];
                      } else if (httpStatus == 400) {
                          [self removeEvents:sendList];
                      } else if (httpStatus == 403) {
                          [self error:@"Bad authentication, please check your API Key"];
                          [self removeEvents:sendList];
                      } else if (httpStatus == 409) {
                          [self error:@"Conflict, dup send?"];
                          [self removeEvents:sendList];
                      } else {
                          // Unknown error, lets just wait and try again.
                          sendDelayed = TRUE;
                      }

                      self->isSendRunning = FALSE;
                      if (sendDelayed) {
                          [self performSelector:@selector(sendEvents) withObject:nil afterDelay:DELAY_RETRY_INTERVAL];
                      } else {
                          [self sendEvents];
                      }
                  });
              }];
          } else {
              self->isSendRunning = FALSE;
          }
      }
    });
}

- (void)addEvent:(NSObject *)event {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [self->eventLock lock];
    [self->eventList addObject:event];
    [defaults setObject:[self->eventList copy] forKey:EVENT_LIST_KEY];
    [self->eventLock unlock];

    [defaults synchronize];
    [self sendEvents];
}
- (void)removeEvents:(NSArray *)processedEvents {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [self->eventLock lock];
    for (NSObject *event in processedEvents) {
        [self->eventList removeObject:event];
    }
    [defaults setObject:[self->eventList copy] forKey:EVENT_LIST_KEY];
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

    [NSURLConnection sendAsynchronousRequest:request
        queue:queue
        completionHandler:^(NSURLResponse *response,NSData *data,NSError *error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger httpStatus = [httpResponse statusCode];
            completionHandler(httpStatus);
        }];
}

- (NSString *)userTag {
    return self->_userTag;
}
- (NSString *)facebookTag {
    return self->_facebookTag;
}
- (NSString *)twitterTag {
    return self->_twitterTag;
}
- (NSString *)googleTag {
    return self->_googleTag;
}
- (NSString *)gameCenterTag {
    return self->_gameCenterTag;
}
- (NSString *)groupTag {
    return self->_groupTag;
}
- (NSString *)serverVer {
    return self->_serverVer;
}
- (NSString *)configVer {
    return self->_configVer;
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

- (NSString *)_tagSave:(NSString *)newValue forTagName:(NSString *)tagName {
    NSString *value = [self _valueCopy:newValue maxLength:TAG_MAX_LENGTH];
    NSString *key = [NSString stringWithFormat:@"%@_%@",USER_TAG_PREFIX_KEY,tagName];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    return value;
}

- (void)setUserTag:(NSString *)newValue {
    self->_userTag = [self _tagSave:newValue forTagName:@"userTag"];
}
- (void)setFacebookTag:(NSString *)newValue {
    self->_facebookTag = [self _tagSave:newValue forTagName:@"facebookTag"];
}
- (void)setTwitterTag:(NSString *)newValue {
    self->_twitterTag = [self _tagSave:newValue forTagName:@"twitterTag"];
}
- (void)setGoogleTag:(NSString *)newValue {
    self->_googleTag = [self _tagSave:newValue forTagName:@"googleTag"];
}
- (void)setGameCenterTag:(NSString *)newValue {
    self->_gameCenterTag = [self _tagSave:newValue forTagName:@"gameCenterTag"];
}

- (void)setGroupTag:(NSString *)newValue {
   self-> _groupTag = [self _valueCopy:newValue maxLength:GROUP_TAG_MAX_LENGTH];
}

- (void)setServerVer:(NSString * )newValue {
    self->_serverVer = [self _valueCopy:newValue maxLength:SERVER_VER_MAX_LENGTH];
}
- (void)setConfigVer:(NSString *)newValue {
    self->_configVer = [self _valueCopy:newValue maxLength:CONFIG_VER_MAX_LENGTH];
}

- (id)trimString:(NSString *)s maxLength:(int)maxLength {
    NSString *ret = nil;
    NSUInteger length = [s length];
    if (length > maxLength) {
        ret = [s substringToIndex:maxLength-1];
    } else {
        ret = [s copy];
    }
    return ret;
}

- (id)properties:(NSDictionary *)properties key:(NSString *)key maxLength:(int)maxLength {
    NSString *ret = nil;
    NSString *value = [[properties objectForKey:key] description];
    NSUInteger length = [value length];
    if (length > 0) {
        ret = [self trimString:value maxLength:maxLength];
    }
    return ret;
}

- (void)eventWithProperties:(NSDictionary *)properties forType:(NSString *)type
    spendCurrency:(NSString *)spendCurrency
    spendType:(NSString *)spendType
    spendAmount:(NSNumber *)spendAmount
    {
    BOOL isGood = true;

    const NSArray *TAXONOMY_PROPERTY_LIST = @[
        @"kingdom",
        @"phylum",
        @"class",
        @"order",
        @"family",
        @"genus",
        @"species",
    ];
    const NSArray *NUMBER_PROPERTY_LIST = @[
        @"float1",
        @"float2",
        @"float3",
        @"float4",
    ];

    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];

    [event setObject:[self getISO8601Date] forKey:@"event_datetime"];
    [event setObject:type forKey:@"type"];

    for (NSString *key in TAXONOMY_PROPERTY_LIST) {
        NSString *value = [self properties:properties key:key maxLength:TAXONOMY_MAX_LENGTH];
        if (value) {
            [event setValue:value forKey:key];
        }
    }

    for (NSString *key in NUMBER_PROPERTY_LIST) {
        id value = [properties objectForKey:key];
        if ([value isKindOfClass:[NSNumber class]]) {
            [event setValue:value forKey:key];
        } else if (value) {
            [self errorWithFormat:@"bad value (%@) for %@",value,key];
        }
    }

    if ([type isEqual:@"economy"]) {
        if( spendCurrency ) {
            spendCurrency = [self trimString:spendCurrency maxLength:TAXONOMY_MAX_LENGTH];
            [event setValue:spendCurrency forKey:@"spend_currency"];
        } else {
            [self error:@"spendCurrency is required"];
            isGood = false;
        }
        if ([spendAmount isKindOfClass:[NSNumber class]]) {
            [event setValue:spendAmount forKey:@"spend_amount"];
        } else if (spendAmount == nil) {
            [self error:@"missing required value spendAmount for economy event"];
            isGood = false;
        } else {
            [self errorWithFormat:@"bad value (%@) for spendAmount",spendAmount];
            isGood = false;
        }

        if( spendType ) {
            spendType = [self trimString:spendType maxLength:TAXONOMY_MAX_LENGTH];
            [event setValue:spendType forKey:@"spend_type"];
        }
    }


    if (isGood) {
        [self addEvent:event];
    } else if( [type isEqual:@"economy"] ) {
        [self errorWithFormat:@"failed to send event with type: %@ and properties: %@, spendCurrency: %@, spendAmount: %@",
            type,properties,spendCurrency,spendAmount];
    } else {
        [self errorWithFormat:@"failed to send event with type: %@ and properties: %@",type,properties];
    }

    if (![type isEqual:@"dau"]) {
        [self maybeAddDAU];
    }
}

- (void)eventWithProperties:(NSDictionary *)properties forType:(NSString *)type {
    [self eventWithProperties:properties
        forType:type
        spendCurrency:nil
        spendType:nil
        spendAmount:nil];
}


- (void)eventWithProperties:(NSDictionary *)properties {
    [self eventWithProperties:properties
        forType:@"event"
        spendCurrency:nil
        spendType:nil
        spendAmount:nil];
}
- (void)economyWithProperties:(NSDictionary *)properties
    spendCurrency:(NSString *)spendCurrency
    spendAmount:(NSNumber *)spendAmount {
    [self eventWithProperties:properties
        forType:@"economy"
        spendCurrency:spendCurrency
        spendType:nil
        spendAmount:spendAmount];
}

- (void)economyWithProperties:(NSDictionary *)properties
    spendCurrency:(NSString *)spendCurrency
    spendAmount:(NSNumber *)spendAmount
    spendType:(NSString *)spendType {

    [self eventWithProperties:properties
        forType:@"economy"
        spendCurrency:spendCurrency
        spendType:spendType
        spendAmount:spendAmount];
}

@end
