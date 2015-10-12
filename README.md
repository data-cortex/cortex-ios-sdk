# cortex-ios-sdk
Data Cortex iOS SDK

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

```objective-c
#import <DataCortex/DataCortex.h>

#define DC_API_KEY @"YOUR_API_KEY"
#define DC_ORG @"your_org_name"

// Initialize the library with your DC_API_KEY
[DataCortex sharedInstanceWithAPIKey:YOUR_API_KEY forOrg:DC_ORG];

// To get your instance later
DataCortex *dc = [DataCortex sharedInstance];
```

# User tracking

If you have a user ID or other identifier you track users by, add this to
Data Cortex to aggregate the user's usage across multiple devices and platforms.

```objective-c
DataCortex *dc = [DataCortex sharedInstance];

// User identified by Numeric ID
[dc addUserTag:@1234];
// User identified by unique string
[dc addUserTag:@"xzy123"];
```

# Event Tracking

Event tracking is the bulk of the ways you'll use the Data Cortex SDK.  Please
refer to your tracking specification for the parameters to use in each event.

```objective-c
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

```objective-c

[dc economyWithProperties:@{
    @"kingdom": @"kingdom",
    @"phylum": @"phylum",
    @"class": @"class",
    @"order": @"order",
    @"family": @"family",
    @"genus": @"genus",
    @"species": @"species",
  },
  spendAmount: @9.99,
  spendCurrency: @"USD",
  spendType: @"coinPurchase",
}];

[dc economyWithProperties:@{
    @"kingdom": @"buildings",
    @"phylum": @"barn",
    @"class": @"red",
  },
  spendAmount: @10,
  spendCurrency: @"coins",
}];

```
