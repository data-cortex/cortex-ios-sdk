//
//  DataCortexViewController.m
//  cortex-ios-sdk
//
//  Created by Yanko Bolanos on 10/04/2015.
//  Copyright (c) 2015 Yanko Bolanos. All rights reserved.
//

#import "DataCortexViewController.h"

#import <DataCortex/DataCortex.h>

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
            @"kingdom": @"kingdom",
            @"phylum": @"phylum",
            @"class": @"class",
            @"order": @"order",
            @"family": @"family",
            @"genus": @"genus",
            @"species": @"species",
            @"float1": @1,
            @"float2": @2,
            @"float3": @3,
            @"float4": @4,
        }];

    [[DataCortex sharedInstance] eventWithProperties:@{
            @"kingdom": @"build",
            @"phylum": @"chicken_coop",
            @"class": @"large",
            @"order": @"red"
        }];
}
- (IBAction)economyEventAction:(id)sender
{
    [[DataCortex sharedInstance] economyWithProperties:@{
            @"kingdom": @"building",
            @"phylum": @"barn",
            @"class": @"blue",
        }
        spendCurrency: @"USD"
        spendAmount: @10.0
        ];
}


@end
