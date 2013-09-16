//
//  GLGNewServer.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGChatView.h"
#import "GLGConnectionView.h"
#import "GLGDefaultValueTextField.h"

@class GLGChatView;

@interface GLGNewServer : NSView <GLGConnectionView> {
    GLGDefaultValueTextField *hostname;
    GLGDefaultValueTextField *port;
    GLGDefaultValueTextField *username;
    NSSecureTextField *password;
    GLGDefaultValueTextField *channels;
    NSButton *ssl;
    BOOL useSSL;

    GLGChatView *chatView;
}

- (id) initWithSuperView:(NSView*) superview;
- (void) shouldClose;

@end
