/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "Model.h"
#import "DiagnosticEvent.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import "NSString+Etresoft.h"
#import "XMLBuilder.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "Safari.h"
#import "Adware.h"

@implementation Model

@synthesize problem = myProblem;
@synthesize problemDescription = myProblemDescription;
@synthesize storageDevices = myStorageDevices;
@synthesize gpuErrors = myGPUErrors;
@synthesize logEntries = myLogEntries;
@synthesize applications = myApplications;
@synthesize physicalRAM = myPhysicalRAM;
@synthesize machineIcon = myMachineIcon;
@synthesize model = myModel;
@synthesize modelType = myModelType;
@synthesize modelMajorVersion = myModelMajorVersion;
@synthesize modelMinorVersion = myModelMinorVersion;
@synthesize serialCode = mySerialCode;
@synthesize diagnosticEvents = myDiagnosticEvents;
@synthesize launchd = myLaunchd;
@synthesize safari = mySafari;
@synthesize adware = myAdware;
@synthesize processes = myProcesses;
@synthesize adwareFound = myAdwareFound;
@synthesize unsignedFound = myUnsignedFound;
@synthesize computerName = myComputerName;
@synthesize hostName = myHostName;
@synthesize terminatedTasks = myTerminatedTasks;
@synthesize backupExists = myBackupExists;
@synthesize ignoreKnownAppleFailures = myIgnoreKnownAppleFailures;
@synthesize showSignatureFailures = myShowSignatureFailures;
@synthesize hideAppleTasks = myHideAppleTasks;
@synthesize oldEtreCheckVersion = myOldEtreCheckVersion;
@synthesize verifiedEtreCheckVersion = myVerifiedEtreCheckVersion;
@synthesize sip = mySIP;
@synthesize cleanupRequired = myCleanupRequired;
@synthesize notificationSPAMs = myNotificationSPAMs;
@synthesize pathsForUUIDs = myPathsForUUIDs;
@synthesize xml = myXMLBuilder;
@synthesize header = myXMLHeader;
@synthesize coreCount = myCoreCount;
@synthesize runningProcesses = myRunningProcesses;
@synthesize kernelApps = myKernelApps;
@synthesize inputDebugDirectory = myInputDebugDirectory;
@synthesize outputDebugDirectory = myOutputDebugDirectory;
  
// Get the model.
- (NSString *) model
  {
  return myModel;
  }
  
// Set the model.
- (void) setModel: (NSString *) model
  {
  if(![myModel isEqualToString: model])
    {
    [self willChangeValueForKey: @"model"];
    
    [myModel release];
    
    myModel = [model retain];
    
    [self didChangeValueForKey: @"model"];
    
    [self parseModel];
    }
  }
  
// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myLaunchd = [Launchd new];
    myStorageDevices = [NSMutableDictionary new];
    myDiagnosticEvents = [NSMutableDictionary new];
    mySafari = [Safari new];
    myAdware = [Adware new];
    myProcesses = [NSMutableSet new];
    myTerminatedTasks = [NSMutableArray new];
    myIgnoreKnownAppleFailures = YES;
    myShowSignatureFailures = NO;
    myHideAppleTasks = YES;
    myNotificationSPAMs = [NSMutableDictionary new];
    myPathsForUUIDs = [NSMutableDictionary new];
    myXMLBuilder = [XMLBuilder new];
    myXMLHeader = [XMLBuilder new];
    myRunningProcesses = [NSMutableDictionary new];
    myKernelApps = [NSMutableArray new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myLaunchd release];
  [myStorageDevices release];
  [myDiagnosticEvents release];
  [mySafari release];
  [myAdware release];
  [myProcesses release];
  [myTerminatedTasks release];
  [myNotificationSPAMs release];
  [myPathsForUUIDs release];
  [myXMLHeader release];
  [myXMLBuilder release];
  
  [myLogEntries release];
  [myApplications release];
  [myMachineIcon release];
  [myModel release];
  [myModelType release];
  [mySerialCode release];
  [myComputerName release];
  [myHostName release];
  [myGPUErrors release];
  [myProblem release];
  [myProblemDescription release];
  [myRunningProcesses release];
  [myKernelApps release];
  [myOutputDebugDirectory release];
  [myInputDebugDirectory release];
  
  [super dealloc];
  }

// Return true if there are log entries for a process.
- (bool) hasLogEntries: (NSString *) name
  {
  if(!name)
    return NO;
  
  __block bool matching = NO;
  __block NSMutableString * result = [NSMutableString string];
  
  [[self logEntries]
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        DiagnosticEvent * event = (DiagnosticEvent *)obj;
        
        if([event.details rangeOfString: name].location != NSNotFound)
          matching = YES;

        else
          {
          NSRange found =
            [event.details
              rangeOfCharacterFromSet:
                [NSCharacterSet whitespaceCharacterSet]];
            
          if(matching && (found.location == 0))
            matching = YES;
          else
            matching = NO;
          }
        
        if(matching)
          {
          [result appendString: event.details];
          [result appendString: @"\n"];
          }
        }];
    
  if([result length])
    {
    DiagnosticEvent * event = [DiagnosticEvent new];

    event.type = kLog;
    event.name = name;
    event.details = result;
      
    [self.diagnosticEvents setObject: event forKey: name];
    
    [event release];

    return YES;
    }

  return NO;
  }

// Collect log entires matching a date.
- (NSString *) logEntriesAround: (NSDate *) date
  {
  NSDate * startDate = [date dateByAddingTimeInterval: -60*5];
  NSDate * endDate = [date dateByAddingTimeInterval: 60*5];
  
  NSArray * lines = self.logEntries;
  
  __block NSMutableString * result = [NSMutableString string];
  
  [lines
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        DiagnosticEvent * event = (DiagnosticEvent *)obj;
        
        if([endDate compare: event.date] == NSOrderedAscending)
          *stop = YES;
        
        else if([startDate compare: event.date] == NSOrderedAscending)
          if([event.details length])
            {
            [result appendString: event.details];
            [result appendString: @"\n"];
            }
        }];
    
  return result;
  }

// Create a details URL for a query string.
- (NSAttributedString *) getDetailsURLFor: (NSString *) query
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  NSString * url =
    [NSString stringWithFormat: @"etrecheck://detail/%@", query];
  
  [urlString
    appendString: ECLocalizedString(@"[Details]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
  
  return [urlString autorelease];
  }

// Create an open URL for a file.
- (NSAttributedString *) getOpenURLFor: (NSString *) path
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  // Use UUIDs since these are sometimes printed in plain text.
  NSString * UUID = [self createUUIDForPath: path];
  
  NSString * url =
    [NSString stringWithFormat: @"etrecheck://open/%@", UUID];
  
  [urlString
    appendString: ECLocalizedString(@"[Open]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
  
  return [urlString autorelease];
  }

// Handle a task that takes too long to complete.
- (void) taskTerminated: (NSString *) program arguments: (NSArray *) args
  {
  NSMutableString * command = [NSMutableString string];
  
  [command appendString: program];
  
  for(NSString * argument in args)
    {
    [command appendString: @" "];
    [command appendString: argument];
    }
    
  [self.terminatedTasks addObject: command];
  }

// Is this a known Apple executable but not a shell script?
- (BOOL) isKnownAppleNonShellExecutable: (NSString *) path
  {
  if([path length])
    {
    NSString * signature = [Utilities checkAppleExecutable: path];
    
    if([signature isEqualToString: kSignatureApple])
      return YES;
      
    if([signature isEqualToString: kSignatureValid])
      return YES;      
    }
    
  return NO;
  }

// Save debug information to a temporary directory.
// Return the path to the temporary directory.
- (NSString *) saveDebugInformation
  {
  NSString * temporaryDirectory = NSTemporaryDirectory();
  NSString * UUID = [NSString UUID];
  self.outputDebugDirectory = 
    [temporaryDirectory stringByAppendingPathComponent: UUID];

  [[NSFileManager defaultManager] 
    createDirectoryAtPath: self.outputDebugDirectory 
    withIntermediateDirectories: YES 
    attributes: nil 
    error: NULL];
  
  BOOL isDirectory = NO;
  
  BOOL exists = 
    [[NSFileManager defaultManager] 
      fileExistsAtPath: self.outputDebugDirectory 
      isDirectory: & isDirectory];
    
  NSLog(@"Saving debug output to %@", self.outputDebugDirectory);
  
  if(exists)
    return self.outputDebugDirectory;
  
  NSLog(
    @"Failed to create output debug directory at %@", 
    self.outputDebugDirectory);
    
  return nil;
  }

// Load debug information from a directory.
- (void) loadDebugInformation: (NSString *) directory
  {
  self.inputDebugDirectory = directory;
  }
  
// A path for debug input for a given key.
- (NSString *) debugInputPath: (NSString *) key
  {
  return [self.inputDebugDirectory stringByAppendingPathComponent: key];
  }

// A path for debug input for a given key.
- (NSString *) debugOutputPath: (NSString *) key
  {
  return [self.outputDebugDirectory stringByAppendingPathComponent: key];
  }
  
// Associate a path with a UUID to hide it.
- (NSString *) createUUIDForPath: (NSString *) path
  {
  NSString * UUID = [NSString UUID];
  
  if([UUID length] > 0)
    [self.pathsForUUIDs setObject: path forKey: UUID];
    
  return UUID;
  }
   
// Parse the model code into parts.
- (void) parseModel
  {
  NSScanner * scanner = [[NSScanner alloc] initWithString: self.model];
  
  [self willChangeValueForKey: @"modelType"];
  
  [scanner 
    scanUpToCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet] 
    intoString: & myModelType];
  
  [self didChangeValueForKey: @"modelType"];
  
  [self willChangeValueForKey: @"modelMajorVersion"];
  
  [scanner scanInt: & myModelMajorVersion];
  
  [self didChangeValueForKey: @"modelMajorVersion"];
  
  [scanner scanString: @"," intoString: NULL];

  [self willChangeValueForKey: @"modelMinorVersion"];
  
  [scanner scanInt: & myModelMinorVersion];
  
  [self didChangeValueForKey: @"modelMinorVersion"];

  [scanner release];
  }
  
@end
