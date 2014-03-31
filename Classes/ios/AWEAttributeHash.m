//
//  AWEAttributeHash.m
//  Wackadoo
//
//  Created by Sascha Lange on 08.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import "AWEAttributeHash.h"
#import "AWEEntity.h"
#import "AWEEntitySetProxy.h"

@implementation AWEAttributeHash

-(id)initWithAttribute:(NSString*)attribute
{
  if ((self = [super init])) {
    self.attribute = attribute;
    self.attributeHash = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark - Start / Stop Observing an Instance

-(void)registerInstance:(AWEEntity *)entity
{
  /// registers itself as an obserer with the given entity
  [entity addObserver:self forKeyPath:self.attribute options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"value_change"];
}

-(void)unregisterInstance:(AWEEntity *)entity
{
  /// unregisters itsels as observer of the given entity
  [entity removeObserver:self forKeyPath:self.attribute];
  [self removeObject:entity forValue:[entity valueForKey:self.attribute]];
}

#pragma mark - Observing and Handling attribute value changes

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  // logic: 1. remove from the oldValues hash
  //        2. add to the newValues hash
  // but only, iff value did change
  
  BOOL doLog = [[object uid] intValue] == 84;
  
  id newValue = [change objectForKey:NSKeyValueChangeNewKey];
  id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
  
  if (oldValue && [oldValue isEqual:newValue]) {
    if (doLog) AWELog(@"same value for %@", object);
    return ; // do nothing, because the value didn't change
  }
  if (oldValue && oldValue != nil && oldValue != [NSNull null]) {
    if (doLog) AWELog(@"remove from oldvalue %d: %@", [oldValue intValue], object);
    [self removeObject:object forValue:oldValue];
  }
  if (newValue && newValue != nil && newValue != [NSNull null]) {
    if (doLog) AWELog(@"add to newvalue %d: %@", [newValue intValue], object);
    [self addObject:object forValue:newValue];
  }
}

-(void)addObject:(id)object forValue:(id)value {
  AWEEntitySetProxy* proxy = [self getEntitySetProxyWithValue:value];
  [proxy addEntitiesObject:object];
  BOOL doLog = [[object uid] intValue] == 84;
  if (doLog) AWELog(@"-> add to value %d: %@", [value intValue], object);
}

-(void)removeObject:(id)object forValue:(id)value {
  AWEEntitySetProxy* proxy = [self.attributeHash objectForKey:value];
  if (proxy) {
    [proxy removeEntitiesObject:object];
    BOOL doLog = [[object uid] intValue] == 84;
    if (doLog) AWELog(@"-> remove from value %d: %@", [value intValue], object);
    /** do not remove empty set any longer, because observers might have been registered
    if ([set countOfEntities] == 0) { // removes empty set on the fly
      [self.attributeHash removeObjectForKey:value];
    } */
  }
}

#pragma mark - Public Interface to access Instances

-(NSSet*)getAllWithValue:(id)value
{
  if (value == nil) {
    NSLog(@"ERROR: requested values from attribute hash for nil.");
    return nil;
  }
  AWEEntitySetProxy* proxy = [self getEntitySetProxyWithValue:value];
  return proxy.entities;
}

-(AWEEntitySetProxy*)getEntitySetProxyWithValue:(id)value
{
  AWEEntitySetProxy* proxy = nil;
  
  @synchronized(self.attributeHash) {
    proxy = [self.attributeHash objectForKey:value];
    if (!proxy) {
      proxy = [AWEEntitySetProxy entitySetProxyWithSet:[NSMutableSet set]];
      [self.attributeHash setObject:proxy forKey:value];
    }
  }
  
  return proxy ;
}

-(AWECollectionChangeNotificationManager *)createChangeNotificationManagerForEntitiesWithValue:(id)value attributePath:(NSString *)attributePath context:(NSString *)context delegate:(NSObject<AWEObservationManagerDelegateProtocol> *)delegate
{
  AWEEntitySetProxy* proxy = [self getEntitySetProxyWithValue:value];
  
  AWECollectionChangeNotificationManager* manager = [[AWECollectionChangeNotificationManager alloc] initWithTarget:proxy collectionPath:@"entities" attributePath:attributePath context:context delegate:delegate];
  
  AWELog(@"> The attribute hash %@ created a new change notification manager %@ for value %d context %@ <", self, manager, [value intValue], context);
  
  return manager;
}

@end
