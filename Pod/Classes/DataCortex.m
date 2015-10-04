//
//  DataCortex.m
//  cortex-ios-sdk
//
//  Created by Yanko Bolanos on 10/4/15.
//  Copyright (c) 2015 DataCortex. All rights reserved.
//

#import "DataCortex.h"




@implementation DataCortex {
    NSLock *running_lock;
    NSLock *events_lock;
    NSString *api_key;
    NSString *org;
    NSString *base_url;
}

@synthesize userTag = _userTag;
@synthesize facebookTag = _facebookTag;
@synthesize twitterTag = _twitterTag;
@synthesize googleTag = _googleTag;
@synthesize gameCenterTag = _gameCenterTag;
@synthesize groupTag = _groupTag;
@synthesize serverVer = _serverVer;
@synthesize configVer = _configVer;

- (id)initWithAPIKey: (NSString*) apiKey ForOrg:(NSString*)Org {
    self = [super init];
    if (self)
    {
        events_lock = [[NSLock alloc] init];
        running_lock = [[NSLock alloc] init];
        api_key = [NSString stringWithString:apiKey];
        org = [NSString stringWithString:Org];
        base_url = [NSString stringWithFormat:@"%@/%@", API_BASE_URL, org];
        NSLog(@"base_url: %@", base_url);
        [self initializeEventList];
        [self pushEvents];
        
    }
    
    return self;
}

-(void) initializeEventList {
    
    [events_lock lock];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *events_list = [[defaults arrayForKey:EVENTS_LIST] mutableCopy];
    
    if (!events_list) {
        events_list = [[NSMutableArray alloc] init];
        [defaults setObject:events_list forKey:EVENTS_LIST];
        [defaults synchronize];
    }
    
    [events_lock unlock];
    
}

-(void) eventWithProperties:(NSDictionary *)properties {
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    
    for (NSString* key in properties) {
        NSString *value = [properties objectForKey:key];
        if ([value length] > 32) {
            [event setValue:[value substringWithRange:NSMakeRange(0, 32)] forKey: key];
        } else {
            [event setValue:value forKey:key];
        }
    }
    
    [event setObject:[self getISO8601Date] forKey:@"event_datetime"];
    [event setObject:@"install" forKey:@"type"];
    
    [self addEvent:event];
    
}

-(NSString*) getISO8601Date {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSDate *now = [[NSDate alloc] init];;
    NSString *iso8601String = [dateFormatter stringFromDate:now];
    return iso8601String;
}

-(void) pushEvents {
    
    BOOL acquired = [running_lock tryLock];
    if (acquired) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        __block NSArray *events_list = [defaults arrayForKey:EVENTS_LIST];
        
        if ([events_list count] > 0) {
            [self postEvents:events_list completionHandler:^(NSInteger httpStatus){
                if (httpStatus >= 200 && httpStatus <= 299) {
                    [self removeEvents: events_list];
                    [running_lock unlock];
                    [self pushEvents];
                } else {
                    [running_lock unlock];
                    [self performSelector:@selector(pushEvents) withObject:nil afterDelay:DELAY_RETRY_INTERVAL];
                }
            }];
        } else {
            [running_lock unlock];
        }
    }
}


-(void) addEvent:(NSObject *)event {
    
    [events_lock lock];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *events_list = [[defaults arrayForKey:EVENTS_LIST] mutableCopy];
    
    [events_list addObject:event];
    [defaults setObject:events_list forKey:EVENTS_LIST];
    [defaults synchronize];
    
    [events_lock unlock];
    
    [self pushEvents];
    
}


-(void) removeEvents:(NSArray*) processed_events {

    [events_lock lock];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *new_events_list = [[defaults arrayForKey:EVENTS_LIST] mutableCopy];
    
    for (NSObject *event in processed_events) {
        [new_events_list removeObject:event];
    }
    
    [defaults setObject:new_events_list forKey:EVENTS_LIST];
    [defaults synchronize];
    
    [events_lock unlock];
    
}
-(void) removeEvent:(NSObject*) event {
    
    [events_lock lock];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *events_list = [[defaults arrayForKey:EVENTS_LIST] mutableCopy];
    
    [events_list removeObject:event];
    [defaults setObject:events_list forKey:EVENTS_LIST];
    [defaults synchronize];
    
    [events_lock unlock];
    
}

-(void) clearEvents {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *events_list = [defaults arrayForKey:EVENTS_LIST];
    [self removeEvents:events_list];
    
}

-(void) listEvents {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSLog(@"Current Events queued up:");
    NSArray *events_list = [defaults arrayForKey:EVENTS_LIST];
    for (NSArray *event in events_list) {
        NSLog(@"%@", event);
    }
    NSLog(@"end");
    
}

-(NSDictionary*) generateDCRequestWithEvents:(NSArray*)events {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSMutableDictionary *request = [[NSMutableDictionary alloc] init];
    
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *deviceFamily = [UIDevice currentDevice].model;
    NSString *deviceType = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    
    [request setObject:api_key forKey:@"api_key"];
    [request setObject:appVersion forKey:@"app_ver"];
    [request setObject:deviceFamily forKey:@"device_family"];
    [request setObject:systemVersion forKey:@"os_ver"];
    [request setObject:uuid forKey:@"device_tag"];
    [request setObject:events forKey:@"events"];
    [request setObject:deviceType forKey:@"device_type"];
    [request setObject:@"iPhone OS" forKey:@"os"]; // need to figure this out
    
    
    if ([self userTag])
        [request setObject:[self userTag] forKey:@"user_tag"];
    if([self facebookTag])
        [request setObject:[self facebookTag] forKey:@"facebook_tag"];
    if([self twitterTag])
        [request setObject:[self twitterTag] forKey:@"twitter_tag"];
    if([self googleTag])
        [request setObject:[self googleTag] forKey:@"google_tag"];
    if([self gameCenterTag])
        [request setObject:[self gameCenterTag] forKey:@"game_center_tag"];
    if([self groupTag])
        [request setObject:[self groupTag] forKey:@"group_tag"];
    if([self serverVer])
        [request setObject:[self serverVer] forKey:@"server_ver"];
    if([self configVer])
        [request setObject:[self configVer] forKey:@"config_ver"];

    
    [request setObject:@"en" forKey:@"language"];

    
    return request;
}

-(void) postEvents:(NSArray*) events completionHandler:(void (^) (NSInteger httpStatus))completionHandler {

    NSOperationQueue *parent_queue = [NSOperationQueue currentQueue];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    NSDictionary *dcRequest = [self generateDCRequestWithEvents:events];
    NSURL *url = [NSURL URLWithString: @"http://localhost:3000"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest
                                    requestWithURL:url
                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:HTTP_TIMEOUT];
    
    NSError *error = nil;
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:dcRequest
                                                          options:0 error:&error];
    
    //TODO: check error
    NSLog(@"%@", [[NSString alloc] initWithData:requestBody encoding:NSUTF8StringEncoding]);
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: requestBody];
    
    
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:queue
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
         
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
         NSInteger httpStatus = [httpResponse statusCode];
         
         if (error != nil)
         {
             if(error.code == NSURLErrorTimedOut)
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

- (NSString*) userTag {
    return _userTag;
}
- (NSString*) facebookTag {
    return _facebookTag;
}
-(NSString*) twitterTag {
    return _twitterTag;
}
-(NSString*) googleTag {
    return _googleTag;
}
-(NSString*) gameCenterTag {
    return _gameCenterTag;
}
-(NSString*) groupTag {
    return _groupTag;
}
-(NSString*) serverVer {
    return _serverVer;
}
-(NSString*) configVer {
    return _configVer;
}

- (void)setUserTag:(NSString*)newValue {
    
    if ([newValue length] > TAG_MAX_LENGTH){
        _userTag = [NSString stringWithString:
                    [newValue substringWithRange:NSMakeRange(0, TAG_MAX_LENGTH)]];
    }
    else{
        _userTag = [NSString stringWithString:newValue];
    }
}

-(void) setFacebookTag:(NSString*) newValue {
    if([newValue length] > TAG_MAX_LENGTH){
        _facebookTag = [NSString stringWithString:
                        [newValue substringWithRange:NSMakeRange(0,TAG_MAX_LENGTH)]];
    }
    else {
        _facebookTag = [NSString stringWithString: newValue];
    }
}
-(void) setTwitterTag:(NSString*) newValue {
    if([newValue length] > TAG_MAX_LENGTH){
        _twitterTag = [NSString stringWithString:
                       [newValue substringWithRange:NSMakeRange(0,TAG_MAX_LENGTH)]];
    }
    else {
        _twitterTag = [NSString stringWithString: newValue];
    }
}
-(void) setGoogleTag:(NSString*) newValue {
    if([newValue length] > TAG_MAX_LENGTH){
        _googleTag = [NSString stringWithString:
                      [newValue substringWithRange:NSMakeRange(0,TAG_MAX_LENGTH)]];
    }
    else {
        _googleTag = [NSString stringWithString: newValue];
    }
}
-(void) setGameCenterTag:(NSString*) newValue {
    // whats the limit?
    _gameCenterTag = [NSString stringWithString: newValue];
    
}
-(void) setGroupTag:(NSString*) newValue {
    if([newValue length] > GROUP_TAG_MAX_LENGTH){
        _groupTag = [NSString stringWithString:
                     [newValue substringWithRange:NSMakeRange(0,GROUP_TAG_MAX_LENGTH)]];
    }
    else {
        _groupTag = [NSString stringWithString: newValue];
    }
}
-(void) setServerVer:(NSString*) newValue {
    if([newValue length] > SERVER_VER_MAX_LENGTH){
        _serverVer = [NSString stringWithString:
                      [newValue substringWithRange:NSMakeRange(0,SERVER_VER_MAX_LENGTH)]];
    }
    else {
        _serverVer = [NSString stringWithString: newValue];
    }
}
-(void) setConfigVer:(NSString*) newValue {
    if([newValue length] > CONFIG_VER_MAX_LENGTH){
        _configVer = [NSString stringWithString:
                      [newValue substringWithRange:NSMakeRange(0,CONFIG_VER_MAX_LENGTH)]];
    }
    else {
        _configVer = [NSString stringWithString: newValue];
    }
}

@end
