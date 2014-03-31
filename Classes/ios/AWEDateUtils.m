//
//  AWEDateUtils.m
//  Wackadoo
//
//  Created by Sascha Lange on 14.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import "AWEDateUtils.h"

@implementation AWEDateUtil

-(id)init
{
  if ((self = [super init])) {
    self.responseHeaderFormatter = [[NSDateFormatter alloc] init];
    self.responseHeaderFormatter.dateFormat = @"EEE, dd MMM yyy HH:mm:ss z";
    self.responseHeaderFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIC"];
    self.responseHeaderFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    self.buildingDurationFormatter = [[NSDateFormatter alloc] init];
    self.buildingDurationFormatter.dateFormat = @"HH:mm:ss";
    self.buildingDurationFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIC"];
    self.buildingDurationFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  }
  return self;
}

+(AWEDateUtil*)sharedDateUtil
{
  static AWEDateUtil* dateUtil = nil;
  if (!dateUtil) {
    dateUtil = [[AWEDateUtil alloc] init];
  }
  return dateUtil;
}

-(NSDate*)dateFromResponseHeader:(NSString *)date
{
  return [self.responseHeaderFormatter dateFromString:date];
}

-(NSString*)dateToHeader:(NSDate *)date
{
  return [self.responseHeaderFormatter stringFromDate:date];
}

-(NSString*)intervalToReadableString:(NSTimeInterval)interval
{
  if (interval < 0) {
    interval = 0;
  }
  
  int h = (int)interval / 3600;
  int m = ((int)interval / 60) % 60;
  int s = ((int)interval % 60);

  return [NSString stringWithFormat:@"%d:%02d:%02d", h, m, s];
}

-(NSString*)intervalToReadableStringfromDate:(NSDate*)fromDate ToDate:(NSDate*)toDate
{
  if ([fromDate compare:toDate] > 0) {
    toDate = fromDate;
  }
  
  NSDateComponents *conversionInfo = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:fromDate  toDate:toDate  options:0];
  
  return [NSString stringWithFormat:@"%d:%02d:%02d", [conversionInfo hour], [conversionInfo minute], [conversionInfo second]];
}

@end
