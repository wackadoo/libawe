//
//  AWEEntity.h
//  Wackadoo
//
//  Created by Sascha Lange on 23.11.12.
//  Copyright (c) 2012 Sascha Lange. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "AWEEntityManager.h"
#import "AWELog.h"


@class AWEAttributeHash;

@protocol AWEMappableObject <NSObject>

+(RKObjectMapping*)requestMapping;
+(RKObjectMapping*)responseMapping;

-(NSDictionary*)toDictionary;
-(void)updateFromDictionary:(NSDictionary*)dictionary;

//+(id<AWEMappableObject>)mappableObjectWithDictionary:(NSDictionary*)dictionary;

@end


#pragma mark
#pragma mark

/** 
 * AWEEntity is the base class for all classes representing parts of the 
 * games gamestate in the client. 
 * 
 * # Data Exchange with the Server Using RESTKit
 *
 * As the client's game state 'mirrors' the state of the toy world represented 
 * at the remote game server, this class needs to come with mechanisms
 * for fetching, updating and changing states on the server. We have chosen
 * RESTKit and its JSON-parsing and object mapping facilities to provide
 * this functionallity. 
 *
 * The client's representation of the game state has been carefully designed
 * according to the following fundametnal principles:
 *
 * - clean separation of 'pure' model (representation of the game state) and 
 *   communication logic
 * - as its so fundamental, the game state representation itself should not
 *   depend on RESTKit; or should at least have as few dependencies as possible
 *
 * Thus, we came up with the idea of separating data representation and
 * corresponding mapping from all communication operations: the AWEEntity class
 * comes together with a 'brother', the AWEEntityManger class, that is able
 * to handle serialization and communication of a particular AWEEntity type.
 * The manager holds the knowledge about routes on the server and communication, 
 * in general. Furthermore, only two (easily replaceable and deprecable) mehtods 
 * in the AWEEntity are the sole locations that collect all the knowledge about 
 * RESTKit-specific declarations of the object mapping.
 */
@interface AWEEntity : NSObject <AWEMappableObject>

@property (nonatomic, strong) NSNumber* uid;
@property (nonatomic, strong) NSDate* updatedAt;    ///< last change on server in server time
@property (nonatomic, strong) NSDate* createdAt;    ///< time of createion in server time
@property (nonatomic, strong) NSDate* requestedAt;  ///< last udpate request to server in server time
@property (nonatomic, strong) NSString* etag;       ///< server generated entity tag (hash value on the entity state).

@property (readonly, getter = isLocalCopy) BOOL localCopy;

@property (readonly) int uidAsInt;

@property (readonly, getter = isDestroyed) BOOL destroyed;

-(AWEEntity*)updateFrom:(AWEEntity*)entity;

/** converts the entity to a dictionary. */
-(NSDictionary*)toDictionary;
-(void)updateFromDictionary:(NSDictionary*)dictionary;

//+(NSMutableDictionary*)managers;
+(NSMutableDictionary*)attributeHashes;
+(AWEAttributeHash*)createHashForAttribute:(NSString*)attribute;
+(int)numberOfInstances;

/** two entities are equal, if they are of the same class and
 * have the same uid. This assumes that you have only one instance
 * for representing the same game entity in any collections. */
-(BOOL)isEqual:(id)object;
/** returns the value of the uid. */
-(NSUInteger)hash;

-(void)makeLocalCopy;
-(void)destroyLocalCopy;

-(NSString*)ifModifiedSinceValue;


@end



@interface NSString (CamelCaseConversion)

-(NSString*)dashedFromCamelCase;
-(NSString*)camelCaseFromDashed;

@end


