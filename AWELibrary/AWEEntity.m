//
//  AWEEntity.m
//  Wackadoo
//
//  Created by Sascha Lange on 23.11.12.
//  Copyright (c) 2012 Sascha Lange. All rights reserved.
//

#import "AWEEntity.h"
#import "AWEAttributeHash.h"
#import "AWETimeCorrection.h"
#import "AWEDateUtils.h"
#import "ARCMSConfig.h"
#import <RestKit/ObjectMapping/RKObjectMappingOperationDataSource.h>
//#import "AWENode.h"

@implementation NSString (CamelCaseConversion)


-(NSString*)dashedFromCamelCase
{
  NSScanner *scanner = [NSScanner scannerWithString:self];
  scanner.caseSensitive = YES;
  
  NSString *builder = [NSString string];
  NSString *buffer = nil;
  NSUInteger lastScanLocation = 0;
  
  while ([scanner isAtEnd] == NO) {
    
    if ([scanner scanCharactersFromSet:[NSCharacterSet lowercaseLetterCharacterSet] intoString:&buffer]) {
      
      builder = [builder stringByAppendingString:buffer];
      
      if ([scanner scanCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&buffer]) {
        
        builder = [builder stringByAppendingString:@"-"];
        builder = [builder stringByAppendingString:[buffer lowercaseString]];
      }
    }
    
    // If the scanner location has not moved, there's a problem somewhere.
    if (lastScanLocation == scanner.scanLocation) return nil;
    lastScanLocation = scanner.scanLocation;
  }
  
  return builder;
}

-(NSString *)camelCaseFromDashed
{
  NSScanner *scanner = [NSScanner scannerWithString:self];
  scanner.caseSensitive = YES;
  
  NSString *builder = [NSString string];
  NSString *buffer = nil;
  NSUInteger lastScanLocation = 0;
  
  while ([scanner isAtEnd] == NO) {
    
    if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"_"] intoString:&buffer]) {
      
      if ([builder length] > 0) {
        builder = [builder stringByAppendingString:[buffer capitalizedString]];
      }
      else {
        builder = [builder stringByAppendingString:buffer];
      }
      
      if (![scanner isAtEnd]) {
        [scanner setScanLocation:scanner.scanLocation+1];
      }
    }
    
    // If the scanner location has not moved, there's a problem somewhere.
    if (lastScanLocation == scanner.scanLocation) return nil;
    lastScanLocation = scanner.scanLocation;
  }
  
 // AWELog(@"CAMEL CASED: %@", builder);
  
  return builder;
}


@end

@interface AWEEntity ()

@property (nonatomic, strong) RKObjectMappingOperationDataSource* dataSource;

@end

static int __num_entity_instances;

@implementation AWEEntity

-(id)init
{
  if ((self = [super init])) {
    _destroyed = NO;
    _localCopy = NO;
    ++__num_entity_instances;
  }
  return self;
}

+(void)initialize
{
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    
    __num_entity_instances = 0;
    
  });
  
}

-(void)dealloc
{
  AWELog(@"|-- DEALLOC Entity %@: %@", self.isLocalCopy ? @"(local)" : @"", self);
  if (self.isLocalCopy) {
    [self destroyLocalCopy];
  }
  --__num_entity_instances;
}

-(void)makeLocalCopy
{
  @synchronized(self) {
    if (!self.isLocalCopy) {
      _localCopy = YES;
      for (AWEAttributeHash* hash in [[AWEEntity attributeHashesForClass:[self class]] allValues]) {
        [hash registerInstance:self];
      }
    }
  }
}

+(int)numberOfInstances
{
  return __num_entity_instances;
}


-(BOOL)isEqual:(id)object
{
  return [self isMemberOfClass:[object class]] && [self.uid intValue] == [((AWEEntity*)object).uid intValue];
}

-(NSUInteger)hash
{
  return [self.uid intValue];
}

-(int)uidAsInt
{
  return self.uid ? [self.uid integerValue] : 0;
}

-(void)destroyLocalCopy
{
  @synchronized(self) {

    if (_destroyed || !_localCopy) return ;
  
    for (AWEAttributeHash* hash in [[AWEEntity attributeHashesForClass:[self class]] allValues]) {
      [hash unregisterInstance:self];
    }

    _destroyed = YES;

  }
}

#pragma mark
#pragma mark Mappings

+(RKObjectMapping*)requestMapping
{
  static RKObjectMapping* mapping = nil;
  if (mapping == nil) {
    mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromDictionary:@{
      @"uid" : @"id",
    }];
  }
  return mapping;
}

+(RKObjectMapping*)responseMapping
{
  static RKObjectMapping* mapping = nil;
  if (mapping == nil) {
    mapping = [RKObjectMapping mappingForClass:[self class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
      @"id" : @"uid",
    }];
  }
  return mapping;
}

-(NSDictionary*)toDictionary
{
  NSMutableDictionary* dict = [NSMutableDictionary dictionary];
  RKObjectMapping* mapping = [[[self class] responseMapping] inverseMapping];
  RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:self destinationObject:dict mapping:mapping];
  
  self.dataSource = [RKObjectMappingOperationDataSource new];
  operation.dataSource = self.dataSource;
  
  if (![operation performMapping:nil]) {
    AWELog(@"ERROR: Mapping to dictionary did fail.");
  }
  return dict;
}

-(void)updateFromDictionary:(NSDictionary*)dictionary;
{
  RKObjectMapping* mapping = [[self class] responseMapping];
  RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:self mapping:mapping];
  
  self.dataSource = [RKObjectMappingOperationDataSource new];
  operation.dataSource = self.dataSource;
  
  if (![operation performMapping:nil]) {
    AWELog(@"ERROR: Mapping from dictionary did fail.");
  }
}


#pragma mark
#pragma mark Updating


-(AWEEntity*)updateFrom:(AWEEntity*)entity
{
  RKObjectMapping* mapping = [[self class] responseMapping];
  
  if (mapping && [self.uid intValue] == [entity.uid intValue]) {
    NSArray* attributeMappings = mapping.attributeMappings;
    for (RKAttributeMapping* attributeMapping in attributeMappings) {
      id newValue = [entity valueForKeyPath:attributeMapping.destinationKeyPath];
      id oldValue = [self   valueForKeyPath:attributeMapping.destinationKeyPath];
      
      if (![newValue isEqual:oldValue]) {
        [self setValue:newValue forKeyPath:attributeMapping.destinationKeyPath];
      }
    }
    
    for (RKRelationshipMapping* relationshipMapping in mapping.relationshipMappings) {
      id value = [entity valueForKeyPath:relationshipMapping.destinationKeyPath];
      
      [self setValue:value forKey:relationshipMapping.destinationKeyPath];
      
/*      if ([value isKindOfClass:[NSArray class]]) {
        for (AWEEntity* member in value) {
          AWEEntity* localCopy = [member.manager entityWithNumber:member.uid];
          if (localCopy) {
            [localCopy updateFrom:member];
          }
        }
      }*/
      
      
      /// \fixme Presently we do NO DEEP UPDATING of nested entities. we simply assign the incoming collection of entities to the corresponding attribute of self. Should we update / copy the nested object???
    }
    
  }
  else {
    AWELog(@"ERROR UPDATING ENTITY: UPDATE ENTITY %@ FROM ENTITY %@", self, entity);
  }
  return self;
}

-(NSString*)ifModifiedSinceValue
{
  NSDate* date = self.updatedAt;
  
  if (date == nil ||
      (self.requestedAt != nil && [self.requestedAt timeIntervalSinceDate:date] >= 1.0)) {  // has been requested later
    date = self.requestedAt;
  }
  
  if (date == nil) {
    return nil;
  }

  return [[AWEDateUtil sharedDateUtil] dateToHeader:date];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<AWEEntity<-%@ : uid: %@ createdAt: %@ updatedAt: %@> requestedAt: %@>", [self class], self.uid, self.createdAt, self.updatedAt, self.requestedAt];
}

#pragma mark - Managing Attribute Hashes


+(NSMutableDictionary*)managers:(Class)clss
{
  static NSMutableDictionary* managers;
  if (!managers) {
    managers = [NSMutableDictionary new];
  }
  return managers;
}



+(NSMutableDictionary*)attributeHashesForClass:(Class)clss
{
  static NSMutableDictionary* attributeHashes;
  if (!attributeHashes) {
    attributeHashes = [NSMutableDictionary new];
  }
  
  NSMutableDictionary* classSpecificHash = [attributeHashes objectForKey:NSStringFromClass(clss)];
  
  if (!classSpecificHash) {
    classSpecificHash = [NSMutableDictionary dictionary];
    [attributeHashes setObject:classSpecificHash forKey:NSStringFromClass(clss)];
  }
  return classSpecificHash;
}

+(NSMutableDictionary*)attributeHashes
{
  NSMutableDictionary* classSpecificHash = [self attributeHashesForClass:[self class]];
  return classSpecificHash ;
}

+(AWEAttributeHash*)createHashForAttribute:(NSString *)attribute
{
  AWEAttributeHash* hash = [[self attributeHashes] objectForKey:attribute];
  if (!hash) { // only create a new hash, in case it hasn't been created before
    hash = [[AWEAttributeHash alloc] initWithAttribute:attribute];
    [[self attributeHashes] setObject:hash forKey:attribute];
  }
  return hash;
}

@end





