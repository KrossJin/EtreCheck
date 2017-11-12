/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"
#import "ByteCountFormatter.h"

@interface StorageDevice : PrintableItem
  {
  // The /dev/* device identifier.
  NSString * myIdentifier;
  
  // The volume name.
  NSString * myName;
  
  // The raw size of the device.
  NSUInteger mySize;
  
  // The type of storage device.
  NSString * myType;
  
  // Errors.
  NSMutableArray * myErrors;
  
  // RAID set UUID.
  NSString * myRAIDSetUUID;
  
  // RAID set members.
  NSArray * myRAIDSetMembers;
  
  // A byte count formatter.
  ByteCountFormatter * myByteCountFormatter;
  }

// The /dev/* device identifier.
@property (retain, readonly, nonnull) NSString * identifier;

// The device name.
@property (retain, nullable) NSString * name;

// The raw size of the device.
@property (assign) NSUInteger size;

// The type of storage device.
@property (retain, nullable) NSString * type;

// Errors.
@property (retain, readonly, nonnull) NSMutableArray * errors;

// RAID set UUID.
@property (retain, nullable) NSString * RAIDSetUUID;

// RAID set members.
@property (retain, nullable) NSArray * RAIDSetMembers;

// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist;

// Format a number into a byte count string.
- (nonnull NSString *) byteCountString: (NSUInteger) value;

@end