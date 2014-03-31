//
//  AWEI18n.h
//  Wackadoo
//
//  Created by Sascha Lange on 15.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>

/** This is a quick and naive implementation that needs to be improved in order
 * to better handle same language, different format and to give the present
 * locale in a cheaper way (buffer the results, track changes on the currentLocale).
 */
@interface AWEI18n : NSObject

@property (readonly, strong) NSDictionary* languageMapping;
@property (readonly, strong) NSString* defaultLocale;
@property (readonly, strong) NSString* defaultLanguage;

@property (readonly, strong) NSLocale* systemLocale;

@property (readonly, strong) NSString* localeIdentifer;         ///< complete identifer
@property (readonly, strong) NSString* languageCode;            ///< language code
@property (readonly, strong) NSString* translationIdentifier;   ///< identifer, to access the rules translation

+(AWEI18n*)sharedI18n;
+(NSLocale*)currentSystemLocale;

-(void)updateLocale;

-(NSString*)localizedStringFromHash:(NSDictionary*)translations;

+(NSDateFormatter*)localizedShortDateFormatter;
+(NSDateFormatter*)localizedShortTimeFormatter;
+(NSDateFormatter*)localizedShortDateTimeFormatter;
+(NSDateFormatter*)localizedLongDateTimeFormatter;


+(NSString*)localizedPercentStringFromNumber:(NSNumber*)number;
+(NSString*)localizedDecimalStringFromNumber:(NSNumber*)number withPlaces:(int)places;
+(NSString*)localizedIntegerStringFromNumber:(NSNumber*)number;
+(NSString*)localizedIntegerStringFromInt:(int)number;
+(NSString*)localizedResourceProductionStringFromNumber:(NSNumber*)number;

+(NSString*)verbalizedTimeSince:(NSDate*)date;

@end
