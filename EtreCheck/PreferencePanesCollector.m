/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "PreferencePanesCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"

// Collect 3rd party preference panes.
@implementation PreferencePanesCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"preferencepanes";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking preference panes", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPPrefPaneDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * items =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([items count])
        {
        [self.result appendAttributedString: [self buildTitle]];
        
        NSUInteger count = 0;
        
        for(NSDictionary * item in items)
          if([self printPreferencePaneInformation: item])
            ++count;
          
        if(!count)
          [self.result
            appendString: NSLocalizedString(@"    None\n", NULL)];
          
        [self.result appendCR];
        }
      }
    }
    
  [subProcess release];
    
  dispatch_semaphore_signal(self.complete);
  }

// Print information for a preference pane.
// Return YES if this is a 3rd party preference pane.
- (bool) printPreferencePaneInformation: (NSDictionary *) item
  {
  NSString * name = [item objectForKey: @"_name"];
  NSString * support = [item objectForKey: @"spprefpane_support"];
  NSString * bundleID =
    [item objectForKey: @"spprefpane_identifier"];
  NSString * path = [item objectForKey: @"spprefpane_bundlePath"];

  if([support isEqualToString: @"spprefpane_support_3rdParty"])
    {
    [self.result
      appendString: [NSString stringWithFormat: @"    %@ ", name]];
      
    NSAttributedString * supportLink =
      [self getSupportURL: name bundleID: bundleID];
    
    [self appendModificationDate: path];
    
    if(supportLink)
      [self.result appendAttributedString: supportLink];
      
    [self.result appendString: @"\n"];
    
    return YES;
    }
    
  return NO;
  }

// Append the modification date.
- (void) appendModificationDate: (NSString *) path
  {
  NSDate * modificationDate = [Utilities modificationDate: path];
    
  if(modificationDate)
    {
    NSString * modificationDateString =
      [Utilities dateAsString: modificationDate format: @"yyyy-MM-dd"];
    
    if(modificationDateString)
      [self.result
        appendString:
          [NSString stringWithFormat: @"(%@)", modificationDateString]];
    }
  }

@end
