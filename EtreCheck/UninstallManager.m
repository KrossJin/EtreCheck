/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "UninstallManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "LaunchdCollector.h"
#import "SubProcess.h"

@implementation UninstallManager

@synthesize window = myWindow;
@synthesize textView = myTextView;
@synthesize tableView = myTableView;
@dynamic canRemoveFiles;
@synthesize filesToRemove = myFilesToRemove;
@synthesize filesRemoved = myFilesRemoved;

// Can I remove files?
- (BOOL) canRemoveFiles
  {
  if([self.filesToRemove count] == 0)
    return NO;
    
  if([[Model model] oldEtreCheckVersion])
    return [self reportOldEtreCheckVersion];
    
  if(![[Model model] verifiedEtreCheckVersion])
    return [self reportUnverifiedEtreCheckVersion];

  if([[Model model] majorOSVersion] < kMountainLion)
    return [self warnBackup];
    
  if(![[Model model] backupExists])
    {
    NSNumber * override =
      [[NSUserDefaults standardUserDefaults]
        objectForKey: @"timemachineoverride"];
      
    if([override boolValue])
      return YES;
      
    [self reportNoBackup];
    
    return NO;
    }
    
  if([self needsAdministratorAuthorization])
    return [self requestAdministratorAuthorization];
    
  return YES;
  }

// Show the window.
- (void) show
  {
  }

// Show the window with content.
- (void) show: (NSString *) content
  {
  myFilesToRemove = [NSMutableArray new];
  
  [self.window makeKeyAndOrderFront: self];
  
  NSMutableAttributedString * details = [NSMutableAttributedString new];
  
  [details appendString: content];

  NSData * rtfData =
    [details
      RTFFromRange: NSMakeRange(0, [details length])
      documentAttributes: @{}];

  NSRange range = NSMakeRange(0, [[self.textView textStorage] length]);
  
  [self.textView replaceCharactersInRange: range withRTF: rtfData];
  [self.textView setFont: [NSFont systemFontOfSize: 13]];
  
  [self.textView setEditable: YES];
  [self.textView setEnabledTextCheckingTypes: NSTextCheckingTypeLink];
  [self.textView checkTextInDocument: nil];
  [self.textView setEditable: NO];

  [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];
    
  [details release];
  }

// Close the window.
- (IBAction) close: (id) sender
  {
  if(self.filesRemoved)
    [self suggestRestart];
  
  self.filesToRemove = nil;

  [self.window close];
  }

// Remove the files.
- (IBAction) removeFiles: (id) sender
  {
  [self uninstallItems: self.filesToRemove];
  }

// Uninstall an array of items.
- (void) uninstallItems: (NSMutableArray *) items
  {
  if(![self canRemoveFiles])
    return;
  
  NSMutableArray * launchdTasksToUnload = [NSMutableArray new];
  NSMutableArray * filesToDelete = [NSMutableArray new];

  for(NSDictionary * item in items)
    {
    NSString * path = [item objectForKey: kPath];
    
    NSDictionary * info = [item objectForKey: kLaunchdTask];
    
    if(info != nil)
      [launchdTasksToUnload addObject: info];
    else if(path != nil)
      [filesToDelete addObject: path];
    }
  
  [self reportFiles];
  [Utilities uninstallLaunchdTasks: launchdTasksToUnload];
  [Utilities deleteFiles: filesToDelete];
  
  [launchdTasksToUnload release];
  [filesToDelete release];
  
  [self verifyRemoveFiles: items];
  }

// Tell the user that EtreCheck is too old.
- (BOOL) reportOldEtreCheckVersion
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Outdated EtreCheck version!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"oldetrecheckversion", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];

  return NO;
  }

// Tell the user that the EtreCheck version is unverified.
- (BOOL) reportUnverifiedEtreCheckVersion
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Unverified EtreCheck version!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(@"unverifiedetrecheckversion", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];

  return NO;
  }

// Warn the user to make a backup.
- (BOOL) warnBackup
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Cannot verify Time Machine backup!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(@"cannotverifytimemachinebackup", NULL)];

  // This is the rightmost, first, default button.
  [alert
    addButtonWithTitle:
      NSLocalizedString(@"No, I don't have a backup", NULL)];

  [alert
    addButtonWithTitle: NSLocalizedString(@"Yes, I have a backup", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  return (result == NSAlertSecondButtonReturn);
  }

// Tell the user that EtreCheck won't delete files without a backup.
- (void) reportNoBackup
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"No Time Machine backup!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"notimemachinebackup", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];
  }

- (BOOL) needsAdministratorAuthorization
  {
  for(NSDictionary * info in self.filesToRemove)
    {
    NSString * path = [info objectForKey: kPath];
    
    if(path != nil)
      if(![[NSFileManager defaultManager] isDeletableFileAtPath: path])
        return YES;
    }
    
  return NO;
  }

- (BOOL) requestAdministratorAuthorization
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Password required!", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  NSString * message = NSLocalizedString(@"passwordrequired", NULL);
  
  [alert setInformativeText: message];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Yes", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"No", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  return (result == NSAlertFirstButtonReturn);
  }

// Verify removal of files.
- (void) verifyRemoveFiles: (NSMutableArray *) files
  {
  NSMutableArray * filesRemoved = [NSMutableArray new];
  NSMutableArray * filesRemaining = [NSMutableArray new];
    
  for(NSMutableDictionary * item in files)
    {
    NSString * path = [item objectForKey: kPath];
    
    if([path length])
      {
      BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: path];
      
      if(exists)
        [filesRemaining addObject: item];
      
      else
        {
        [item
          setObject: [NSNumber numberWithBool: YES] forKey: kFileDeleted];
        
        [filesRemoved addObject: path];
        
        [[[Model model] launchdFiles] removeObjectForKey: path];
        }
      }
    }
    
  if([filesRemaining count] > 0)
    [self reportDeletedFilesFailed: filesRemoved];
  else
    [self reportDeletedFiles: filesRemoved];

  [filesRemoved release];
  
  [files setArray: filesRemaining];
  
  [filesRemaining release];
  }

// Report the files.
- (void) reportFiles
  {
  NSMutableString * json = [NSMutableString string];
  
  [json appendString: @"{\"action\":\"addtoblacklist\","];
  [json appendString: @"\"files\":["];
  
  bool first = YES;
  
  for(NSDictionary * item in self.filesToRemove)
    {
    NSString * path = [item objectForKey: kPath];
    
    if([path length])
      {
      NSDictionary * info = [item objectForKey: kLaunchdTask];
      
      NSString * command = [info objectForKey: kCommand];
        
      path =
        [path stringByReplacingOccurrencesOfString: @"\"" withString: @"'"];
        
      NSString * name = [path lastPathComponent];
      
      if(!first)
        [json appendString: @","];
        
      first = NO;
      
      [json appendString: @"{"];
      
      [json appendFormat: @"\"name\":\"%@\",", name];
      [json appendFormat: @"\"path\":\"%@\",", path];
      [json appendFormat: @"\"cmd\":\"%@\"", command ? command : @""];
      
      [json appendString: @"}"];
      }
    }
    
  [json appendString: @"]}"];
  
  NSString * server = @"https://etrecheck.com/server/adware_detection.php";
  
  NSArray * args =
    @[
      @"-s",
      @"--data",
      json,
      server
    ];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/curl" arguments: args])
    {
    NSString * status =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
      
    if([status isEqualToString: @"OK"])
      {
      //NSLog(@"adware report successful");
      }
    else
      {
      //NSLog(@"adware report failed: %@", status);
      }
      
    [status release];
    }
    
  [subProcess release];
  }

// Suggest a restart.
- (void) suggestRestart
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Restart recommended", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  NSString * message = NSLocalizedString(@"restartrecommended", NULL);
  
  [alert setInformativeText: message];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Restart", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Restart later", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  if(result == NSAlertFirstButtonReturn)
    {
    if(![Utilities restart])
      [self restartFailed];
    }
  }

// Restart failed.
- (void) restartFailed
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Restart failed", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"restartfailed", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];
  
  [alert runModal];

  [alert release];
  }

// Report which files were deleted.
- (void) reportDeletedFiles: (NSArray *) filesRemoved
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      TTTLocalizedPluralString(
        [filesRemoved count], @"file deleted", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  [message appendString: NSLocalizedString(@"filesdeleted", NULL)];
  
  for(NSString * path in filesRemoved)
    [message appendFormat: @"%@\n", path];
    
  [alert setInformativeText: message];

  [alert runModal];
  
  [alert release];
  }

// Report which files were deleted.
- (void) reportDeletedFilesFailed: (NSArray *) filesRemoved
  {
  NSUInteger count = [filesRemoved count];
  
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: TTTLocalizedPluralString(count, @"file deleted", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  NSMutableString * message = [NSMutableString string];
  
  if(count == 0)
    {
    [message appendString: NSLocalizedString(@"nofilesdeleted", NULL)];

    [alert setInformativeText: message];
    
    [alert runModal];
    }
  else
    {
    [message appendString: NSLocalizedString(@"filesdeleted", NULL)];
  
    for(NSString * path in filesRemoved)
      [message appendFormat: @"%@\n", path];
      
    [message appendString: NSLocalizedString(@"filesdeletedfailed", NULL)];
    
    [alert setInformativeText: message];

    [alert runModal];
    }

  [alert release];
  }

@end
