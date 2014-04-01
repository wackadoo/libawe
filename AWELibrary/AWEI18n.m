//
//  AWEI18n.m
//  Wackadoo
//
//  Created by Sascha Lange on 15.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import "AWEI18n.h"
#import "AWELog.h"


@implementation AWEI18n

-(id)init
{
  if ((self = [super init])) {
    _languageMapping = @{  // we do not support everything....
      @"en" : @"en_US",
      @"de" : @"de_DE",
    };
    _defaultLocale   = @"en_US";
    _defaultLanguage = @"en";
    
    [self updateLocale];
  }
  return self;
}

+(AWEI18n*)sharedI18n
{
  static AWEI18n* theHelper = nil;
  if (!theHelper) {
    theHelper = [[AWEI18n alloc] init];
  }
  return theHelper;
}

+(NSLocale*)currentSystemLocale
{
  return [NSLocale autoupdatingCurrentLocale];
}


// Logic:
// 1. determine system locale
// 2. check, whether this language is supported in translations
//    a. iff supported     -> leave language code and region format unchanged
//    b. iff not supported -> switch to default locale (with language code and region format)
// 3. extract language part from the result and determine the translationIdentifier (may have different region format, iff, for example, we do not support de_CH.

-(void)updateLocale
{
  _systemLocale = [AWEI18n currentSystemLocale];

  // is this language supported? if not -> switch to default locale (yes, change region format! we want to have a consistent appearance...)
  NSDictionary* components = [NSLocale componentsFromLocaleIdentifier:_systemLocale.localeIdentifier];
  NSString* languageCode = [components objectForKey:NSLocaleLanguageCode];
  
  NSArray* prefered = [NSLocale preferredLanguages];
  if ([prefered count] > 0) {
    languageCode = [prefered objectAtIndex:0];
  }
  
  AWELog(@"DETERMING LOCLALE: language code %@, identifier %@", languageCode, _systemLocale.localeIdentifier);
  
  NSString* tId = [self.languageMapping objectForKey:languageCode];
  
  if (tId == nil) { // language not supported -> switch
    languageCode = self.defaultLanguage;
    tId = self.defaultLocale;
    _localeIdentifer = tId;
  }
  else {
    _localeIdentifer = _systemLocale.localeIdentifier;
  }
  _languageCode = languageCode;
  _translationIdentifier = tId;
}


-(NSString*)localizedStringFromHash:(NSDictionary *)translations
{
  return [translations objectForKey:self.translationIdentifier];
}

+(NSDateFormatter*)localizedLongDateTimeFormatter
{
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateStyle:NSDateFormatterLongStyle];
  [formatter setTimeStyle:NSDateFormatterShortStyle];
  [formatter setLocale:[NSLocale currentLocale]];
  return formatter;
}

+(NSDateFormatter*)localizedShortDateFormatter
{
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateStyle:NSDateFormatterShortStyle];
  [formatter setTimeStyle:NSDateFormatterNoStyle];
  [formatter setLocale:[NSLocale currentLocale]];
  
  return formatter;
}

+(NSDateFormatter*)localizedShortTimeFormatter
{
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateStyle:NSDateFormatterNoStyle];
  [formatter setTimeStyle:NSDateFormatterShortStyle];
  [formatter setLocale:[NSLocale currentLocale]];
  
  return formatter;
}


+(NSDateFormatter*)localizedShortDateTimeFormatter
{
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateStyle:NSDateFormatterShortStyle];
  [formatter setTimeStyle:NSDateFormatterShortStyle];
  [formatter setLocale:[NSLocale currentLocale]];
  
  return formatter;
}

+(NSString*)localizedPercentStringFromNumber:(NSNumber*)number
{
  NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
  [formatter setNumberStyle:NSNumberFormatterPercentStyle];
  [formatter setLocale:[NSLocale currentLocale]];
  return [formatter stringFromNumber:number];
}

+(NSString*)localizedDecimalStringFromNumber:(NSNumber*)number withPlaces:(int)places
{
  NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [formatter setMaximumFractionDigits:places];
  [formatter setLocale:[NSLocale currentLocale]];
  return [formatter stringFromNumber:number];
}

+(NSString*)localizedIntegerStringFromNumber:(NSNumber*)number
{
  NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [formatter setMaximumFractionDigits:0];
  [formatter setLocale:[NSLocale currentLocale]];
  return [formatter stringFromNumber:number];
}

+(NSString *)localizedIntegerStringFromInt:(int)number
{
  return [AWEI18n localizedIntegerStringFromNumber:[NSNumber numberWithInt:number]];
}

+(NSString*)localizedResourceProductionStringFromNumber:(NSNumber*)number
{
  int frac = 0;
  if (fabs([number doubleValue] < 1.0)) {
    frac = 2;
  }
  else if (fabs([number doubleValue] < 10.0)) {
    frac = 1;
  }
  NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [formatter setMaximumFractionDigits:frac];
  [formatter setLocale:[NSLocale currentLocale]];
  return [formatter stringFromNumber:number];
}

+(NSString*)verbalizedTimeSince:(NSDate*)date
{
  
  
  double difference = [[NSDate date] timeIntervalSinceDate:date];
  
  
  
  NSMutableArray *periodsSingular = [NSMutableArray arrayWithObjects:
                                     NSLocalizedStringFromTable(@"%li second ago", @"Messaging", nil),
                                     NSLocalizedStringFromTable(@"%li minute ago", @"Messaging", nil),
                                     NSLocalizedStringFromTable(@"%li hour ago", @"Messaging", nil),
                                     NSLocalizedStringFromTable(@"%li day ago", @"Messaging", nil),
                                     NSLocalizedStringFromTable(@"%li week ago", @"Messaging", nil),
                                     NSLocalizedStringFromTable(@"%li month ago", @"Messaging", nil),
                                     NSLocalizedStringFromTable(@"%li year ago", @"Messaging", nil),
                                     NSLocalizedStringFromTable(@"%li decade ago", @"Messaging", nil),
                                     nil];
  NSMutableArray *periodsPlural = [NSMutableArray arrayWithObjects:
                                   NSLocalizedStringFromTable(@"%li seconds ago", @"Messaging", nil),
                                   NSLocalizedStringFromTable(@"%li minutes ago", @"Messaging", nil),
                                   NSLocalizedStringFromTable(@"%li hours ago", @"Messaging", nil),
                                   NSLocalizedStringFromTable(@"%li days ago", @"Messaging", nil),
                                   NSLocalizedStringFromTable(@"%li weeks ago", @"Messaging", nil),
                                   NSLocalizedStringFromTable(@"%li months ago", @"Messaging", nil),
                                   NSLocalizedStringFromTable(@"%li years ago", @"Messaging", nil),
                                   NSLocalizedStringFromTable(@"%li decades ago", @"Messaging", nil),
                                   nil];
  
  NSArray *lengths = [NSArray arrayWithObjects:@60, @60, @24, @7, @4.35, @12, @10, nil];
  int j = 0;
  for(j=0; difference >= [[lengths objectAtIndex:j] doubleValue]; j++)
  {
    difference /= [[lengths objectAtIndex:j] doubleValue];
  }
  difference = roundl(difference);
  if(difference != 1)
  {
    //[periods insertObject:[[periods objectAtIndex:j] stringByAppendingString:@"s"] atIndex:j];
    return [NSString stringWithFormat:[periodsPlural objectAtIndex:j], (long)difference ];
  }
  else {
    return [NSString stringWithFormat:[periodsSingular objectAtIndex:j], (long)difference ];
  }
}


@end
