//
//  ARCMSConfig.h
//  Wackadoo
//
//  Created by Sascha Lange on 22.11.12.
//  Copyright (c) 2012 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define DEBUG_LEVEL_DEFAULT           9

#define DBEUG_LEVEL_SILENT            0
#define DEBUG_LEVEL_ERROR             2
#define DEBUG_LEVEL_WARNING           3
#define DEBUG_LEVEL_INFO              4
#define DEBUG_LEVEL_DEBUG             5
#define DEBUG_LEVEL_VERY_VERBOSE     10


/*
 *  System Versioning Preprocessor Macros
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


@interface ARCMSConfig : NSObject

@property BOOL sandboxMode; ///< indicates whether or not the app has been build for the app store (apple's live servers) or debug / ad hoc distribution (apple's sandbox servers). IS NOT identical to debug / release target.
@property (readonly) BOOL debugTarget; ///< indicates wheter or not the app has been build for the release (usually used during ad hoc / app store distribution) or debug (simulator / cable-wise installation) target.
@property BOOL onTestServer;

@property BOOL automaticallyJoinAllianceMode; ///< indicates whether or not the leader of an alliance can see and set the automatically joining of own alliance.

@property (nonatomic, strong) NSSet* serverSupportedLanguageCodes;
@property (nonatomic, strong) NSString* serverDefaultLanguageCode;


@property (nonatomic, strong) NSString*            identityProviderBaseURL;
@property (nonatomic, strong, readonly) NSString*  identityProviderLanguageFragment;
@property (nonatomic, strong, readonly) NSString*  identityProviderLanguageURL;

/*
@property (nonatomic, strong) NSString* chatServer;
@property (nonatomic, strong) NSArray*             gameServerBaseURLs;
@property (nonatomic, strong) NSString*            geoServerBaseURL;
@property (nonatomic, strong) NSString*            geoServerLanguageFragment;
@property (nonatomic, strong) NSString*            geoServerLanguageURL;
@property (nonatomic, strong, readonly) NSString*  gameServerLanguageFragment;
@property (nonatomic, strong, readonly) NSString*  gameServerLanguageURL;
*/

@property (nonatomic) BOOL geoModeEnabled;
@property (nonatomic) NSTimeInterval geoPositionMaxAge;

@property (nonatomic, strong) NSString* allianceInvitationBaseURL;

@property (nonatomic, strong) NSString* clientGrantType;
@property (nonatomic, strong) NSString* clientId;
@property (nonatomic, strong) NSString* clientPassword;
@property (nonatomic, strong) NSString* clientScope;

@property (nonatomic, strong) NSString* credentialsFilename;
@property (nonatomic, strong) NSString* appTokenFilename;

@property NSTimeInterval premiumExpirationWarningTimeSpan;

@property BOOL sound;  ///< should become "music"!
@property BOOL sfx;    ///< sound fx switched on or off?
@property BOOL betaTesting;

@property NSTimeInterval cameraPanAnimationTime;  ///< time for the panning animation
@property NSTimeInterval cameraZoomAnimationTime; ///< time for the zooming animation

#pragma mark - TestFlight SDK

@property (nonatomic, strong) NSString* testFlightTeamToken;
@property (nonatomic, strong) NSString* testFlightAppToken;

@property int debugLevel;
@property int timeDebugLevel;

@property NSTimeInterval voteNotificationMinPlaytime; ///< playtime in seconds, that triggers the first notification to please vote in the app store.


#pragma mark - Platinum Store

@property (nonatomic, strong) NSArray*  shopProductIdentifiers;
@property (nonatomic, strong) NSString* shopPreferredProductIdentifier;
@property (nonatomic, strong) NSString* shopSpecialOfferProductIdentifier;
@property (nonatomic, strong) NSString* shopMethod;

/*
@property (nonatomic, strong) NSString* shopHostname;
@property (nonatomic, strong, readonly) NSString* shopBaseURL;
@property (nonatomic, strong, readonly) NSString* shopCompleteURL;*/

@property (nonatomic, strong) UIColor* defaultTintColor;

@property int platinumAdditionalConstructionJobs;
@property int platinumAdditionalTrainingJobs;

@property int customIconSets;

@property BOOL rendererUpdateInBackground;

@property NSTimeInterval specialOfferDialogInterval;

#pragma mark - Geo Functions

@property (nonatomic, strong) NSString* mapTileFormatString;

#pragma mark - Colors

@property (nonatomic, strong) NSDictionary* advisorColors;
@property (nonatomic, strong) NSDictionary* jobColors;


+(ARCMSConfig*)sharedConfig;

//-(NSString*)randomGameServerBaseURL;

-(NSString*)serverSupportedLanguageCode;


@end
