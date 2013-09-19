//
//  GLGIRCBroker.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/19/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGIRCBroker.h"

@implementation GLGIRCBroker

- (id) initWithDelegate:(id <GLGBrokerDelegate>) aDelegate {
    if (self = [super init]) {
        delegate = aDelegate;
    }

    return self;
}

- (NSString *) hostname {
    return hostname;
}

#pragma mark - connection methods
- (void) connectToServer: (NSString *) theHostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL {

    currentNick = username;
    hostname = theHostname;

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef) theHostname, port, &readStream, &writeStream);

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
}

- (void) connectToServer: (NSString *) theHostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL
            withChannels:(NSArray *) channels
{

    [self connectToServer:theHostname onPort:port withUsername:username withPassword:password useSSL:useSSL];
    channelsToJoin = channels;
}

- (void) connectToServer:(IRCServer *) server {
    NSMutableArray *theChannels = [[NSMutableArray alloc] init];
    [[server.channels allObjects] enumerateObjectsUsingBlock:^(IRCChannel *chan, NSUInteger index, BOOL *stop) {
        [theChannels addObject:[chan name]];
    }];

    [self connectToServer:server.hostname
                   onPort:[server.port intValue]
             withUsername:server.username
             withPassword:server.password
                   useSSL:server.useSSL
             withChannels:theChannels];
}

#pragma mark StreamReader Delegate methods
- (void) receivedString:(NSString *) string {
    if ([self handledPing:string]) {
        return;
    }

    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^:([a-z0-9!~@:.-]+) ([a-z0-9]+) (.+)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];

    if ([matches count] == 0) {
        return NSLog(@"looks like we got a boo boo: %@", string);
    }

    NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];
    NSString *theSender = [string substringWithRange:[channelMatch rangeAtIndex:1]];
    NSString *theType = [string substringWithRange:[channelMatch rangeAtIndex:2]];
    NSString *theMessage = [string substringWithRange:[channelMatch rangeAtIndex:3]];

    // xxx: temporary workaround for freenode chat name
    // I'd like for this to be passed to *some class* as the real hostname or value for the channel
    // and then ChatView wouldn't know about a server until it was actually active
    NSArray *components = [theSender componentsSeparatedByString:@"."];
    if (components.count == 3) {
        NSString *second = [components objectAtIndex:1];
        NSString *third = [components objectAtIndex:2];
        if ([second isEqualToString:@"freenode"] && [third isEqualToString:@"net"]) {
            theSender = @"chat.freenode.net";
        }
    }

    NSString *theChannel;
    if ([theType isEqualToString:@"JOIN"]) {
        NSArray *nameComponents = [theSender componentsSeparatedByString:@"!"];
        NSString *shortName = [nameComponents objectAtIndex:0];
        NSString *fullName = theSender;
        theChannel = [theMessage stringByReplacingOccurrencesOfString:@"#" withString:@""];
        string = [NSString stringWithFormat:@"%@ (%@) has joined channel #%@\n", shortName, fullName, theChannel];
    }
    else if ([theType isEqualToString:@"PART"]) {
        NSArray *nameComponents = [theSender componentsSeparatedByString:@"!"];
        NSString *shortName = [nameComponents objectAtIndex:0];
        NSString *fullName = theSender;
        theChannel = [theMessage stringByReplacingOccurrencesOfString:@"#" withString:@""];
        string = [NSString stringWithFormat:@"%@ (%@) has quit channel #%@\n", shortName, fullName, theChannel];
    }
    else if ([theType isEqualToString:@"PRIVMSG"]) {
        NSArray *nameComponents = [theSender componentsSeparatedByString:@"!"];
        NSString *whom = [nameComponents objectAtIndex:0];

        NSRange firstSpace = [theMessage rangeOfString:@" "];
        theChannel = [[theMessage substringWithRange:NSMakeRange(0, firstSpace.location)] stringByReplacingOccurrencesOfString:@"#" withString:@""];
        theMessage = [theMessage substringWithRange:NSMakeRange(firstSpace.location + 2, theMessage.length - (firstSpace.location + 2))];
        string = [NSString stringWithFormat:@"<%@> %@\n", whom, theMessage];
    }
    else {
        theChannel = theSender;
    }

    [delegate receivedString:string inChannel:theChannel fromHost:hostname];
}

- (void) didConnectToHost {
    // xxx: should wait until we get the real hostname for this server
    [delegate connectedToServer:hostname withInternalName:hostname];
    [channelsToJoin enumerateObjectsUsingBlock:^(NSString *chan, NSUInteger index, BOOL *stop) {
        [writer addCommand:[@"JOIN #" stringByAppendingString:chan]];
        [delegate joinChannel:chan onServer:hostname userInitiated:NO];
    }];
}

- (void) joinChannel:(NSString *) channel {
    [writer addCommand:[@"JOIN #" stringByAppendingString:channel]];
    [delegate joinChannel:channel onServer:hostname userInitiated:YES];
}

- (void) streamDidClose {
    NSLog(@"closing streams. Should start exponential backoff reconnect attempts");
    [inputStream close];
    [outputStream close];
}

#pragma mark - Response Parsing (needs to be refactored out of this class)
- (NSString *) didSubmitText:(NSString *)string inChannel:(NSString *) channel {

    NSString *message;
    NSString *command;
    NSString *messageToDisplay;
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
            messageToDisplay = [NSString stringWithFormat:@"/join %@, %@", channel, remainder];

            [self joinChannel:channel];
        }
        else if ([command isEqualToString:@"part"]) {
            NSString *channel = [[parts objectAtIndex:1] lowercaseString];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];
            message = [NSString stringWithFormat:@"PART #%@ %@", channel, remainder];
            messageToDisplay = [NSString stringWithFormat:@"/part %@ %@", channel, remainder];

            [delegate didPartChannel:channel];
        }
        else if ([command isEqualToString:@"msg"] || [command isEqualToString:@"whisper"]) {
            NSString *whom = [parts objectAtIndex:1];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];
            message = [NSString stringWithFormat:@"PRIVMSG %@ :%@", whom, remainder];
            messageToDisplay = [NSString stringWithFormat:@"<%@> %@", currentNick, remainder];
        }
        else if ([command isEqualToString:@"who"]) {
            if ([parts count] < 2) {
                message = @"";
                messageToDisplay = @"/who\nWHO: not enough parameters\nusage: /who {channel}";
            }
            else {
                NSString *whom = [parts objectAtIndex:1];
                message = [@"WHO " stringByAppendingString:whom];
                messageToDisplay = [NSString stringWithFormat:@"/who %@", whom];
            }
        }
        else if ([command isEqualToString:@"me"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];
            message = [@"ACTION " stringByAppendingString:remainder];
            messageToDisplay = [NSString stringWithFormat:@"/me %@", remainder];
        }
        else {
            NSLog(@"unknown command");
            message = string;
            messageToDisplay = string;
        }
    }
    else if (channel) {
        message = [NSString stringWithFormat:@"PRIVMSG #%@ :%@", channel, string];
        messageToDisplay = [NSString stringWithFormat:@"<%@> %@", currentNick, string];
    }
    else {
        NSLog(@"message sent with no receiving channel");
        message = string;
    }

    [writer addCommand:message];

    return messageToDisplay;
}

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

    NSString *theHostname = [maybePing substringWithRange:[result rangeAtIndex:1]];
    if ([theHostname length] > 0) {
        [writer addCommand:[@"PONG " stringByAppendingString:hostname]];
        return YES;
    }

    return NO;
}

@end
