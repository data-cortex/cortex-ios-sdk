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

@property NSString* user_tag;

- (id)initWithAPIKey: (NSString*) apiKey ForOrg:(NSString*)Org;
-(void) eventWithProperties:(NSDictionary*) properties;
-(void) listEvents;

@end
