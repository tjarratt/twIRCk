//
//  GLGAppDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CFNetwork/CFSocketStream.h> 
#import "GLGManagedObjectContext.h"
#import "GLGNewServerView.h"
#import "IRCServer.h"
#import "GLGLogger.h"
#import "GLGPreferencesView.h"
#import "GLGPreferencesController.h"

@interface GLGAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (retain) GLGChatView *chatView;
@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSWindowController *windowController;

- (IBAction)closeActiveWindow:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)showPreferences:(id)sender;

@end
