//
//  AWEEntityManager.h
//  Wackadoo
//
//  Created by Sascha Lange on 21.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@class AWEEntity;


@interface TextSerialization : NSObject <RKSerialization>

@end

/** Basic management of a particular entity type. Each different type
 * of gamestate entity (subclass of AWEEntity) should come with its own
 * instance of an AWEEntityManager. If more specific behavior is needed
 * for a particular tpye, this should be placed in a corresponding
 * manager that is a subclass of the AWEEntityManager.
 */
@interface AWEEntityManager : NSObject

@property (nonatomic, strong) NSMutableDictionary* entities;
@property (nonatomic, strong) NSString* pathPattern;
@property (nonatomic, strong) NSString* keyPath;
@property (readonly) Class entityClass;
@property (nonatomic, strong, readonly) RKObjectManager* objectManager;

@property (nonatomic, strong, readonly) NSMutableDictionary* updateRequests;
@property (nonatomic, strong, readonly) NSMutableDictionary* relationRequests;
@property (nonatomic, strong, readonly) NSMutableDictionary* relationRequestDates;

#pragma mark
#pragma mark Object Life Cycle

-(id)initWithEntityClass:(Class)entityClass objectManager:(RKObjectManager*)objectManager pathPattern:(NSString*)pathPattern keyPath:(NSString*)keyPath;

#pragma mark
#pragma mark Accessing, Adding and Removing Entities

-(AWEEntity*)entityWithUid:(int)uid;
-(AWEEntity*)entityWithNumber:(NSNumber*)uid;

/** adds the given entity to the local storage or updates a previously added
 * entity. Finally returns the locally stored entity that may be the same
 * instance as the argument, but that may also be another instance that has
 * been added earlier. */
-(AWEEntity*)addEntity:(AWEEntity*)entity;
-(AWEEntity*)addEntity:(AWEEntity *)entity requestedAt:(NSDate*)date;

-(NSArray*)addEntities:(NSArray*)entities;
-(NSArray*)addEntities:(NSArray*)entities requestedAt:(NSDate*)date;

-(void)removeEntity:(AWEEntity*)entity;
-(void)removeEntityWithNumber:(NSNumber*)uid;
-(void)removeEntityWithUid:(int)uid;

-(void)removeAllEntities;

-(NSArray*)allEntities;

#pragma mark
#pragma mark Retrieval of Remote Objects


-(void)getEntitiesAtPath:(NSString*)path parameters:(NSDictionary*)dictionary success:(void (^) (NSArray*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock;

-(void)getEntitiesWithRelation:(NSString*)relation forEntity:(AWEEntity*)entity success:(void (^) (NSArray*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock;

-(void)updateEntity:(AWEEntity*)entity success:(void (^) (AWEEntity*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock;

-(void)updateEntityWithNumber:(NSNumber*)uid success:(void (^) (AWEEntity*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock;

-(void)updateEntityWithUid:(int)uid success:(void (^) (AWEEntity*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock;


-(void)putEntity:(AWEEntity*)entity success:(void (^) (int statusCode))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock;


-(NSDate*)lastUpdateOnRelation:(NSString*)relation entity:(AWEEntity*)entity;


#pragma mark
#pragma mark Mappings (AWEMappableObject protocol)

-(void)setupMapping;

-(NSIndexSet*)acceptableResponseCodes;


@end