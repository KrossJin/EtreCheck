/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemLaunchAgentsCollector.h"
#import "Utilities.h"

@implementation SystemLaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"systemlaunchagents";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Collect system launch agents.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking system launch agents", NULL)];
 
  // Make sure the base class is setup.
  [super collect];
  
  NSArray * args =
    @[
      @"/System/Library/LaunchAgents",
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  NSData * result = [Utilities execute: @"/usr/bin/find" arguments: args];
  
  NSArray * files = [Utilities formatLines: result];
  
  [self printPropertyListFiles: files];
    
  dispatch_semaphore_signal(self.complete);
  }
  
@end
