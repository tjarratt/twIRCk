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

@interface GLGChatView : NSView <GLGReaderDelegate> {
    NSWindow *window;

    NSInputStream *inputStream;
    NSOutputStream *outputStream;

    GLGReadDelegate *reader;
    GLGWriteDelegate *writer;
}

- (id) initWithWindow:(NSWindow *) _window;
- (void) connectToServer: (NSString *) hostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL;
@end
