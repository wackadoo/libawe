//
//  AWEAttributeHash.h
//  Wackadoo
//
//  Created by Sascha Lange on 08.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AWEObservationManager.h"

@class AWEEntity;
@class AWEEntitySetProxy;

/**
 * Class that observes an attribute of an AWEEntity sub-class and
 * provides an access hash for all instances of that particular
 * type according to the value of the observed attributes. For example,
 * it can be used to get all instances of AWEConstructionJob that have the
 * same queueId. 
 *
 * Never construct an instance of AWEAttributeHash directly, but use
 * the method +createHashForAttribute: of AWEEntity (or more precisesly:
 * on the subclass of AWEEntity at hand) to create and register an
 * access hash for a particular attribute of the subject.
 *
 * The class makes use of key value coding and is automatically registered
 * for every single instance as the attribute's observe. This is done 
 * during AWEEntity's init method, whereas the observer is unregistered 
 * during the dealloc method.
 */
@interface AWEAttributeHash : NSObject

/** the observed attribute name in a key-value-coding complient form. */ 
@property (nonatomic, strong) NSString* attribute;
/** the hash that maps attribute values to sets of instances having this
 * particular attribute value. */
@property (nonatomic, strong) NSMutableDictionary* attributeHash;


/** inits an attribute hash for the given attribute. 
 * \warning called by AWEEntity +createHashForAttribute; NEVER call 
 * directly. */
-(id)initWithAttribute:(NSString*)attribute;

/** returns all living instances of the associated type, where
 * the instance's attribute value matches the given value. Returns
 * an empty set in case there's no instance with the given attribute
 * value. */
-(NSSet*)getAllWithValue:(id)value;

/** registers a new instance of the associated type with the
 * access hash. The hash will start observing the given entity. 
 * \warning never call directly */
-(void)registerInstance:(AWEEntity*)entity;

/** unregisters a "dying" instance of the associated type with the
 * access hash. The hash will stop observing the given entity.
 * \warning never call directly */
-(void)unregisterInstance:(AWEEntity*)entity;

/** returns a proxy around the set of all entities with the given
 * value. The proxy can be used to register observers at. */
-(AWEEntitySetProxy*)getEntitySetProxyWithValue:(id)value;

/** creates a new change notification manager that listens to changes
 * on the set of entities with the specified attribute value. The 
 * caller has to keep a strong reference as this method does NOT OWN
 * the created notification manager. */
-(AWECollectionChangeNotificationManager*)createChangeNotificationManagerForEntitiesWithValue:(id)value attributePath:(NSString*)attributePath context:(NSString*)context delegate:(NSObject<AWEObservationManagerDelegateProtocol>*)delegate;


@end
