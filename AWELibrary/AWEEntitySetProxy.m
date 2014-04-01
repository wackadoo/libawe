//
//  AWEEntitySetProxy.m
//  Wackadoo
//
//  Created by Stefan Mattern on 29.01.13.
//  Copyright (c) 2013 5D Lab GmbH. All rights reserved.
//

#import "AWEEntitySetProxy.h"

@implementation AWEEntitySetProxy

-(id)initWithSet:(NSMutableSet *)set
{
  if ((self = [super init])) {
    self.entities = set;
  }
  return self;
}


+(AWEEntitySetProxy *)entitySetProxyWithSet:(NSMutableSet *)set
{
  return [[AWEEntitySetProxy alloc] initWithSet:set];
}

- (NSUInteger)countOfEntities
{
  return [self.entities count];
}

- (NSEnumerator *)enumeratorOfEntities
{
  return [self.entities objectEnumerator];
}

- (AWEEntity *)memberOfTEntities:(AWEEntity *)anObject
{
  return [self.entities member:anObject];
}

- (void)addEntitiesObject:(AWEEntity *)anObject
{
  [self.entities addObject:anObject];
}

- (void)addEntities:(NSSet *)manyObjects
{
  [self.entities unionSet:manyObjects];
}

- (void)removeEntitiesObject:(AWEEntity *)anObject
{
  [self.entities removeObject:anObject];
}

- (void)removeEntities:(NSSet *)manyObjects
{
  [self.entities minusSet:manyObjects];
}

- (void)intersectEntities:(NSSet *)objects
{
  [self.entities intersectSet:objects];
}


@end
