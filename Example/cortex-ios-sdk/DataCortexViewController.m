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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)setUserTagAction:(id)sender
{
    [[DataCortex sharedInstance] setUserTag:@"ybolanos"];
}

- (IBAction)firstEventAction:(id)sender
{
    [[DataCortex sharedInstance] eventWithProperties:@{
        @"kingdom": @"first event",
    }];
}
- (IBAction)secondEventAction:(id)sender
{
    [[DataCortex sharedInstance] eventWithProperties:@{
        @"kingdom": @"second event",
        @"phylum": @"has",
        @"class": @"a",
        @"order": @"long",
        @"family": @"taxonomy",
        @"genus": @"in",
        @"species": @"here"
    }];
}
- (IBAction)economyEventAction:(id)sender
{
    NSLog(@"here");
}


@end
