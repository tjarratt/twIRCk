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

@protocol GLGConnectionView;

@interface GLGChatView : NSView <GLGReaderDelegate> {
    NSWindow *window;

    NSInputStream *inputStream;
    NSOutputStream *outputStream;

    GLGReadDelegate *reader;
    GLGWriteDelegate *writer;

    NSScrollView *scrollview;
    GLGChatTextField *input;
    NSTextView *chatlog;
}

@property id <GLGConnectionView> connectView;

- (id) initWithWindow:(NSWindow *) _window;
- (void) connectToServer: (NSString *) hostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL;
@end

@protocol GLGConnectionView <NSObject>

@required
- (void) shouldClose;

@end
