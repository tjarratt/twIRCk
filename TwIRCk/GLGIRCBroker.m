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
        reconnectAttempts = 0;
        hasReadHostname = NO;
        [self setChannelOccupants:[[NSMutableDictionary alloc] init]];
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
        return NSLog(@"big trouble in little IRC client. Could not open write stream to %@ on port %d", theHostname, port);
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

- (void) connectToServer:(IRCServer *) theServer {
    server = theServer;

    NSMutableArray *theChannels = [[NSMutableArray alloc] init];
    [[server.channels allObjects] enumerateObjectsUsingBlock:^(IRCChannel *chan, NSUInteger index, BOOL *stop) {
        [theChannels addObject:[chan name]];

        NSMutableArray *occupants = [[NSMutableArray alloc] init];
        [[self channelOccupants] setValue:occupants forKey:[chan name]];
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
    if (!hasReadHostname) {
        [self readActualHostname:string];
    }

    if ([self handledPing:string]) {
        return;
    }

    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^:([a-z0-9!~`_/|@:\\[\.\-]+) ([a-z0-9]+) (.+)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];

    if ([matches count] == 0) {
        return NSLog(@"looks like we got a boo boo: %@", string);
    }

    NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];
    NSString *theSender = [string substringWithRange:[channelMatch rangeAtIndex:1]];
    NSString *theType = [string substringWithRange:[channelMatch rangeAtIndex:2]];
    NSString *theMessage = [string substringWithRange:[channelMatch rangeAtIndex:3]];

    // when you connect to some servers eg: chat.freenode.net, your requests will actually
    // be handled by what is effectively a mirror, or a shard eg: hitchcock.
    if ([theSender isEqualToString:internalHostname]) {
        theSender = hostname;
    }

    NSString *theChannel;
    if ([theType isEqualToString:@"353"]) {
        // read the channel and all of the occupants
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(.*) :" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [regex matchesInString:theMessage options:0 range:NSMakeRange(0, theMessage.length)];

        if ([matches count] == 0) {
            return NSLog(@"could not parse occupants for channel in message : %@", theMessage);
        }

        NSTextCheckingResult *result = [matches objectAtIndex:0];
        NSRange channelRange = [result rangeAtIndex:1];
        theChannel = [theMessage substringWithRange:channelRange];

        NSUInteger start = channelRange.location + channelRange.length + 2;
        NSUInteger remaining = theMessage.length - start;
        NSString *nameString = [theMessage substringWithRange:NSMakeRange(start, remaining)];
        NSArray *names = [nameString componentsSeparatedByString:@" "];

        NSMutableArray *occupants = [self.channelOccupants valueForKey:theChannel];
        if (occupants == nil) {
            occupants = [[NSMutableArray alloc] init];
        }

        [occupants addObjectsFromArray:names];
        [self.channelOccupants setValue:occupants forKey:theChannel];
        [delegate updateOccupants:occupants forChannel:theChannel];
    }
    else if ([theType isEqualToString:@"JOIN"]) {
        NSArray *nameComponents = [theSender componentsSeparatedByString:@"!"];
        NSString *shortName = [nameComponents objectAtIndex:0];
        NSString *fullName = theSender;
        theChannel = [theMessage stringByReplacingOccurrencesOfString:@"#" withString:@""];
        string = [NSString stringWithFormat:@"%@ (%@) has joined channel #%@\n", shortName, fullName, theChannel];

        NSMutableArray *occupants = [self.channelOccupants valueForKey:theChannel];
        [occupants addObject:shortName];
        [self.channelOccupants setValue:occupants forKey:theChannel];
        [delegate updateOccupants:occupants forChannel:theChannel];
    }
    else if ([theType isEqualToString:@"PART"]) {
        NSArray *nameComponents = [theSender componentsSeparatedByString:@"!"];
        NSString *shortName = [nameComponents objectAtIndex:0];
        NSString *fullName = theSender;
        theChannel = [theMessage stringByReplacingOccurrencesOfString:@"#" withString:@""];
        string = [NSString stringWithFormat:@"%@ (%@) has quit channel #%@\n", shortName, fullName, theChannel];

        NSMutableArray *occupants = [self.channelOccupants valueForKey:theChannel];
        [occupants removeObject:shortName];
        [self.channelOccupants setValue:occupants forKey:theChannel];
        [delegate updateOccupants:occupants forChannel:theChannel];
        // xxx: this doesn't go in the right channel AT ALL grrrrrr
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

- (void) readActualHostname:(NSString *) message {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^:([a-z0-9!~`/@:.-]+) ([a-z0-9]+) (.+)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:message options:0 range:NSMakeRange(0, [message length])];

    if ([matches count] == 0) {
        return NSLog(@"SNAP. Could not read internal hostname from message : %@", message);
    }

    NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];

    hasReadHostname = YES;
    internalHostname = [message substringWithRange:[channelMatch rangeAtIndex:1]];
}

- (void) didConnectToHost {
    reconnectAttempts = 0;
    [delegate connectedToServer:hostname];
    [channelsToJoin enumerateObjectsUsingBlock:^(NSString *chan, NSUInteger index, BOOL *stop) {
        [writer addCommand:[@"JOIN #" stringByAppendingString:chan]];
        [delegate joinChannel:chan onServer:hostname userInitiated:NO];
    }];
}

- (void) joinChannel:(NSString *) channelName {
    [writer addCommand:[@"JOIN #" stringByAppendingString:channelName]];
    [delegate joinChannel:channelName onServer:hostname userInitiated:YES];
    [server addChannelNamed:channelName];

    NSMutableArray *occupants = [self.channelOccupants valueForKey:channelName];
    if (occupants == nil) {
        occupants = [[NSMutableArray alloc] init];
        [self.channelOccupants setValue:occupants forKey:channelName];
    }
}

- (void) partChannel:(NSString *) channelName {
    [delegate willPartChannel:channelName];

    __block NSString *name = channelName;
    NSManagedObjectContext *context = [GLGManagedObjectContext managedObjectContext];
    [[server channels] enumerateObjectsUsingBlock:^(IRCChannel *channel, BOOL *stop) {
        if ([[channel name] isEqualToString:name]) {
            NSError *error;
            [context deleteObject:channel];
            [context save:&error];
             stop = YES;
        }
    }];
}

- (void) streamDidClose {
    [inputStream close];
    [outputStream close];
    hasReadHostname = NO;
    // at this point, we MIGHT need to close our tabs because
    // they might "belong" to the wrong hostname, right?
    // maybe the broker should know what the internal name is, and the
    // chatview and tabs will only know about the hostname the user entered?

    NSUInteger waitInterval = pow(2, reconnectAttempts);
    ++reconnectAttempts;
    waitInterval = MIN(waitInterval, 60);
    NSLog(@"going to wait for %lu seconds before firing timer", waitInterval);
    reconnectTimer = [NSTimer timerWithTimeInterval:waitInterval target:self selector:@selector(attemptReconnect) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:reconnectTimer forMode:NSRunLoopCommonModes];
}

- (void) attemptReconnect {
    int port = [server.port intValue];
    [self connectToServer:server.hostname onPort:port withUsername:server.username withPassword:server.password useSSL:server.useSSL];
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
            NSString *theChannel;
            if ([parts count] < 2 && channel) {
                theChannel = channel;
                message = [NSString stringWithFormat:@"PART #%@ http://twIRCk.com (sometimes you just gotta twIRCk it!)", channel];
                messageToDisplay = @"";
            }
            else {
                theChannel = [[parts objectAtIndex:1] lowercaseString];
                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
                parts = [parts objectsAtIndexes:indices];
                NSString *remainder = [parts componentsJoinedByString:@" "];
                message = [NSString stringWithFormat:@"PART #%@ %@", channel, remainder];
                messageToDisplay = @"";
            }

            [self partChannel:theChannel];
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
        else if ([command isEqualToString:@"nick"]) {
            currentNick = [parts objectAtIndex:1];
            [server setUsername:currentNick];
            message = [@"NICK " stringByAppendingString:currentNick];
            messageToDisplay = [NSString stringWithFormat:@"/nick %@", currentNick];
        }
        else if ([command isEqualToString:@"pass"]) {
            [server setPassword:[parts objectAtIndex:1]];
            message = [@"PASS " stringByAppendingString:server.password];
            messageToDisplay = [NSString stringWithFormat:@"/pass %@", server.password];
        }
        else {
            NSLog(@"unknown command: %@", command);
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

- (NSArray *) occupantsInChannel:(NSString *) channel {
    return [[self channelOccupants] valueForKey:channel];
}

@end
