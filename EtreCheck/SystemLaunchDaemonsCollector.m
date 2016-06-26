/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemLaunchDaemonsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"

@implementation SystemLaunchDaemonsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"systemlaunchdaemons";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Collect system launch daemons.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking system launch daemons", NULL)];

  // Make sure the base class is setup.
  [super collect];
  
  NSArray * args =
    @[
      @"/System/Library/LaunchDaemons",
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * files = [Utilities formatLines: subProcess.standardOutput];
    
    NSArray * plists = [self collectPropertyListFiles: files];
    
    [self printPropertyLists: plists];
    }
    
  [subProcess release];
    
  dispatch_semaphore_signal(self.complete);
  }
  
@end

