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
#import "GLGResponseCodes.h"
#import "GLGIRCBroker.h"
#import "GLGTabView.h"
#import "IRCServer.h"

@interface GLGChatView : NSView <GLGBrokerDelegate, NSWindowDelegate, NSTextViewDelegate> {
    GLGResponseCodes *responseTable;
    NSWindow *window;

    NSMutableArray *brokers;

    NSScrollView *scrollview;
    GLGChatTextField *input;

    GLGTabView *tabView;
    NSString *currentNick;
    NSString *currentChannel;
    NSMutableDictionary *chatlogs;
}

@property id <GLGConnectionView> connectView;

- (id) initWithWindow:(NSWindow *) _window;
- (void) connectToServer:(IRCServer *) server;
@end

