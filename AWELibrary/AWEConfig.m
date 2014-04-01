//
//  ARCMSConfig.m
//  Wackadoo
//
//  Created by Sascha Lange on 22.11.12.
//  Copyright (c) 2012 Sascha Lange. All rights reserved.
//

#import "AWEConfig.h"
#import "AWEI18n.h"
#import <UIKit/UIKit.h>


#define USE_TEST_SERVER

@implementation ARCMSConfig

-(id)init
{
  if ((self = [super init])) { // set defaults
    
    self.sandboxMode    = NO;
    self.geoModeEnabled = NO; // publicly enabled?  -> insiders may see parts.
    self.automaticallyJoinAllianceMode = YES;
    
    self.serverSupportedLanguageCodes = [NSSet setWithArray:@[@"en", @"de"]];
    self.serverDefaultLanguageCode = @"en";
    
    self.identityProviderBaseURL = @"https://wack-a-doo.de/";

    //   self.gameServerBaseURLs = @[
#ifdef USE_TEST_SERVER
  //    @"https://test1.wack-a-doo.de/"
#else
   //   @"https://gs02.wack-a-doo.de/"
#endif
 //   ];

#ifdef USE_TEST_SERVER
 //   self.chatServer = @"jabber3.wack-a-doo.com";
#else
 //   self.chatServer = @"jabber4.wack-a-doo.com";
#endif

#ifdef USE_TEST_SERVER
    self.onTestServer = YES;
#else
    self.onTestServer = NO;
#endif
    
#ifdef USE_TEST_SERVER
//    self.geoServerBaseURL = @"https://test1.wack-a-doo.de/";
#else
//    self.geoServerBaseURL = @"https://gs02.wack-a-doo.de/";
#endif

#ifdef USE_TEST_SERVER
    self.allianceInvitationBaseURL = @"https://test1.wack-a-doo.de/alliance_invitation/";
#else
    self.allianceInvitationBaseURL = @"https://wack-a-doo.de/alliance_invitation/";
#endif
    
    self.credentialsFilename     = @"credentials.plist";
    self.appTokenFilename        = @"token.plist";
    
    self.clientGrantType = @"password";
    self.clientId        = @"WACKADOO-IOS";
    self.clientPassword  = @"5d";
#ifdef USE_TEST_SERVER
    self.clientScope     = @"payment 5dentity wackadoo-testround3";
#else
    self.clientScope     = @"payment 5dentity wackadoo-round3";    
#endif
    
    self.mapTileFormatString = @"%d/%d/%d.png";
    
    
    self.debugLevel     = DEBUG_LEVEL_DEFAULT;
    self.timeDebugLevel = DEBUG_LEVEL_INFO;
    
    self.geoPositionMaxAge = DBL_MAX; // 3900.0;

    self.voteNotificationMinPlaytime = 120.0*60.0; // vote after 120 minutes.
    
    self.sound = !self.sandboxMode;
    self.sfx   = !self.sandboxMode;
    self.betaTesting = self.sandboxMode;
    
    
    self.defaultTintColor = [UIColor orangeColor];
    
    self.testFlightTeamToken = @"6280f9bb4ea1174921080d15631d317a_MTgzNTMwMjAxMy0wMi0wNSAwNjo0OTowNS45MzIyMjg";

    self.testFlightAppToken = @"6f961eea-631b-451c-b887-7159d0a83cc6";
    
    self.advisorColors = [NSDictionary dictionaryWithObjectsAndKeys:
                          [UIColor colorWithRed:0.67 green:0.65 blue:0.80 alpha:1.0], @"chef",
                          [UIColor colorWithRed:0.90 green:0.63 blue:0.23 alpha:1.0], @"warrior",
                          [UIColor colorWithRed:0.76 green:0.82 blue:0.21 alpha:1.0], @"girl",
                          nil];
    
    
    self.cameraPanAnimationTime = 0.400; 
    self.cameraZoomAnimationTime = 0.400;
    
    
    // SHOP
    
    self.premiumExpirationWarningTimeSpan = 3600.0*36; // 36 hours
    
    self.shopProductIdentifiers = @[
                                   @{ @"id"    : @"com.5dlab.wackadoo.pc6" },
                                   @{ @"id"    : @"com.5dlab.wackadoo.pc5" },
                                   @{ @"id"    : @"com.5dlab.wackadoo.pc4" },
                                   @{ @"id"    : @"com.5dlab.wackadoo.pc3" },
                                   @{ @"id"    : @"com.5dlab.wackadoo.pc2" },
                                   @{ @"id"    : @"com.5dlab.wackadoo.pc1" },
                                   @{ @"id"    : @"com.5dlab.wackadoo.starter1",
                                      @"hidden": @true },
                                  ];
    
    self.shopPreferredProductIdentifier    = @"com.5dlab.wackadoo.pc4";
    self.shopSpecialOfferProductIdentifier = @"com.5dlab.wackadoo.starter1";
    
#ifdef USE_TEST_SERVER
    //self.shopHostname = @"test1";
#else 
    //self.shopHostname = @"gs02";
#endif
    self.shopMethod   = @"istore";
    
    self.platinumAdditionalConstructionJobs = 3;
    self.platinumAdditionalTrainingJobs = 3;
    
    self.customIconSets = 3;
    
    self.rendererUpdateInBackground = YES;
    
    self.specialOfferDialogInterval = 16 * 60 * 60; // wait at least 16 hours since last display of special offer
    
    self.jobColors = [NSDictionary dictionaryWithObjectsAndKeys:
                      [UIColor colorWithRed:209.0/255.0 green:228.0/255.0 blue:152.0/255.0 alpha:1.0f], @"lightGreen",
                      [UIColor colorWithRed:239.0/255.0 green:193.0/255.0 blue:171.0/255.0 alpha:1.0f], @"lightRed",
                      [UIColor colorWithRed:201.0/255.0 green:203.0/255.0 blue:222.0/255.0 alpha:1.0f], @"lightBlue",
                      [UIColor colorWithRed:175.0/255.0 green:208.0/255.0 blue:47.0/255.0 alpha:1.0f], @"green",
                      [UIColor colorWithRed:255.0/255.0 green:61.0/255.0 blue:8.0/255.0 alpha:1.0f], @"red",
                      nil];
  }
  
  
  
  return self;
}


+(ARCMSConfig*)sharedConfig
{
  static ARCMSConfig* theConfig = nil;
  if (theConfig == nil) {
    theConfig = [[ARCMSConfig alloc] init];
  }
  return theConfig;
}


-(NSString *)shopBaseURL
{
  if (self.sandboxMode) {
    return @"http://217.86.148.136:81/";
  }
  else {
    return @"https://secure.bytro.com/";
  }
}

-(NSString *)shopCompleteURL
{
  if (self.sandboxMode) {
    return @"http://217.86.148.136:81/cl-5distore/index.php?eID=api&key=wackadooShop&action=processPayment";
  }
  else {
    return @"https://secure.bytro.com/index.php?eID=api&key=wackadooShop&action=processPayment";
  }
}

-(NSString*)serverSupportedLanguageCode
{
  NSString* code = [[AWEI18n sharedI18n] languageCode];
  if ([self.serverSupportedLanguageCodes containsObject:code]) {
    return code;
  }
  else {
    return self.serverDefaultLanguageCode;
  }
}




-(NSString *)identityProviderLanguageFragment
{
  return [NSString stringWithFormat:@"/identity_provider/%@", [self serverSupportedLanguageCode]];
}

-(NSString*)identityProviderLanguageURL
{
  return [[self identityProviderBaseURL] stringByAppendingPathComponent:[self identityProviderLanguageFragment]];
}

/*
-(NSString *)gameServerLanguageFragment
{
  return [NSString stringWithFormat:@"/game_server/%@", [self serverSupportedLanguageCode]];
}

-(NSString*)gameServerLanguageURL
{
  return [[self randomGameServerBaseURL] stringByAppendingPathComponent:[self gameServerLanguageFragment]];
}

-(NSString*)randomGameServerBaseURL
{
  return [self.gameServerBaseURLs objectAtIndex:arc4random() % [self.gameServerBaseURLs count]];
}


-(NSString *)geoServerLanguageFragment
{
  return [NSString stringWithFormat:@"/geo_server/%@", [self serverSupportedLanguageCode]];
}

-(NSString*)geoServerLanguageURL
{
  return [[self geoServerBaseURL] stringByAppendingPathComponent:[self geoServerLanguageURL]];
}*/


-(BOOL)debugTarget
{
#ifdef DEBUG
  return YES;
#else
  return NO;
#endif
}

@end
