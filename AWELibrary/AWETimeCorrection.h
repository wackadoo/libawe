//
//  AWETimeCorrection.h
//  Wackadoo
//
//  Created by Sascha Lange on 14.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWETimeCorrection : NSObject

@property double alpha;
@property NSTimeInterval lagEstimate;

-(id)initWithAlpha:(double)alpha;

+(AWETimeCorrection*)sharedTimeCorrection;

-(NSTimeInterval)estimatedLag;
-(NSDate*)estimatedServerTime;

-(NSDate*)serverToLocalDate:(NSDate*)server;
-(NSDate*)localToServerDate:(NSDate*)local;

-(void)registerMeasurementWithRemoteTime:(NSDate*)remote localTime:(NSDate*)local;
-(void)registerMeasurementWithRemoteTime:(NSDate*)remote localTime:(NSDate*)local requestEndTime:(NSDate*)requestEnd;

@end
