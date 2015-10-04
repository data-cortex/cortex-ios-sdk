//
//  DataCortex.m
//  cortex-ios-sdk
//
//  Created by Yanko Bolanos on 10/4/15.
//  Copyright (c) 2015 DataCortex. All rights reserved.
//

#import "DataCortex.h"

static int const DELAY_RETRY_INTERVAL = 30;
static int const HTTP_TIMEOUT = 60.0;
static NSString* const EVENTS_LIST = @"events_list";
static NSString* const API_BASE_URL = @"https://api.data-cortex.com";

@implementation DataCortex {
    NSLock *running_lock;
    NSLock *events_lock;
    NSString *api_key;
    NSString *org;
    NSString *base_url;
}


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

@end
