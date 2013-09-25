//
//  GLGNewServer.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "GLGChatView.h"
#import "GLGConnectionView.h"
#import "GLGDefaultValueTextField.h"
#import "GLGManagedObjectContext.h"
#import "GLGAppDelegate.h"

@class GLGChatView;

@interface GLGNewServer : NSView <GLGConnectionView> {
    GLGDefaultValueTextField *hostname;
    GLGDefaultValueTextField *port;
    GLGDefaultValueTextField *username;
    NSSecureTextField *password;
    GLGDefaultValueTextField *channels;
    NSButton *ssl;
    BOOL useSSL;
}

- (id) initWithSuperView:(NSView*) superview;
- (void) shouldClose;

@end
