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

        input = [[GLGChatTextField alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, 50)];
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

        currentChannel = nil;
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
        NSLog(NSLocalizedString(@"big trouble in little IRC client", @"writeStreamFailure"));
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

- (void) connectToServer: (NSString *) hostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL
            withChannels:(NSArray *) channels {
    [self connectToServer:hostname onPort:port withUsername:username withPassword:password useSSL:useSSL];
    [channels enumerateObjectsUsingBlock:^(NSString *chan, NSUInteger index, BOOL *stop) {
        [self joinChannel:chan];
    }];
}

- (void) joinChannel:(NSString *) channel {
    [writer addCommand:[@"JOIN #" stringByAppendingString:channel]];
}

- (void) didConnectToHost:(NSString *) host {
    [connectView shouldClose];
}

- (void) receivedString:(NSString *) string {
    [chatlog setEditable:YES];
    [chatlog setSelectedRange:NSMakeRange([[chatlog textStorage] length], 0)];
    [chatlog insertText:string];
    [chatlog setEditable:NO];
}

- (void) didSubmitText {
    NSString *string = [input stringValue];
    if ([string isEqualToString:@""]) { return; }

    NSString *message;
    NSString *command;
    if ([[string substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"] ) {
        NSUInteger length = [string length];
        NSString *substring = [string substringWithRange:NSMakeRange(1, length - 1)];
        NSArray *parts = [substring componentsSeparatedByString:@" "];
        command = [[parts objectAtIndex:0] lowercaseString];

        if ([command isEqualToString:@"join"]) {
            NSString *channel = [[parts objectAtIndex:1] lowercaseString];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];
            message = [NSString stringWithFormat:@"JOIN #%@ %@", channel, remainder];

            currentChannel = [@"#" stringByAppendingString:channel];
        }
        else if ([command isEqualToString:@"part"]) {
            NSString *channel = [[parts objectAtIndex:1] lowercaseString];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];
            message = [NSString stringWithFormat:@"PART #%@ %@", channel, remainder];

            currentChannel = nil;
        }
        else if ([command isEqualToString:@"msg"] || [command isEqualToString:@"whisper"]) {
            NSString *whom = [parts objectAtIndex:1];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];
            message = [NSString stringWithFormat:@"PRIVMSG %@ :%@", whom, remainder];
        }
        else if ([command isEqualToString:@"who"]) {
            // TODO : emit a message for each of the names listed
            NSString *whom = [parts objectAtIndex:1];
            message = [@"WHO " stringByAppendingString:whom];
        }
    }
    else if (currentChannel) {
        message = [NSString stringWithFormat:@"PRIVMSG %@ :%@", currentChannel, string];
    }
    else {
        message = string;
    }


    [writer addCommand:message];
    [self receivedString:[string stringByAppendingString:@"\n"]];
    [input clearTextField];
}

@end
