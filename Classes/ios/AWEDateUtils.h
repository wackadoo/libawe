//
//  AWEDateUtils.h
//  Wackadoo
//
//  Created by Sascha Lange on 14.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWEDateUtil : NSObject

@property (nonatomic, strong) NSDateFormatter* responseHeaderFormatter;
@property (nonatomic, strong) NSDateFormatter* buildingDurationFormatter;

-(id)init;
+(AWEDateUtil*)sharedDateUtil;

-(NSDate*)dateFromResponseHeader:(NSString*)date;
-(NSString*)dateToHeader:(NSDate*)date;

-(NSString*)intervalToReadableString:(NSTimeInterval)interval;
-(NSString*)intervalToReadableStringfromDate:(NSDate*)fromDate ToDate:(NSDate*)toDate;

@end
