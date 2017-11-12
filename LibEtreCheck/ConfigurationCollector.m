/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "ConfigurationCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"

#define kRootlessPrefix @"System Integrity Protection status:"

// Collect changes to config files like /etc/sysctl.conf and /etc/hosts.
@implementation ConfigurationCollector

@synthesize configFiles = myConfigFiles;
@synthesize modifiedFiles = myModifiedFiles;
@synthesize modifications = myModifications;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"configurationfiles"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.configFiles = nil;
  self.modifiedFiles = nil;
  self.modifications = nil;
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollect
  {
  [self checkExistingConfigFiles];
  
  bool haveChanges = [self.configFiles count] > 0;

  [self checkModifiedConfigFiles];

  if([self.modifiedFiles count] > 0)
    haveChanges = YES;
    
  [self checkOtherModifications];
  
  if([self.modifications count] > 0)
    haveChanges = YES;
  
  // See if /etc/hosts has any changes or is corrupt.
  bool corrupt = NO;
  
  NSUInteger hostsCount = [self hostsStatus: & corrupt];
  
  if(hostsCount || corrupt)
    haveChanges = YES;
    
  // Only print this section if I have changes.
  if(haveChanges)
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    [self printModifiedFiles];

    [self printUnexpectedFiles];
      
    // Print changes to /etc/hosts.
    [self printHostsStatus: corrupt count: hostsCount];
    
    [self printOtherModifications];
      
    [self.result appendCR];
    }    
  }

// Find modified configuration files.
- (void) checkModifiedConfigFiles
  {
  NSMutableArray * files = [NSMutableArray array];
  
  NSFileManager * fileManager = [NSFileManager defaultManager];
  
  NSDictionary * attributes =
    [fileManager attributesOfItemAtPath: @"/etc/sudoers" error: NULL];
  
  // See if /etc/sudoers has been modified.
  if(attributes)
    {
    int version = [[OSVersion shared] major];
    unsigned long long expectedSize = attributes.fileSize;
    
    switch(version)
      {
      case kSnowLeopard:
        expectedSize = 1242;
        break;
      case kLion:
        expectedSize = 1275;
        break;
      case kMountainLion:
        expectedSize = 1275;
        break;
      case kMavericks:
        expectedSize = 1275;
        break;
      case kYosemite:
        expectedSize = 1275;
        break;
      case kElCapitan:
        expectedSize = 2299;
        break;
      case kSierra:
        expectedSize = 1563;
        break;
      case kHighSierra:
        expectedSize = 1563;
        break;
      }
    
    if(self.simulating)
      expectedSize = 42;
      
    // All the beta testers have an El Capitan file.
    // I guess this is permanently broken.
    if(!self.simulating && [[Model model] ignoreKnownAppleFailures])
      if((version >= kYosemite) && (attributes.fileSize != expectedSize))
        switch(version)
          {
          // Just accept anything recent.
          case kYosemite:
          case kElCapitan:
          case kSierra:
          case kHighSierra:
            if(attributes.fileSize == 1242)
              expectedSize = attributes.fileSize;
            else if(attributes.fileSize == 1275)
              expectedSize = attributes.fileSize;
            else if(attributes.fileSize == 2299)
              expectedSize = attributes.fileSize;
            break;
          }

    if(attributes.fileSize != expectedSize)
      {
      [self.model startElement: @"unexpectedsudoerssize"];
      
      [self.model 
        addElement: @"size" 
        unsignedLongLongValue: attributes.fileSize 
        attributes: 
          [NSDictionary dictionaryWithObjectsAndKeys:@"B", @"units", nil]];

      [self.model 
        addElement: @"expectedsize" 
        unsignedLongLongValue: expectedSize 
        attributes: 
          [NSDictionary dictionaryWithObjectsAndKeys:@"B", @"units", nil]];
          
      [self.model endElement: @"unexpectedsudoerssize"];
          
      [files
        addObject:
          [NSString
            stringWithFormat:
              ECLocalizedString(
                @"    %@, File size %llu but expected %llu\n"),
              @"/etc/sudoers",
              attributes.fileSize,
              expectedSize]];
      }
    }
  
  self.modifiedFiles = files;
  }

// Find existing configuration files.
- (void) checkExistingConfigFiles
  {
  NSMutableArray * files = [NSMutableArray array];
  
  NSFileManager * fileManager = [NSFileManager defaultManager];
  
  BOOL etcsysctlExists = 
    [fileManager fileExistsAtPath: @"/etc/sysctl.conf"];
  
  BOOL etclaunchdExists = 
    [fileManager fileExistsAtPath: @"/etc/launchd.conf"];
  
  // See if /etc/sysctl.conf exists.
  if(etcsysctlExists || self.simulating)
    {
    [self.model addElement: @"etcsysctlconfexists" boolValue: YES];
    
    [files addObject: @"/etc/sysctl.conf"];
    }
    
  // See if /etc/launchd.conf exists.
  if(etclaunchdExists || self.simulating)
    {
    [self.model addElement: @"etclaunchdconfexists" boolValue: YES];

    [files addObject: @"/etc/launchd.conf"];
    }
    
  self.configFiles = files;
  }

// Check for other modifications.
- (void) checkOtherModifications
  {
  NSMutableArray * otherModificiations = [NSMutableArray array];
  
  if([[OSVersion shared] major] >= kElCapitan)
    {
    NSString * status = [self checkRootlessStatus];
  
    if(self.simulating)
      status = @"Simulated";
      
    if([status isEqualToString: @"enabled"])
      [[Model model] setSIP: YES];
    else
      {
      [self.model addElement: @"SIP" value: status];

      [otherModificiations
        addObject:
          [[[NSMutableAttributedString alloc]
            initWithString:
              [NSString
                stringWithFormat:
                  ECLocalizedString(
                    @"System Integrity Protection status: %@"),
                  status]
            attributes:
              [NSDictionary
                dictionaryWithObjectsAndKeys:
                  [NSColor redColor], NSForegroundColorAttributeName, nil]]
            autorelease]];
      }
    }
    
  self.modifications = otherModificiations;
  }

// Check System Integrity Protection.
- (NSString *) checkRootlessStatus
  {
  bool csrutilExists =
    [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/bin/csrutil"];
    
  if(!csrutilExists)
    return ECLocalizedString(@"/usr/bin/csrutil missing");
    
  // Now consolidate destination information.
  NSArray * args =
    @[
      @"status",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/csrutil" arguments: args])
    {
    NSString * status =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
    
    NSString * result = status;
    
    NSScanner * scanner = [NSScanner scannerWithString: status];
    
    if([scanner scanString: kRootlessPrefix intoString: NULL])
      [scanner scanUpToString: @"." intoString: & result];
      
    if(![result length])
      result =
        [NSString
          stringWithFormat:
            ECLocalizedString(@"/usr/bin/csrutil returned \"%@\""), status];
    
    [status release];
    
    return result;
    }
    
  return ECLocalizedString(@"missing");
  }

// Collect the number of changes to /etc/hosts and its status.
- (NSUInteger) hostsStatus: (bool *) corrupt
  {
  NSUInteger count = 0;
  
  NSString * hosts =
    [NSString
      stringWithContentsOfFile:
        @"/etc/hosts" encoding: NSUTF8StringEncoding error: nil];
        //@"/Users/jdaniel/Downloads/hosts.wrong.txt" encoding: NSUTF8StringEncoding error: nil];
  
  NSArray * lines = [hosts componentsSeparatedByString: @"\n"];
  
  int localhostCount = 0;
  int broadcasthostCount = 0;
  
  for(NSString * line in lines)
    {
    if(![line length])
      continue;
      
    if([line hasPrefix: @"#"])
      continue;
      
    NSString * hostname = [self readHostname: line];
      
    if(corrupt && !hostname)
      *corrupt = YES;
      
    if([hostname length] < 1)
      continue;
      
    if([hostname isEqualToString: @"localhost"])
      {
      ++localhostCount;
      continue;
      }
      
    if([hostname isEqualToString: @"broadcasthost"])
      {
      ++broadcasthostCount;
      continue;
      }
      
    ++count;
    }
    
  if(corrupt && (localhostCount < 1))
    *corrupt = YES;
    
  if(corrupt && (broadcasthostCount < 1))
    *corrupt = YES;
    
  if(self.simulating)
    {
    if(corrupt != NULL)
      *corrupt = YES;
    
    count = 1024;
    }
    
  return count;
  }

// Read a name from /etc/hosts.
// Return nil if the name is invalid or the file is corrupt.
- (NSString *) readHostname: (NSString *) line
  {
  NSString * trimmedLine =
    [line
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  if([trimmedLine hasPrefix: @"#"])
    return @"";
    
  if([trimmedLine length] < 1)
    return @"";
    
  NSScanner * scanner = [NSScanner scannerWithString: trimmedLine];
  
  NSString * address = nil;
  
  bool scanned =
    [scanner
      scanUpToCharactersFromSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]
      intoString: & address];
  
  if(!scanned)
    return nil;
    
  NSString * name = nil;

  scanned =
    [scanner
      scanUpToCharactersFromSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]
      intoString: & name];

  if(!scanned)
    return nil;
    
  return name;
  }

// Print modified files.
- (void) printModifiedFiles
  {
  // Print modified configFiles.
  for(NSString * modifiedFile in self.modifiedFiles)
    [self.result
      appendString: modifiedFile
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  }

// Print unexpected files.
- (void) printUnexpectedFiles
  {
  // Print existing configFiles.
  for(NSString * configFile in self.configFiles)
    [self.result
      appendString:
        [NSString stringWithFormat:
          ECLocalizedString(@"    %@ - File exists but not expected\n"),
          configFile]];
  }

// Print other modifications.
- (void) printOtherModifications
  {
  // Print existing configFiles.
  for(NSAttributedString * modification in self.modifications)
    {
    [self.result appendString: @"    "];
    
    [self.result appendAttributedString: modification];
    
    [self.result appendString: @"\n"];
    }
  }

// Print the status of the hosts file.
- (void) printHostsStatus: (bool) corrupt count: (NSUInteger) count
  {
  NSString * corruptString = @"";
  
  if(corrupt)
    corruptString = ECLocalizedString(@" - Corrupt!");
    
  NSString * countString = @"";
  
  if(count > 0)
    countString =
      [NSString 
        stringWithFormat: ECLocalizedString(@" - Count: %d"), count];
    
  if((count > 10) || corrupt)
    {
    [self.model addElement: @"hostscount" unsignedIntegerValue: count];
    [self.model addElement: @"hostscorrupt" boolValue: YES];
    
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    /etc/hosts%@%@\n", countString, corruptString]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    }
  else if(count > 0)
    {
    [self.model addElement: @"hostscount" unsignedIntegerValue: count];

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    /etc/hosts%@%@\n", countString, corruptString]];
    }
  }

@end