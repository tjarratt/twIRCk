//
//  GLGChatView.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGChatTextField.h"
#import "GLGConnectionView.h"
#import "GLGTabView.h"
#import "GLGChannelSidebar.h"
#import "GLGChatLogView.h"
#import "IRCServer.h"
#import "GLGOccupantDelegate.h"
#import "GLGChatViewDelegate.h"

@interface GLGChatView : NSView <NSWindowDelegate, GLGOccupantDelegate>

@property (readonly) NSWindow *superWindow;
@property (retain, readonly) GLGTabView *tabView;
@property (retain, readonly) GLGChannelSidebar *sidebar;
@property (retain, readonly) NSScrollView *scrollview;
@property (retain, readonly) GLGChatTextField *input;
@property (retain, readonly) GLGChatLogView *chatlogView;
@property (retain, readonly) id <GLGChatViewDelegate> controller;
@property (retain, readwrite) id <GLGConnectionView> connectView;

- (instancetype) initWithWindow:(NSWindow *) aWindow andDelegate:(id) delegate;

#pragma mark - Connection windows
- (void) connectToServer:(IRCServer *) server;
- (void) didConnectToHost:(NSString *) host;

#pragma mark - tabs
- (void) closeActiveTabOrWindow;

#pragma mark - chat logs
- (GLGChatLogView *) newChatlog;

- (IBAction) copy:(id) sender;
@end

