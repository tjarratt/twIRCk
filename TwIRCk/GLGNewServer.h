//
//  GLGNewServer.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGChatView.h"

@interface GLGNewServer : NSView <GLGConnectionView> {
    NSTextField *hostname;
    NSTextField *port;
    NSTextField *username;
    NSSecureTextField *password;
    NSTextField *channels;

    GLGChatView *chatView;
}

- (id) initWithSuperView:(NSView*) superview;
- (void) shouldClose;

@end
