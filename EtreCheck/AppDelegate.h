/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>

@class SlideshowView;
@class DetailManager;
@class HelpManager;
@class AdwareManager;

@interface AppDelegate : NSObject
  <NSApplicationDelegate,
  NSUserNotificationCenterDelegate,
  NSToolbarDelegate,
  NSSharingServiceDelegate,
  NSSharingServicePickerDelegate>
  {
  NSWindow * window;
  NSWindow * myLogWindow;
  NSView * myAnimationView;
  NSView * myReportView;
  NSProgressIndicator * myProgress;
  NSProgressIndicator * mySpinner;
  NSProgressIndicator * myDockProgress;
  NSButton * myCancelButton;
  NSTextView * myStatusView;
  NSTextView * logView;
  NSAttributedString * myDisplayStatus;
  NSMutableAttributedString * log;
  double myNextProgressIncrement;
  NSTimer * myProgressTimer;
  SlideshowView * myMachineIcon;
  SlideshowView * myApplicationIcon;
  NSImageView * myMagnifyingGlass;
  NSImageView * myMagnifyingGlassShade;
  NSImageView * myFinderIcon;
  NSImageView * myDemonImage;
  NSImageView * myAgentImage;
  NSString * myCollectionStatus;
  NSWindow * myUserParametersPanel;
  
  NSView * myClipboardCopyToolbarItemView;
  NSButton * myClipboardCopyButton;
  NSView * myShareToolbarItemView;
  NSButton * myShareButton;
  NSView * myHelpToolbarItemView;
  NSButton * myHelpButton;
  NSImage * myHelpButtonImage;
  NSImage * myHelpButtonInactiveImage;
  NSView * myTextSizeToolbarItemView;
  NSButton * myTextSizeButton;
  NSUInteger myTextSize;
  NSToolbar * myToolbar;

  NSMutableDictionary * launchdStatus;
  NSMutableSet * appleLaunchd;
  
  DetailManager * myDetailManager;
  HelpManager * myHelpManager;
  AdwareManager * myAdwareManager;
  
  BOOL myReportAvailable;
  NSDate * myReportStartTime;
  
  NSWindow * myTOUPanel;
  NSTextView * myTOUView;
  NSButton * myAcceptTOUButton;
  BOOL myTOSAccepted;
  }
  
@property (retain) IBOutlet NSWindow * window;
@property (retain) IBOutlet NSWindow * logWindow;
@property (retain) IBOutlet NSView * animationView;
@property (retain) IBOutlet NSView * reportView;
@property (retain) IBOutlet NSProgressIndicator * progress;
@property (retain) IBOutlet NSProgressIndicator * spinner;
@property (retain) IBOutlet NSProgressIndicator * dockProgress;
@property (retain) IBOutlet NSButton * cancelButton;
@property (retain) IBOutlet NSTextView * statusView;
@property (retain) IBOutlet NSTextView * logView;
@property (retain) NSAttributedString * displayStatus;
@property (retain) NSMutableAttributedString * log;
@property (assign) double nextProgressIncrement;
@property (retain) NSTimer * progressTimer;
@property (retain) IBOutlet SlideshowView * machineIcon;
@property (retain) IBOutlet SlideshowView * applicationIcon;
@property (retain) IBOutlet NSImageView * magnifyingGlass;
@property (retain) IBOutlet NSImageView * magnifyingGlassShade;
@property (retain) IBOutlet NSImageView * finderIcon;
@property (retain) IBOutlet NSImageView * demonImage;
@property (retain) IBOutlet NSImageView * agentImage;
@property (retain) NSString * collectionStatus;
@property (retain) IBOutlet NSWindow * userParametersPanel;
@property (retain) IBOutlet NSView * shareToolbarItemView;
@property (retain) IBOutlet NSButton * shareButton;
@property (retain) IBOutlet NSView * clipboardCopyToolbarItemView;
@property (retain) IBOutlet NSButton * clipboardCopyButton;
@property (retain) IBOutlet NSView * helpToolbarItemView;
@property (retain) IBOutlet NSButton * helpButton;
@property (retain) IBOutlet NSImage * helpButtonImage;
@property (retain) IBOutlet NSImage * helpButtonInactiveImage;
@property (retain) IBOutlet NSView * textSizeToolbarItemView;
@property (retain) IBOutlet NSButton * textSizeButton;
@property (assign) NSUInteger textSize;
@property (retain) IBOutlet NSToolbar * toolbar;
@property (retain) IBOutlet DetailManager * detailManager;
@property (retain) IBOutlet HelpManager * helpManager;
@property (retain) IBOutlet AdwareManager * adwareManager;
@property (assign) BOOL reportAvailable;
@property (retain) NSDate * reportStartTime;
@property (retain) IBOutlet NSWindow * TOUPanel;
@property (retain) IBOutlet NSTextView * TOUView;
@property (retain) IBOutlet NSButton * acceptTOUButton;
@property (assign) BOOL TOSAccepted;

// Ignore known Apple failures.
@property (assign) bool ignoreKnownAppleFailures;

// Check Apple signatures.
@property (assign) bool checkAppleSignatures;

// Hide Apple tasks.
@property (assign) bool hideAppleTasks;

// Start the report.
- (IBAction) start: (id) sender;

// Cancel the report.
- (IBAction) cancel: (id) sender;

// Copy the report to the clipboard.
- (IBAction) copyToClipboard: (id) sender;

// Show a custom about panel.
- (IBAction) showAbout: (id) sender;

// Go to the Etresoft web site.
- (IBAction) gotoEtresoft: (id) sender;

// Display more info.
- (IBAction) moreInfo: (id) sender;

// Show the log window.
- (IBAction) showLog: (id) sender;

// Show the EtreCheck window.
- (IBAction) showEtreCheck: (id) sender;

// Confirm cancel.
- (IBAction) confirmCancel: (id) sender;

// Save the EtreCheck report.
- (IBAction) saveReport: (id) sender;

// Share the EtreCheck report.
- (IBAction) shareReport: (id) sender;

// Show Terms of Use agreement for a standard copy.
- (IBAction) showTOUAgreementCopy: (id) sender;

// Show Terms of Use agreement for a copy report.
- (IBAction) showTOUAgreementCopyAll: (id) sender;

// Decline the Terms of Use.
- (IBAction) declineTOS: (id) sender;

@end
