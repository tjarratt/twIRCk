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
#import "GLGNewServer.h"
#import "GLGChatViewController.h"
#import "IRCServer.h"
#import "GLGLogger.h"

@interface GLGAppDelegate : NSObject <NSApplicationDelegate> {
    BOOL serverWindowIsVisible;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, strong, readonly) GLGChatViewController *controller;
@property (strong, nonatomic) NSWindowController *windowController;

- (IBAction)closeActiveWindow:(id)sender;
- (IBAction)copy:(id)sender;
- (void) didCreateChatViewController:(GLGChatViewController *) controller;

@end
