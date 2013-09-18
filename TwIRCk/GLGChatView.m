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

- (id) initWithWindow:(NSWindow *) theWindow {
    if (self = [super init]) {
        window = theWindow;
        NSView *content = [window contentView];
        NSRect frame = [content frame];
        [self setFrame:frame];

        tabView = [[GLGTabView alloc] initWithFrame:NSMakeRect(0, frame.size.height - 30, frame.size.width, 30)];
        [self addSubview:tabView];

        NSRect chatRect = NSMakeRect(0, 50, frame.size.width, frame.size.height - 80);
        scrollview = [[NSScrollView alloc] initWithFrame:chatRect];

        [scrollview setBorderType:NSNoBorder];
        [scrollview setHasVerticalScroller:YES];
        [scrollview setHasHorizontalScroller:NO];
        [scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollview setScrollsDynamically:YES];

        input = [[GLGChatTextField alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, 50)];
        [input setTarget:self];
        [input setAction:@selector(didSubmitText)];

        chatlogs = [[NSMutableDictionary alloc] init];

        [window makeFirstResponder:input];
        [window makeKeyAndOrderFront:nil];

        [self addSubview:input];
        [self addSubview:scrollview];

        currentChannel = nil;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTabSelection:) name:@"did_switch_tabs" object:nil];
    }

    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - handling chat logs
- (NSTextView *) newChatlog {
    NSSize contentSize = [scrollview contentSize];
    NSTextView *textview = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
    [textview setMinSize:NSMakeSize(0, contentSize.height)];
    [textview setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [textview setVerticallyResizable:YES];
    [textview setHorizontallyResizable:NO];
    [textview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[textview textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
    [[textview textContainer] setWidthTracksTextView:YES];

    return textview;
}

- (NSTextView *) currentChatlogTextView {
    return [chatlogs objectForKey:currentChannel];
}

#pragma mark - NSNotificationCenter actions
- (void) handleTabSelection:(NSNotification *) notification {
    NSString *newChannel = [notification object];
    NSTextView *chat = [chatlogs objectForKey:newChannel];

    assert( chat != nil );

    currentChannel = newChannel;
    [scrollview setDocumentView:chat];
}

#pragma mark - connection methods
- (void) connectToServer: (NSString *) hostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL {

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef) hostname, port, &readStream, &writeStream);

    if(!CFWriteStreamOpen(writeStream)) {
        // failed validation, or maybe not connected to the internet
        return NSLog(NSLocalizedString(@"big trouble in little IRC client", @"writeStreamFailure"));
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

    if ([username length] > 0) {
        [writer addCommand:[@"PASS " stringByAppendingString:password]];
        [writer addCommand:[@"NICK " stringByAppendingString:username]];
        [writer addCommand:[NSString stringWithFormat:@"USER %@ 8 * %@", username, username]];
    }

    [tabView addItem:hostname];
    NSTextView *newLog = [self newChatlog];
    [chatlogs setValue:newLog forKey:hostname];

    if ([tabView count] == 1) {
        currentChannel = hostname;
        [scrollview setDocumentView:newLog];
    }
}

- (void) connectToServer: (NSString *) hostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL
            withChannels:(NSArray *) channels {
    // delegates to simpler method, then calls joinChannel for each chan
    [self connectToServer:hostname onPort:port withUsername:username withPassword:password useSSL:useSSL];
    [channels enumerateObjectsUsingBlock:^(NSString *chan, NSUInteger index, BOOL *stop) {
        [self joinChannel:chan];
    }];
}

- (void) connectToServer:(IRCServer *) server {
    [self connectToServer:server.hostname
                   onPort:[server.port intValue]
             withUsername:server.username
             withPassword:server.password
                   useSSL:server.useSSL];
}

#pragma mark - needs to be refactored out of this class
- (BOOL) handledPing:(NSString *) maybePing {
    NSError *error;
    NSRegularExpression *pingRegex = [NSRegularExpression regularExpressionWithPattern:@"^PING :([a-zA-Z.-]+)" options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"error creating ping regex: %@", [error localizedDescription]);
        NSLog(@"failure reason: %@", [error localizedFailureReason]);
        return NO;
    }

    NSArray *matches = [pingRegex matchesInString:maybePing options:0 range:NSMakeRange(0, maybePing.length)];
    if ([matches count] == 0) {
        return NO;
    }

    NSTextCheckingResult *result = [matches objectAtIndex:0];
    if ([result numberOfRanges] <= 1) {
        return NO;
    }

    NSString *hostname = [maybePing substringWithRange:[result rangeAtIndex:1]];
    if ([hostname length] > 0) {
        [writer addCommand:[@"PONG " stringByAppendingString:hostname]];
        return YES;
    }

    return NO;
}

#pragma mark - notifications
- (void) didConnectToHost:(NSString *) host {
    [connectView shouldClose];
}

- (void) receivedString:(NSString *) string inChannel:(NSString *) channel {
    NSTextView *log = [chatlogs objectForKey:channel];
    assert( log != nil );

    [log setEditable:YES];
    [log setSelectedRange:NSMakeRange([[log textStorage] length], 0)];
    [log insertText:string];
    [log setEditable:NO];
}

- (void) receivedString:(NSString *) string {
    if ([self handledPing:string]) {
        return NSLog(@"pong");
    }

    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^:([a-z.-]+) ([a-z0-9]+) (.+)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];

    if ([matches count] == 0) {
        return NSLog(@"looks like we got a boo boo: %@", string);
    }

    NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];
    NSString *theChannel = [string substringWithRange:[channelMatch rangeAtIndex:1]];
    NSString *theType = [string substringWithRange:[channelMatch rangeAtIndex:2]];
    NSString *theMessage = [string substringWithRange:[channelMatch rangeAtIndex:3]];

    // xxx: temporary workaround for freenode chat name
    // I'd like for this to be passed to *some class* as the real hostname or value for the channel
    // and then ChatView wouldn't know about a server until it was actually active
    NSArray *components = [theChannel componentsSeparatedByString:@"."];
    if (components.count == 3) {
        NSString *second = [components objectAtIndex:1];
        NSString *third = [components objectAtIndex:2];
        if ([second isEqualToString:@"freenode"] && [third isEqualToString:@"net"]) {
            theChannel = @"chat.freenode.net";
        }
    }

    [self receivedString:string inChannel:theChannel];
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

            currentChannel = channel;
            [self joinChannel:channel];
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
        else if ([command isEqualToString:@"me"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];
            message = [@"ACTION " stringByAppendingString:remainder];
        }
        else {
            message = string;
        }
    }
    else if (currentChannel) {
        message = [NSString stringWithFormat:@"PRIVMSG %@ :#%@", currentChannel, string];
    }
    else {
        message = string;
    }

    [writer addCommand:message];
    [input clearTextField];

    if (currentChannel != nil) {
        [self receivedString:[string stringByAppendingString:@"\n"] inChannel:currentChannel];
    }
}

#pragma mark - IBAction
- (void) joinChannel:(NSString *) channel {
    [writer addCommand:[@"JOIN #" stringByAppendingString:channel]];
    [tabView addItem:channel];

    NSTextView *newLog = [self newChatlog];
    [chatlogs setValue:newLog forKey:channel];
    currentChannel = channel;
    [scrollview setDocumentView:newLog];
}

#pragma mark - NSResponder methods
- (void) keyUp:(NSEvent *) theEvent {
    unsigned short keycode = [theEvent keyCode];
    NSUInteger flags = [theEvent modifierFlags];

    if (!(flags & NSControlKeyMask) || keycode != 48) {
        return;
    }

    if (flags & NSShiftKeyMask) {
        [tabView tabBackward];
    }
    else {
        [tabView tabForward];
    }
}

@end
