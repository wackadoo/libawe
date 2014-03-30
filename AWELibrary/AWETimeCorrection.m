//
//  AWETimeCorrection.m
//  Wackadoo
//
//  Created by Sascha Lange on 14.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import "AWETimeCorrection.h"
//#import "ARCMSConfig.h"
#import "AWELog.h"



@implementation AWETimeCorrection

-(id)initWithAlpha:(double)alpha
{
  if ((self = [super init])) {
    self.alpha = alpha;
    self.lagEstimate = 0.0;
  }
  return self;
}

+(AWETimeCorrection*)sharedTimeCorrection
{
  static AWETimeCorrection* theTimeCorrection = nil;
  if (!theTimeCorrection) {
    theTimeCorrection = [[AWETimeCorrection alloc] initWithAlpha:0.92]; /// \todo to configuration file
  }
  return theTimeCorrection;
}

-(NSTimeInterval)estimatedLag
{
  return fabs(self.lagEstimate) > 1.0 ? self.lagEstimate : 0.0; // don't scare the user, don't correct too much ;-)
}

-(NSDate*)estimatedServerTime
{
  return [[NSDate date] dateByAddingTimeInterval:(-[self estimatedLag])];
}

-(NSDate*)localToServerDate:(NSDate *)local
{
  return [local dateByAddingTimeInterval:(-[self estimatedLag])];
}

-(NSDate*)serverToLocalDate:(NSDate *)server
{
  return [server dateByAddingTimeInterval:[self estimatedLag]];
}

-(void)registerMeasurementWithRemoteTime:(NSDate *)remote localTime:(NSDate *)local requestEndTime:(NSDate *)requestEnd
{
  // TODO: if duration was longer than 1s and we already have an estimate of the lag, just ignore this measurement as it will be to imprecise
  
  NSTimeInterval duration   = [requestEnd timeIntervalSinceDate:local];
  NSDate*        normalized = [local dateByAddingTimeInterval:duration/2.0];
  NSTimeInterval difference = [normalized timeIntervalSinceDate:remote];
  NSTimeInterval newLag     = self.lagEstimate == 0.0 ? difference : difference * (1.0-self.alpha) + self.lagEstimate * self.alpha; // jump, no estimate present (0.0 is highly unlikely after having the first estimate)
  
  /*
  ARCMSConfig* config = [ARCMSConfig sharedConfig];
  
  if (config.timeDebugLevel >= DEBUG_LEVEL_DEBUG) {
    AWELog(@"TIME_CORRECTION MEASUREMENT: %@, %@, %@", remote, local, requestEnd);
    AWELog(@"TIME_CORRECTION MEASUREMENT-GT: %lf, %lf, %lf", [remote timeIntervalSince1970], [local timeIntervalSince1970], [remote timeIntervalSince1970]);
    AWELog(@"TIME_CORRECTION NEW_LAG: %lf, duration: %lf, normalized: %@, difference: %lf, old: %lf", newLag, duration, normalized, difference, self.estimatedLag);
  }
  if (config.timeDebugLevel >= DEBUG_LEVEL_INFO) {
    AWELog(@"LAG: %@HOURS: %lf MINUTES: %d SECONDS: %d MS: %d",
          (newLag < 0.0 ? @"-" : @""),
          floor(fabs(newLag / (1000*60*60))),
          ((int)floor(fabs(newLag / (1000*60))))%60,
          ((int)floor(fabs(newLag / 1000)))%60,
          (int)((newLag - floor(newLag))*1000));
  }*/
  self.lagEstimate = newLag;
}

-(void)registerMeasurementWithRemoteTime:(NSDate *)remote localTime:(NSDate *)local
{
  [self registerMeasurementWithRemoteTime:remote localTime:local requestEndTime:local];
}

@end
