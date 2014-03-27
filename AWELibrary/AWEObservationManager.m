//
//  AWEObservationManager.m
//  Wackadoo
//
//  Created by Sascha Lange on 28.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import "AWEObservationManager.h"

#import "AWEEntity.h"

@interface CollectionObservation : NSObject

@property (nonatomic, strong) NSObject* target;
@property (nonatomic, strong) NSString* keyPath;
@property (nonatomic, strong) NSString* context;

@end

@implementation CollectionObservation
@end

@interface EntityObservation : NSObject

@property (nonatomic, strong) AWEEntity* entity;
@property (nonatomic, strong) NSString* context;

@end

@implementation EntityObservation
@end



@interface AWECollectionChangeNotificationManager ()

@property (nonatomic, readwrite, getter = isObserving) BOOL observing;

@property (nonatomic, strong) NSMutableSet* registeredEntities;
@property (nonatomic, strong) NSObject* target;
@property (nonatomic, strong) NSObject* observedCollection;
@property (nonatomic, strong) NSString* collectionPath;
@property (nonatomic, strong) NSString* attributePath;
@property (nonatomic, strong) NSString* context;


-(void)unregisterAllObservers;
-(void)registerAllObservers;

-(void)registerObserverForEntity:(AWEEntity*)entity context:(NSString*)context;
-(void)registerObserverForEntities:(NSArray*)entities context:(id)context;

@end



@implementation AWECollectionChangeNotificationManager

-(id)initWithTarget:(NSObject*)target collectionPath:(NSString *)collectionPath attributePath:(NSString *)attributePath context:(NSString *)context delegate:(NSObject<AWEObservationManagerDelegateProtocol> *)delegate
{
  if ((self = [super init])) {
    AWELog(@"CREATE CHANGE NOTIFICATION MANAGER FOR %@ WITH DELEGATE %@", collectionPath, delegate);
    self.observedCollection = nil;
    self.target         = target;
    self.collectionPath = collectionPath;
    self.attributePath  = attributePath;
    self.context        = context;
    self.delegate       = delegate;
    self.observing      = YES;
    self.registeredEntities = [NSMutableSet new];
    [self registerAllObservers];
  }
  return self;
}

-(void)dealloc
{
  AWELog(@"DESTROY CHANGE NOTIFICATION MANAGER FOR %@", self.collectionPath);
  if (self.isObserving) {
    [self stopNotifications];
  }
  self.registeredEntities = nil;
  self.target = nil;
}

#pragma mark - Start / Stop


-(void)stopNotifications
{
  @synchronized(self) {
    if (self.isObserving) {
      self.observing = NO;
      [self unregisterAllObservers];
    }
  }
}

-(void)startNotifications
{
  @synchronized(self) {
    if (!self.isObserving) {
      self.observing = YES;
      [self registerAllObservers];
    }
  }
}

#pragma mark - Register Observers

-(void)registerObserverForEntity:(AWEEntity*)entity context:(NSString*)context
{
  AWELog(@"--> REGISTER OBSERVER FOR ENTITY %@", entity);
  
  if (![self.registeredEntities containsObject:entity]) {
    [self.registeredEntities addObject:entity];

    [entity addObserver:self forKeyPath:self.attributePath options:NSKeyValueObservingOptionNew context:(__bridge void *)(context)];
  }
}

-(void)registerObserverForEntities:(NSArray*)entities context:(id)context
{
  for (AWEEntity* entity in entities) {
    [self registerObserverForEntity:entity context:context];
  }
}

-(NSArray*)membersOfCollection
{
  id collection = [self.target valueForKeyPath:self.collectionPath];
  if (!collection) {
    return @[];
  }
  else if ([collection isKindOfClass:[NSSet class]]) {
    return [collection allObjects];
  }
  else if ([collection isKindOfClass:[NSDictionary class]]) {
    return [collection allValues];
  }
  else { // NSArray or unknown type
    return collection;
  };
}

-(void)registerAllObservers
{
  AWELog(@"--> REGISTER FOR COLLECTION %@", self.collectionPath);
  
  [self.target addObserver:self forKeyPath:self.collectionPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"member_change"];
  
  self.observedCollection = [self.target valueForKey:self.collectionPath];

  [self registerObserverForEntities:[self membersOfCollection] context:self.context];
}


#pragma mark - Unregister Observers


-(void)unregisterObserverForEntity:(AWEEntity*)entity
{
  AWELog(@"--> UNREGISTER OBSERVER FOR REMOVED ENTITY %@", entity);
    
  if ([self.registeredEntities containsObject:entity]) {
    [self.registeredEntities removeObject:entity];
    [entity removeObserver:self forKeyPath:self.attributePath];
  }
}

-(void)unregisterObserverForEntities:(NSArray*)entities
{
  for (AWEEntity* entity in entities) {
    [self unregisterObserverForEntity:entity];
  }
}

-(void)unregisterAllObservers
{
  AWELog(@"--> UNREGISTER FOR COLLECTION %@", self.collectionPath);  
  
  [self.target removeObserver:self forKeyPath:self.collectionPath];
  self.observedCollection = nil;
  [self unregisterObserverForEntities:[self.registeredEntities allObjects]];
}



#pragma mark - Observe and Dispatch Changes

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  AWELog(@"--> OBSERVATION MANAGER CALLED WITH\n    keypath %@, target %@ context %@ and change %@", keyPath, object, context, change);
  
  @synchronized(self) {
    if ([@"member_change" isEqualToString:(__bridge NSString *)(context)]) {

      if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting) {  // whole collection has been replaced
        if (self.isObserving) {
          [self unregisterAllObservers];
          [self registerAllObservers];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(collectionChanged:context:)]) {
          [self.delegate collectionChanged:self.observedCollection context:self.context];
        }
      }
      else if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeInsertion) {  // inserted a new member to collection
        
        NSArray* newEntites = [change objectForKey:NSKeyValueChangeNewKey];
        if (self.isObserving) {
          [self registerObserverForEntities:newEntites context:self.context];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(newMembers:inCollection:context:)]) {
          [self.delegate newMembers:newEntites inCollection:[self.target valueForKeyPath:self.collectionPath] context:self.context];
        }
      }
      else if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeRemoval) {  // deleted a member from collection
        NSArray* oldEntites = [change objectForKey:NSKeyValueChangeNewKey];
        if (self.isObserving) {
          [self unregisterObserverForEntities:oldEntites];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(removedMembers:fromCollection:context:)]) {
          [self.delegate removedMembers:oldEntites fromCollection:[self.target valueForKeyPath:self.collectionPath] context:self.context];
        }
      }
    }
    else { // entity did change
      if (self.delegate && [self.delegate respondsToSelector:@selector(entityDidChange:context:)]) {
        [self.delegate entityDidChange:object context:(__bridge NSString *)(context)];
      }
    }
  }
}




@end

