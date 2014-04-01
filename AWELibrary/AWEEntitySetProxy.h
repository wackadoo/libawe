//
//  AWEEntitySetProxy.h
//  Wackadoo
//
//  Created by Stefan Mattern on 30.01.13.
//  Copyright (c) 2013 5D Lab GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AWEEntity;


@interface AWEEntitySetProxy : NSObject

@property (atomic, strong) NSMutableSet* entities;

-(id)initWithSet:(NSMutableSet*)set;

+(AWEEntitySetProxy*)entitySetProxyWithSet:(NSMutableSet*)set;

- (NSUInteger)countOfEntities;
- (NSEnumerator *)enumeratorOfEntities;
- (AWEEntity *)memberOfTEntities:(AWEEntity *)anObject;
- (void)addEntitiesObject:(AWEEntity *)anObject;
- (void)addEntities:(NSSet *)manyObjects;
- (void)removeEntitiesObject:(AWEEntity *)anObject;
- (void)removeEntities:(NSSet *)manyObjects;
- (void)intersectEntities:(NSSet *)objects;

@end
