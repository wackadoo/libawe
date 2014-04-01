//
//  AWEEntityManager.m
//  Wackadoo
//
//  Created by Sascha Lange on 21.01.13.
//  Copyright (c) 2013 Sascha Lange. All rights reserved.
//

#import "AWEEntityManager.h"
#import "AWEEntity.h"
#import "AWEAttributeHash.h"
#import "AWETimeCorrection.h"
#import "AWEDateUtils.h"
#import "AWEConfig.h"
#import "AWELog.h"


//#import "AWEConstructionQueue.h"

@implementation TextSerialization


+(id)objectFromData:(NSData*)data error:(NSError**)error
{
  return [NSDictionary dictionary];
}

+(NSData *)dataFromObject:(id)object error:(NSError *__autoreleasing *)error
{
  return [NSData data];
}

+(void)load
{
  [RKMIMETypeSerialization registerClass:[TextSerialization class] forMIMEType:@"text/plain"];
}

@end

#pragma mark - Request Descriptor


@interface AWERequestDescriptor : NSObject

@property (nonatomic, strong) AWEEntity* entity;

@property (nonatomic, copy) void (^successBlock) (AWEEntity* entity);
@property (nonatomic, copy) void (^relationSuccessBlock) (NSArray* entities);
@property (nonatomic, copy) void (^failureBlock) (int statusCode, NSError *error);

+(AWERequestDescriptor*)requestDescriptorWithEntity:(AWEEntity*)entity success:(void (^) (AWEEntity*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock;

+(AWERequestDescriptor*)requestDescriptorWithRelationFor:(AWEEntity*)entity success:(void (^) (NSArray*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock;


@end




@implementation AWERequestDescriptor

+(AWERequestDescriptor*)requestDescriptorWithEntity:(AWEEntity*)entity success:(void (^) (AWEEntity*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock
{
  AWERequestDescriptor* descriptor = [AWERequestDescriptor new];
  descriptor.entity = entity;
  descriptor.successBlock = successBlock;
  descriptor.failureBlock = failureBlock;
  return descriptor;
}

+(AWERequestDescriptor*)requestDescriptorWithRelationFor:(AWEEntity*)entity success:(void (^) (NSArray*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock
{
  AWERequestDescriptor* descriptor = [AWERequestDescriptor new];
  descriptor.entity = entity;
  descriptor.relationSuccessBlock = successBlock;
  descriptor.failureBlock = failureBlock;
  return descriptor;
}

-(void)dealloc
{
  NSLog(@"DEALLOC REQUEST DESCRIPTOR for Entity %d", [self.entity.uid intValue]);
}

@end




#pragma mark - Entity Manager

/** private interface */
@interface AWEEntityManager ()

@property (nonatomic, strong, readwrite) NSMutableDictionary* updateRequests;
@property (nonatomic, strong, readwrite) NSMutableDictionary* relationRequests;
@property (nonatomic, strong, readwrite) NSMutableDictionary* relationRequestDates;

-(void)registerTimeMeasurementWithTimeStarted:(NSDate*)started timeEnded:(NSDate*)ended dateStringInResponse:(NSString*)response;

-(void)prepareRequest:(NSMutableURLRequest*)request forEntity:(AWEEntity*)entity;

-(NSIndexSet*)acceptableResponseCodes;

@end



@implementation AWEEntityManager

#pragma mark - Initialization and Object Life Cylce


-(id)initWithEntityClass:(Class)entityClass objectManager:(RKObjectManager *)objectManager pathPattern:(NSString *)pathPattern keyPath:(NSString *)keyPath
{
  if ((self = [super init])) {
    _entityClass = entityClass;
    _objectManager = objectManager;
    self.entities = [NSMutableDictionary dictionary];
    
    self.updateRequests = [NSMutableDictionary dictionary];
    self.relationRequests = [NSMutableDictionary dictionary];
    self.relationRequestDates = [NSMutableDictionary dictionary];
    
    _keyPath = keyPath;
    self.pathPattern = pathPattern; // sets up mapping
  }
  return self;
}

-(void)dealloc
{
  AWELog(@"+-- DEALLOC EntityManager: %@", self);
}

-(void)setPathPattern:(NSString *)pathPattern
{
  _pathPattern = pathPattern;
  [self setupMapping];
}

-(void)setKeyPath:(NSString *)keyPath
{
  _keyPath = keyPath;
  [self setupMapping];
}

#pragma mark
#pragma mark Mappings (AWEMappableObject protocol)

-(void)setupMapping
{
  if (self.objectManager) {
    RKObjectMapping* characterRequestMapping  = [self.entityClass requestMapping];
    RKObjectMapping* characterResponseMapping = [self.entityClass responseMapping];
    
    RKRequestDescriptor* characterRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:characterRequestMapping objectClass:self.entityClass rootKeyPath:self.keyPath];  // TODO : is this the correct change?
    
    RKResponseDescriptor* characterResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:characterResponseMapping pathPattern:nil keyPath:self.keyPath statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [self.objectManager addRequestDescriptor:characterRequestDescriptor];
    [self.objectManager addResponseDescriptor:characterResponseDescriptor];
    
    // ROUTE GET:
    [self.objectManager.router.routeSet addRoute:[RKRoute routeWithClass:self.entityClass pathPattern:[NSString stringWithFormat:@"%@/:uid", self.pathPattern] method:RKRequestMethodGET]];
    
    // ROUTE PUT:
    [self.objectManager.router.routeSet addRoute:[RKRoute routeWithClass:self.entityClass pathPattern:[NSString stringWithFormat:@"%@/:uid", self.pathPattern] method:RKRequestMethodPUT]];
    
    // ROUTE POST:
    [self.objectManager.router.routeSet addRoute:[RKRoute routeWithClass:self.entityClass pathPattern:self.pathPattern method:RKRequestMethodPOST]];
    
    // ROUTE INDEX:
    [self.objectManager.router.routeSet addRoute:[RKRoute routeWithName:[NSString stringWithFormat:@"all_%@s", self.keyPath] pathPattern:self.pathPattern method:RKRequestMethodGET]];
    
    // ROUTE DELETE:
    RKRoute* route = [RKRoute routeWithClass:self.entityClass pathPattern:[NSString stringWithFormat:@"%@/:uid", self.pathPattern] method:RKRequestMethodDELETE];
    AWELog(@"ROUTE: %@", route);
    [self.objectManager.router.routeSet addRoute:route];
  }
}

#pragma mark
#pragma mark Accessing, Adding and Removing Entities

-(AWEEntity*)entityWithUid:(int)uid
{
  return [self entityWithNumber:[NSNumber numberWithInt:uid]];
}

-(AWEEntity*)entityWithNumber:(NSNumber*)uid
{
  return [self.entities objectForKey:uid];
}

-(AWEEntity*)addEntity:(AWEEntity*)entity
{
  return [self addEntity:entity requestedAt:[NSDate dateWithTimeIntervalSince1970:0.0]];
}


-(AWEEntity*)addEntity:(AWEEntity*)entity requestedAt:(NSDate *)date
{
  if (entity == nil || entity.uid == nil) {
      AWELogError(@"Trying to add an invalid entity: %@", entity);
  }
  
  AWEEntity* existing = [self.entities objectForKey:entity.uid];
  if (existing == nil) {
    
    if (entity.uid != nil) {  // protect from crash due to key == nil
      [entity makeLocalCopy];
      entity.requestedAt = date;
      [self.entities setObject:entity forKey:entity.uid];
    }
    else { // this is a serious error!
      AWELogError(@"PREVENTED CRASH: key is nil for entity %@", entity);
    }
    
    existing = entity;
  }
  else {
    [existing updateFrom:entity];
    existing.requestedAt = date;
  }
  
  // now handle nested relationships

  return existing;
}

-(NSArray*)addEntities:(NSArray *)entities
{
  return [self addEntities:entities requestedAt:[NSDate dateWithTimeIntervalSince1970:0.0]];
}

-(NSArray*)addEntities:(NSArray *)entities requestedAt:(NSDate *)date
{
  NSMutableArray* localEntities = [NSMutableArray arrayWithCapacity:[entities count]];
  for(AWEEntity* entity in entities) {
    AWEEntity* localEntity = [self addEntity:entity requestedAt:date];
    [localEntities addObject:localEntity];
  }
  return localEntities;
}


-(void)removeEntity:(AWEEntity*)entity
{
  [self.entities removeObjectForKey:entity.uid];
  [entity destroyLocalCopy];
}

-(void)removeEntityWithNumber:(NSNumber*)uid
{
  AWEEntity* entity = [self.entities objectForKey:uid];
  [self.entities removeObjectForKey:uid];
  [entity destroyLocalCopy];
}


-(void)removeEntityWithUid:(int)uid
{
  [self removeEntityWithNumber:[NSNumber numberWithInt:uid]];
}

-(NSArray*)allEntities
{
  return [self.entities allValues];
}

-(void)removeAllEntities
{
  @autoreleasepool {
    NSArray* all = [[self.entities allValues] copy];
  
    for (AWEEntity* entity in all) {
      [entity destroyLocalCopy];
    }
  
    self.entities = [NSMutableDictionary dictionary];
  }
}


#pragma mark - Request Registry for Updates

-(BOOL)registerUpdateRequest:(AWERequestDescriptor*)request
{
  BOOL newRequest = NO;
  
  @synchronized(self.updateRequests) { // actually we only need a lock on the entities key & entry. improve this, in case it turns out if ( a bottle neck
    
    id key = request.entity.uid ? request.entity.uid : [NSNull null];
    
    NSMutableArray* ongoingRequests = [self.updateRequests objectForKey:key];
    
    if (!ongoingRequests) {
      ongoingRequests = [NSMutableArray array];
      [self.updateRequests setObject:ongoingRequests forKey:key];
      newRequest =YES;
    }
    
    if (request.failureBlock || request.successBlock) {
      [ongoingRequests addObject:request];
    }
    
  }
  
  return newRequest;
}


-(void)finalizeSuccessfullUpdateRequestForEntity:(AWEEntity*)entity
{
  @synchronized(self.updateRequests) {
    
    NSObject* key = entity.uid ? entity.uid : [NSNull null];
    
    NSArray* requests = [self.updateRequests objectForKey:key];
    
    if (requests) {
            
      for (AWERequestDescriptor* descriptor in requests) {
        if (descriptor.successBlock) {
          descriptor.successBlock(entity);
        }
      }
      [self.updateRequests removeObjectForKey:key];
    }
    else {
      AWELog(@"ERROR: no pending request descriptors found when processing response from server.");
    }
    
  }
}


-(void)finalizeUpdateRequestForEntity:(AWEEntity*)entity statusCode:(int)code error:(NSError*)error
{
  @synchronized(self.updateRequests) {
    
    NSObject* key = entity.uid ? entity.uid : [NSNull null];
    
    NSArray* requests = [self.updateRequests objectForKey:key];
    
    if (requests) {
      for (AWERequestDescriptor* descriptor in requests) {
        if (descriptor.failureBlock) {
          descriptor.failureBlock(code, error);
        }
      }
      [self.updateRequests removeObjectForKey:key];
    }
    else {
      AWELog(@"ERROR: no pending request descriptors found when processing response from server.");
    }
    
  }
}



#pragma mark - Request Registry for Relations

-(BOOL)registerRequest:(AWERequestDescriptor*)request forRelation:(NSString*)relation
{
  BOOL newRequest = NO;

  @synchronized(self.relationRequests) {

  
  NSMutableDictionary* relationHash = [self.relationRequests objectForKey:relation];
  
  if (!relationHash) {
    relationHash = [NSMutableDictionary dictionary];
    [self.relationRequests setObject:relationHash forKey:relation];
  }
      
    id key = request.entity.uid ? request.entity.uid : [NSNull null];
    
    NSMutableArray* ongoingRequests = [relationHash objectForKey:key];
    
    if (!ongoingRequests) {
      ongoingRequests = [NSMutableArray array];
      [relationHash setObject:ongoingRequests forKey:key];
      newRequest =YES;
    }
    
    if (request.failureBlock || request.relationSuccessBlock) {
      [ongoingRequests addObject:request];
    }
    
  }
  
  return newRequest;
}

-(NSDate*)lastUpdateRequestInRelation:(NSString*)relation entity:(AWEEntity*)entity
{
  return [self lastUpdateOnRelation:relation entity:entity];
}


-(void)setLastUpdateAt:(NSDate*)date relation:(NSString*)relation entity:(AWEEntity*)entity
{
  @synchronized(self.relationRequests) {

  NSMutableDictionary* relationHash = [self.relationRequestDates objectForKey:relation];
  
  if (!relationHash) {
    relationHash = [NSMutableDictionary dictionary];
    [self.relationRequestDates setObject:relationHash forKey:relation];
  }
  
  id key = entity.uid ? entity.uid : [NSNull null];
  
  if (!date) {
    AWELogError(@"CRITICAL ERROR: no date set when updating entity of class %@ with id %d", NSStringFromClass([entity class]), [[entity uid] intValue]);
    date = [NSDate date];
  }
  
  [relationHash setObject:date forKey:key];
    
  }
}

-(void)finalizeSuccessfullRequestForRelation:(NSString*)relation entity:(AWEEntity*)entity members:(NSArray*)members
{
  @synchronized(self.relationRequests) {

    NSMutableDictionary* relationHash = [self.relationRequests objectForKey:relation];
  
    if (!relationHash) {
      AWELog(@"ERROR: no hash for relation found when processing response");
      return ;
    }
  
  
    id key = entity.uid ? entity.uid : [NSNull null];
    
    NSArray* requests = [relationHash objectForKey:key];
    
    if (requests) {
      
      for (AWERequestDescriptor* descriptor in requests) {
        if (descriptor.relationSuccessBlock) {
          descriptor.relationSuccessBlock(members);
        }
      }
      [relationHash removeObjectForKey:key];
    }
    else {
      AWELog(@"ERROR: no pending request descriptors found when processing response from server.");
    }
    
  }
}


-(void)finalizeRequestForRelation:(NSString*)relation entity:(AWEEntity*)entity statusCode:(int)code error:(NSError*)error
{
  @synchronized(self.relationRequests) {

    NSMutableDictionary* relationHash = [self.relationRequests objectForKey:relation];
  
    if (!relationHash) {
      AWELog(@"ERROR: no hash for relation found when processing response");
      return ;
    }
  
  
    id key = entity.uid ? entity.uid : [NSNull null];
    
    NSArray* requests = [relationHash objectForKey:key];
    
    if (requests) {
      for (AWERequestDescriptor* descriptor in requests) {
        if (descriptor.failureBlock) {
          descriptor.failureBlock(code, error);
        }
      }
      [relationHash removeObjectForKey:key];
    }
    else {
      AWELog(@"ERROR: no pending request descriptors found when processing response from server.");
    }
    
  }
}


#pragma mark
#pragma mark Retrieval of Remote Objects



-(void)registerTimeMeasurementWithTimeStarted:(NSDate*)started timeEnded:(NSDate*)ended dateStringInResponse:(NSString*)response
{
  NSDate* responseDate = [[AWEDateUtil sharedDateUtil] dateFromResponseHeader:response];
  
  if ([ARCMSConfig sharedConfig].timeDebugLevel >= DEBUG_LEVEL_DEBUG) {
    AWELog(@"DATE (string) IN RESPONSE %@", response);
    AWELog(@"DATE (parsed) in RESPONSE %@", responseDate);
    AWELog(@"DATE REQUEST STARTED LOCAL %@", started);
  }
  
  [[AWETimeCorrection sharedTimeCorrection] registerMeasurementWithRemoteTime:responseDate localTime:started requestEndTime:ended];
}


-(void)getEntitiesAtPath:(NSString*)path parameters:(NSDictionary*)dictionary success:(void (^) (NSArray*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock
{
  path = path == nil ? self.pathPattern : path; // use path pattern as default
  
  [self.objectManager getObjectsAtPath:path
                            parameters:dictionary
                               success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
   {
     NSArray* result = [mappingResult array];
     AWELog(@"Loaded entities: %@", result);
     
     result = [self addEntities:result];
     
     if (successBlock) {
       successBlock(result);
     }
   } failure:^(RKObjectRequestOperation *operation, NSError *error)
   {
     AWELog(@"Hit error: %@", error);
     if (failureBlock) {
       failureBlock(operation.HTTPRequestOperation.response.statusCode, error);
     }
   }];
}


// ////////////////////////////////////////////////////////////////////
//
//   U P D A T E   R E L A T I O N
//
// ////////////////////////////////////////////////////////////////////


-(void)getEntitiesWithRelation:(NSString*)relation forEntity:(AWEEntity*)entity success:(void (^) (NSArray*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock
{
  NSDate* requestStarted = [[NSDate alloc] init];
  
  AWERequestDescriptor* requestDescriptor = [AWERequestDescriptor requestDescriptorWithRelationFor:entity success:successBlock failure:failureBlock];
  
  BOOL newRequest = [self registerRequest:requestDescriptor forRelation:relation];
  
  if (newRequest) {
  
    NSMutableURLRequest* request = [self.objectManager requestWithPathForRelationship:relation ofObject:entity method:RKRequestMethodGET parameters:nil];
        
    NSDate* lastUpdate = [self lastUpdateRequestInRelation:relation entity:entity];
    AWELog(@"Last update: %@", lastUpdate);
    if (lastUpdate) {
      [request setValue:[[AWEDateUtil sharedDateUtil] dateToHeader:lastUpdate] forHTTPHeaderField:@"If-Modified-Since"];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    RKObjectRequestOperation* operation = [self.objectManager objectRequestOperationWithRequest:request success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
    {
   //   AWELogDebug(@"RESULT %@", operation.HTTPRequestOperation.responseString);
      
      NSArray* result = nil;
      
      NSDate* requestEnded = [NSDate date];
      NSDate* serverTime   = [[AWEDateUtil sharedDateUtil] dateFromResponseHeader:[operation.HTTPRequestOperation.response.allHeaderFields objectForKey:@"Date"]];
      [self setLastUpdateAt:serverTime relation:relation entity:entity];

      // //////////   P R O C E S S   3 0 4   /////////////
      
      if ( //operation.HTTPRequestOperation.wasNotModified ||
          operation.HTTPRequestOperation.response.statusCode == 304) {
        
        AWELog(@"304 - entities not modified.");
        
      }

      // //////////   P R O C E S S   2 0 X  /////////////
      
      else {
        
        AWELog(@"Request was for entity %@ : status code %d", entity, operation.HTTPRequestOperation.response.statusCode);
        
        result = [mappingResult array];
        result = [self addEntities:result requestedAt:serverTime];
        
        AWELog(@"20X - entities: %@", result);

      }
      
      [self registerTimeMeasurementWithTimeStarted:requestStarted timeEnded:requestEnded dateStringInResponse:[operation.HTTPRequestOperation.response.allHeaderFields objectForKey:@"Date"]];
      
      [self finalizeSuccessfullRequestForRelation:relation entity:entity members:result];

      
     } failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
       
       // //////////   P R O C E S S   4 0 4  /////////////

       AWELog(@"Hit error: %@", error);
       [self finalizeRequestForRelation:relation entity:entity statusCode:operation.HTTPRequestOperation.response.statusCode error:error];
       

     }];
    
    operation.HTTPRequestOperation.acceptableStatusCodes = [self acceptableResponseCodes];
    
  /*  if ([relation isEqualToString:@"character_quests"]) {
      AWELog(@"Request MIME TYPES: %@", [RKMIMETypeSerialization registeredMIMETypes]);
      AWELog(@"Request OPERATION DESCS: %@", operation.responseDescriptors);
      //     [self.objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:nil pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:304]]];
    }*/

    
    [self.objectManager enqueueObjectRequestOperation:operation];
  }
}


// ////////////////////////////////////////////////////////////////////
//
//   U P D A T E   E N T I T Y
//
// ////////////////////////////////////////////////////////////////////


-(void)updateEntity:(AWEEntity*)entity success:(void (^) (AWEEntity*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock
{
  NSDate* requestStarted = [NSDate date];
  
  AWERequestDescriptor* requestDescriptor = [AWERequestDescriptor requestDescriptorWithEntity:entity success:successBlock failure:failureBlock];
  
  BOOL newRequest = [self registerUpdateRequest:requestDescriptor];
  
  if (newRequest) {
    
    NSMutableURLRequest* request = [self.objectManager requestWithObject:entity method:RKRequestMethodGET path:nil parameters:nil];
    
    [self prepareRequest:request forEntity:entity];
    
    RKObjectRequestOperation* operation = [self.objectManager objectRequestOperationWithRequest:request success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
      
      AWEEntity* newEntity = nil;
      
      NSDate* requestEnded = [[NSDate alloc] init];
      NSDate* serverTime   = [[AWEDateUtil sharedDateUtil] dateFromResponseHeader:[operation.HTTPRequestOperation.response.allHeaderFields objectForKey:@"Date"]];
      
      // //////////   P R O C E S S   3 0 4   /////////////
      
      if (//operation.HTTPRequestOperation.wasNotModified ||
          operation.HTTPRequestOperation.response.statusCode == 304) {
        
        newEntity = entity;
        newEntity.requestedAt = serverTime;
        
        AWELog(@"304 - entity not modified: %@", newEntity);
        
      }
      
      // //////////   P R O C E S S   2 0 X  /////////////
      
      else {
        
        newEntity = mappingResult.firstObject;
        newEntity = [self addEntity:newEntity requestedAt:serverTime];
        newEntity.etag = [operation.HTTPRequestOperation.response.allHeaderFields objectForKey:@"ETag"];
        
        AWELog(@"20X - with time %@ and etag %@ got entity: %@", newEntity.requestedAt, newEntity.etag, newEntity);
      }

      [self registerTimeMeasurementWithTimeStarted:requestStarted timeEnded:requestEnded dateStringInResponse:[operation.HTTPRequestOperation.response.allHeaderFields objectForKey:@"Date"]];
      
      [self finalizeSuccessfullUpdateRequestForEntity:newEntity];
      
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
      
      // //////////   P R O C E S S   4 0 4  /////////////
      
      if (operation.HTTPRequestOperation.response.statusCode == 404) {
        
        AWELog(@"DESTROYING %@", entity);
        [entity destroyLocalCopy];
        [self removeEntity:entity];
        
      }
      
      // ///////   P R O C E S S   E R R O R   ///////////
      
      else {
        AWELog(@"Hit error: %@", [error description]);
      }
      
      [self finalizeUpdateRequestForEntity:entity statusCode:operation.HTTPRequestOperation.response.statusCode error:error];
      
    }];
    
    operation.HTTPRequestOperation.acceptableStatusCodes = [self acceptableResponseCodes];
    
    [self.objectManager enqueueObjectRequestOperation:operation];
  }
}






-(void)updateEntityWithNumber:(NSNumber*)uid success:(void (^) (AWEEntity*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock
{
  AWEEntity* entity = [self entityWithNumber:uid];
  if (!entity) {
    entity = [self.entityClass new];
    entity.uid = uid;
    [self addEntity:entity];
  }
  [self updateEntity:entity success:successBlock failure:failureBlock];
}

-(void)updateEntityWithUid:(int)uid success:(void (^) (AWEEntity*))successBlock failure:(void (^) (int statusCode, NSError *error))failureBlock
{
  [self updateEntityWithNumber:[NSNumber numberWithInt:uid] success:successBlock failure:failureBlock];
}



-(NSIndexSet*)acceptableResponseCodes
{
  NSMutableIndexSet* set = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 299)];
  [set addIndex:304];
  return set;
}

-(void)prepareRequest:(NSMutableURLRequest*)request
            forEntity:(AWEEntity*)entity
{
  NSString* lastUpdate = [entity ifModifiedSinceValue];
  if (lastUpdate) {
    [request setValue:lastUpdate forHTTPHeaderField:@"If-Modified-Since"];
  }
  if (entity.etag) {
    [request setValue:entity.etag forHTTPHeaderField:@"If-None-Match"];
  }
  request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
}


-(NSDate *)lastUpdateOnRelation:(NSString *)relation entity:(AWEEntity *)entity
{
  NSMutableDictionary* relationHash = [self.relationRequestDates objectForKey:relation];
  
  id key = entity.uid ? entity.uid : [NSNull null];
  
  return relationHash ? [relationHash objectForKey:key] : nil;
}


-(void)putEntity:(AWEEntity *)entity success:(void (^)(int))successBlock failure:(void (^)(int, NSError *))failureBlock
{
  [self.objectManager putObject:entity path:nil parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
    
    if (successBlock) {
      successBlock(operation.HTTPRequestOperation.response.statusCode);
    }
    
  } failure:^(RKObjectRequestOperation *operation, NSError *error) {
    if (failureBlock) {
      failureBlock(operation.HTTPRequestOperation.response.statusCode, error);
    }
  }];
}


@end




