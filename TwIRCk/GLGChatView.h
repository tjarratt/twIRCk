//
//  GLGChatView.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGReadDelegate.h"
#import "GLGWriteDelegate.h"
#import "GLGChatTextField.h"
#import "GLGAppDelegate.h"
#import "GLGConnectionView.h"
#import "IRCServer.h"
#import "GLGTabView.h"

@class GLGAppDelegate;

@interface GLGChatView : NSView <GLGReaderDelegate> {
    NSWindow *window;

    NSInputStream *inputStream;
    NSOutputStream *outputStream;

    GLGReadDelegate *reader;
    GLGWriteDelegate *writer;

    NSScrollView *scrollview;
    GLGChatTextField *input;

    GLGTabView *tabView;
    NSString *currentChannel;
    NSMutableDictionary *chatlogs;
}

@property id <GLGConnectionView> connectView;

- (id) initWithWindow:(NSWindow *) _window;
- (void) connectToServer: (NSString *) hostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL;
- (void) connectToServer: (NSString *) hostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL
            withChannels:(NSArray *) channels;
- (void) connectToServer:(IRCServer *) server;
@end

