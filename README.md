# cortex-ios-sdk
Data Cortex iOS SDK

# cortex-ios-sdk

[![CI Status](http://img.shields.io/travis/Yanko Bolanos/cortex-ios-sdk.svg?style=flat)](https://travis-ci.org/Yanko Bolanos/cortex-ios-sdk)
[![Version](https://img.shields.io/cocoapods/v/cortex-ios-sdk.svg?style=flat)](http://cocoapods.org/pods/cortex-ios-sdk)
[![License](https://img.shields.io/cocoapods/l/cortex-ios-sdk.svg?style=flat)](http://cocoapods.org/pods/cortex-ios-sdk)
[![Platform](https://img.shields.io/cocoapods/p/cortex-ios-sdk.svg?style=flat)](http://cocoapods.org/pods/cortex-ios-sdk)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

cortex-ios-sdk is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "DataCortex"
```

Make sure you include the following in your Info.plist

```plist
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
   <key>api.data-cortex.com</key>
   <dict>
    <key>NSTemporaryThirdPartyExceptionRequiresForwardSecrecy</key>
    <false/>
   </dict>
  </dict>
</dict>
```


# Initializing the library

Generally you initialize the library in your AppDelegate.m file.
[application:willFinishLaunchingWithOptions:](http://developer.apple.com/library/ios/documentation/UIKit/Reference/UIApplicationDelegate_Protocol/Reference/Reference.html#//apple_ref/occ/intfm/UIApplicationDelegate/application:willFinishLaunchingWithOptions:)

```
#import <DataCortex.h>

#define DC_API_KEY @"YOUR_API_KEY"

// Initialize the library with your DC_API_KEY
[DataCortex sharedInstanceWithAPIKey:YOUR_API_KEY];

// To get your instance later
DataCortex *dc = [DataCortex sharedInstance];
```

# User tracking

If you have a user ID or other identifier you track users by, add this to
Data Cortex to aggregate the user's usage across multiple devices and platforms.

```
DataCortex *dc = [DataCortex sharedInstance];

// User identified by Numeric ID
[dc addUserTag:@1234];
// User identified by unique string
[dc addUserTag:@"xzy123"];
```

# Event Tracking

Event tracking is the bulk of the ways you'll use the Data Cortex SDK.  Please
refer to your tracking specification for the parameters to use in each event.

## Using named selector arguments

```
DataCortex *dc = [DataCortex sharedInstance];

// With all taxonomy
[dc eventWithKingdom:@"kingdom"
  phylum:@"phylum"
  class:@"class"
  order:@"order"
  family:@"family"
  genus:@"genus",
  species:@"species"
];

// With partial taxonomy
[dc eventWithKingdom:@"signup" phylum:@"phylum" class:@"class"];

// With partial taxonomy and floats
[dc eventWithKingdom:@"kingdom"
  phylum:@"phylum"
  class:@"class"
  order:@"order"
  family:@"family"
  genus:@"genus"
  species:@"species"
  float1:1.5
  float2:2.0
  float3:3.0
  float4:4.0
];

// With partial taxonomy and NSNumbers as floats
[dc eventWithKingdom:@"signup" float1:@20000];
```

## Using a dictonary
You can also track events using a dictonary of properties.

```
DataCortex *dc = [DataCortex sharedInstance];

// With all taxonomy
[dc eventWithProperties:@{
  @"kingdom": @"kingdom",
  @"phylum": @"phylum",
  @"class": @"class",
  @"order": @"order",
  @"family": @"family",
  @"genus": @"genus",
  @"species": @"species",
}];

// With all taxonomy and floats
[dc eventWithProperties:@{
  @"kingdom": @"kingdom",
  @"phylum": @"phylum",
  @"class": @"class",
  @"order": @"order",
  @"family": @"family",
  @"genus": @"genus",
  @"species": @"species",
  @"float1": @123,
  @"float2": @1.5,
  @"float3": @100000,
  @"float4": @0.0,
}];

```

# Economy tracking
Economy tracking is very similar to event tracking but adds a few extra
required elements.  Specifically `spendAmount` and `spendCurrency`.  It also
adds an optional `spendType`.

```
DataCortex *dc = [DataCortex sharedInstance];

// With all taxonomy
[dc economyWithKingdom:@"kingdom"
  phylum:@"phylum"
  class:@"class"
  order:@"order"
  family:@"family"
  genus:@"genus",
  species:@"species"
  spendAmount:@5.0
  spendCurrency:@"coins"
  spendType:@"upgrade"
];

// With all taxonomy
[dc economyWithProperties:@{
  @"kingdom": @"kingdom",
  @"phylum": @"phylum",
  @"class": @"class",
  @"order": @"order",
  @"family": @"family",
  @"genus": @"genus",
  @"species": @"species",
  @"spendAmount": @9.99,
  @"spendCurrency": @"USD",
  @"spendType": @"coinPurchase",
}];

```






## License
