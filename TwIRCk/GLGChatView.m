//
//  GLGChatView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGChatView.h"

@implementation GLGChatView

@synthesize connectView;

- (id) initWithWindow:(NSWindow *) _window {
    if (self = [super init]) {
        window = _window;
        NSView *content = [window contentView];
        NSRect frame = [content frame];
        [self setFrame:frame];

        NSRect chatRect = NSMakeRect(0, 50, frame.size.width, frame.size.height - 50);
        scrollview = [[NSScrollView alloc] initWithFrame:chatRect];
        NSSize contentSize = [scrollview contentSize];

        [scrollview setBorderType:NSNoBorder];
        [scrollview setHasVerticalScroller:YES];
        [scrollview setHasHorizontalScroller:NO];
        [scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollview setScrollsDynamically:YES];

        input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, 50)];
        [input setTarget:self];
        [input setAction:@selector(didSubmitText)];

        chatlog = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
        [chatlog setMinSize:NSMakeSize(0, contentSize.height)];
        [chatlog setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [chatlog setVerticallyResizable:YES];
        [chatlog setHorizontallyResizable:NO];
        [chatlog setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [[chatlog textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[chatlog textContainer] setWidthTracksTextView:YES];

        [scrollview setDocumentView:chatlog];
        [window makeFirstResponder:input];
        [window makeKeyAndOrderFront:nil];

        [self addSubview:input];
        [self addSubview:scrollview];
    }

    return self;
}

- (void) connectToServer: (NSString *) hostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL {


    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef) hostname, port, &readStream, &writeStream);

    if(!CFWriteStreamOpen(writeStream)) {
        // validation, or maybe not connected?
        NSLog(@"big trouble in little IRC client");
        return;
    }

    inputStream = (__bridge_transfer NSInputStream *) readStream;
    reader = [[GLGReadDelegate alloc] init];
    [reader setDelegate:self];
    [inputStream setDelegate:reader];

    outputStream = (__bridge_transfer NSOutputStream *) writeStream;
    writer = [[GLGWriteDelegate alloc] init];
    [writer setWriteStream:outputStream];
    [outputStream setDelegate:writer];

    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    if (useSSL) {
        [inputStream setProperty:NSStreamSocketSecurityLevelTLSv1 forKey:NSStreamSocketSecurityLevelKey];
    }

    [inputStream open];
    [outputStream open];

    if ([username length] > 0 && [password length] > 0) {
        [writer addCommand:[@"PASS " stringByAppendingString:password]];
        [writer addCommand:[@"NICK " stringByAppendingString:username]];
        [writer addCommand:[NSString stringWithFormat:@"USER %@ 8 * %@", username, username]];
    }
}

- (void) didConnectToHost:(NSString *) host {
    [connectView shouldClose];
}

- (void) receivedString:(NSString *) string {
    [chatlog setEditable:YES];
    [chatlog insertText:string];
    [chatlog setEditable:NO];
}

- (void) didSubmitText {
    [writer addCommand:[input stringValue]];
    [self receivedString:[[input stringValue] stringByAppendingString:@"\n"]];
    [input setStringValue:@""];
}

@end
