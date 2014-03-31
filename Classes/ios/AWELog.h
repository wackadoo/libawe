//
//  AWELog.h
//  Wackadoo
//
//  Created by Sascha Lange on 05.04.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG

#define AWELog(...)         NSLog(__VA_ARGS__)

#define AWELogDebug(...)    NSLog(__VA_ARGS__)
#define AWELogInfo(...)     NSLog(__VA_ARGS__)
#define AWELogError(...)    NSLog(__VA_ARGS__)
#define AWELogCritical(...) TFLog(__VA_ARGS__)
#define AWELogRemote(...)   TFLog(__VA_ARGS__)

#else

#define AWELog(...)        

#define AWELogDebug(...)   
#define AWELogInfo(...)     
#define AWELogError(...)    
#define AWELogCritical(...) TFLog(__VA_ARGS__)
#define AWELogRemote(...)   TFLog(__VA_ARGS__)


#endif