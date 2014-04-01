//
//  AWEObservationManager.h
//  Wackadoo
//
//  Created by Sascha Lange on 28.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AWEEntity;


@protocol AWEObservationManagerDelegateProtocol <NSObject>

@optional

-(void)collectionChanged:(id)collection context:(NSString*)context;
-(void)newMembers:(NSArray*)entities inCollection:(id)collection context:(NSString*)context;
-(void)removedMembers:(NSArray*)entities fromCollection:(id)collection context:(NSString*)context;
-(void)entityDidChange:(AWEEntity*)entity context:(NSString*)context;

@end


/** Class for observing exactly one attribute (or keyPath) of one collection
 * of objects. Sends change notifications to its delegate when entities
 * are added to or removed from the set or when the observed attribute
 * of at least one of the entities in the collection did change. Thus,
 * replaces the functionality @each offers in Ember.JS and a-like. */
@interface AWECollectionChangeNotificationManager : NSObject

@property (nonatomic, weak) NSObject<AWEObservationManagerDelegateProtocol>* delegate;
@property (nonatomic, readonly, getter = isObserving) BOOL observing;

-(id)initWithTarget:(NSObject*)target collectionPath:(NSString*)collectionPath attributePath:(NSString*)keyPath context:(NSString*)context delegate:(NSObject<AWEObservationManagerDelegateProtocol>*)delegate;

/** stops the changenotification process for all registered sets and entities */
-(void)stopNotifications;
/** restarts the change notification process for all registered sets and entities */
-(void)startNotifications;

@end
