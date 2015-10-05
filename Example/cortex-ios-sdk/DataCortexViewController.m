//
//  DataCortexViewController.m
//  cortex-ios-sdk
//
//  Created by Yanko Bolanos on 10/04/2015.
//  Copyright (c) 2015 Yanko Bolanos. All rights reserved.
//

#import "DataCortexViewController.h"

#import "DataCortex.h"

@interface DataCortexViewController ()

@end

@implementation DataCortexViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    DataCortex *dc = [DataCortex sharedInstanceWithAPIKey:@"dYlBxjMTYkXadqhnOyHnjo7iGb5bW1y0"
                                                    forOrg:@"rs_example"];
    
    [dc setUserTag:@"ybolanos"];
    
    [dc eventWithProperties:@{
                              @"kingdom": @"abcdefghigklmnopqrstuvxzyabcdefghigklmnopqrstuvxzy",
                              @"phylum": @"phylum",
                              @"class": @"class",
                              @"order": @"order",
                              @"family": @"family",
                              @"genus": @"genus",
                              @"species": @"species"
                              }];
    
    [dc listEvents];
    [dc clearEvents];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
