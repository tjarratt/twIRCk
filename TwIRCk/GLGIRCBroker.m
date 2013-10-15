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
        if ([[chan name] length] == 0) { return; }

        [theChannels addObject:[chan properName]];
        NSMutableArray *occupants = [[NSMutableArray alloc] init];
        [[self channelOccupants] setValue:occupants forKey:[chan properName]];
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

    NSLog(@"%@", string);

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
    if ([theType isEqualToString:@"433"]) { // username is not available

    }
    else if ([theType isEqualToString:@"353"]) {
        // read the channel and all of the occupants
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(.*) :" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [regex matchesInString:theMessage options:0 range:NSMakeRange(0, theMessage.length)];

        if ([matches count] == 0) {
            return NSLog(@"could not parse occupants for channel in message : %@", theMessage);
        }

        NSTextCheckingResult *result = [matches objectAtIndex:0];
        NSRange channelRange = [result rangeAtIndex:1];
        theChannel = [@"#" stringByAppendingString:[theMessage substringWithRange:channelRange]];

        NSUInteger start = channelRange.location + channelRange.length + 2;
        NSUInteger remaining = theMessage.length - start;
        NSString *nameString = [theMessage substringWithRange:NSMakeRange(start, remaining)];
        NSArray *names = [nameString componentsSeparatedByString:@" "];

        NSMutableArray *cleanedNames = [[NSMutableArray alloc] init];
        [names enumerateObjectsUsingBlock:^(NSString *occupant, NSUInteger index, BOOL *stop) {
            [cleanedNames addObject:[occupant stringByReplacingOccurrencesOfString:@"@" withString:@""]];
        }];

        NSMutableArray *occupants = [self.channelOccupants valueForKey:theChannel];
        if (occupants == nil) {
            occupants = [[NSMutableArray alloc] init];
        }

        string = @"";
        [occupants addObjectsFromArray:cleanedNames];
        [self.channelOccupants setValue:occupants forKey:theChannel];
        [delegate updateOccupants:occupants forChannel:theChannel];
    }
    else if ([theType isEqualToString:@"366"] || [theType isEqualToString:@"376"]) {
        string = @""; // "end of /NAMES list" or "end of MOTD"
        theChannel = theSender;
    }
    else if ([theType isEqualToString:@"NOTICE"]) {
        theChannel = theSender;
        NSUInteger startIndex = [string rangeOfString:@":"].location;
        string = [[theMessage substringFromIndex:startIndex + 3] stringByAppendingString:@"\n"];
    }
    else if ([theType isEqualToString:@"372"]) {
        theChannel = theSender;
        NSUInteger indexOfMessageStart = [string rangeOfString:@":-"].location;
        string = [[string substringFromIndex:indexOfMessageStart + 2] stringByAppendingString:@"\n"];
    }
    else if ([theType isEqualToString:@"NICK"]) {
        theChannel = hostname;
        NSString *newNick = [theMessage substringWithRange:NSMakeRange(1, theMessage.length - 1)];
        NSString *oldNick = [[theSender componentsSeparatedByString:@"!"] objectAtIndex:0];
        string = [NSString stringWithFormat:@"%@ has changed their nick to %@\n", oldNick, newNick];

        [self nickChangedFrom:oldNick to:newNick];
    }
    else if ([theType isEqualToString:@"JOIN"]) {
        NSArray *nameComponents = [theSender componentsSeparatedByString:@"!"];
        NSString *shortName = [nameComponents objectAtIndex:0];
        NSString *fullName = theSender;
        theChannel = theMessage;
        string = [NSString stringWithFormat:@"%@ (%@) has joined channel %@\n", shortName, fullName, theChannel];

        [self userJoinedChannel:(NSString *)theChannel withNick:(NSString *)shortName];
    }
    else if ([theType isEqualToString:@"PART"]) {
        NSArray *nameComponents = [theSender componentsSeparatedByString:@"!"];
        NSString *shortName = [nameComponents objectAtIndex:0];
        NSString *fullName = theSender;

        NSArray *partComponents = [theMessage componentsSeparatedByString:@" "];
        theChannel = [partComponents objectAtIndex:0];
        string = [NSString stringWithFormat:@"%@ (%@) has quit channel %@\n", shortName, fullName, theChannel];

        // xxx it would be ideal if we could still show this IFF the tab is open
        if ([shortName isEqualToString:currentNick]) {
            string = @"";
            theChannel = server.hostname;
        }
        else {
            [self userLeftChannel:theChannel withNick:shortName];
            NSMutableArray *occupants = [self.channelOccupants valueForKey:theChannel];
            [occupants removeObject:shortName];
            [self.channelOccupants setValue:occupants forKey:theChannel];
            [delegate updateOccupants:occupants forChannel:theChannel];
        }
    }
    else if ([theType isEqualToString:@"QUIT"]) {
        NSString *nick = [[theSender componentsSeparatedByString:@"!"] objectAtIndex:0];
        theChannel = server.hostname;
        string = [NSString stringWithFormat:@"%@ has quit %@\n", nick, theMessage];

        [self removeNickFromAllChannels:nick withMessage:theMessage];
    }
    else if ([theType isEqualToString:@"PRIVMSG"]) {
        NSArray *nameComponents = [theSender componentsSeparatedByString:@"!"];
        NSString *whom = [nameComponents objectAtIndex:0];

        NSRange firstSpace = [theMessage rangeOfString:@" "];
        theChannel = [theMessage substringWithRange:NSMakeRange(0, firstSpace.location)];
        theMessage = [theMessage substringWithRange:NSMakeRange(firstSpace.location + 2, theMessage.length - (firstSpace.location + 2))];
        string = [NSString stringWithFormat:@"<%@> %@\n", whom, theMessage];

        // private message to use from another user
        if ([theChannel isEqualToString:currentNick]) {
            theChannel = whom;
        }

        // if the message matches currentNick, alert delegate
        NSRange substringRange = [theMessage rangeOfString:currentNick];
        if (substringRange.location != NSNotFound) {
            [delegate mentionedInChannel:theChannel fromBroker:self byUser:whom];
        }
    }
    else {
        theChannel = theSender;
    }

    [delegate receivedString:string inChannel:theChannel fromHost:hostname fromBroker:self];
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
    [delegate connectedToServer:hostname fromBroker:self];
    
    [channelsToJoin enumerateObjectsUsingBlock:^(NSString *chan, NSUInteger index, BOOL *stop) {
        [writer addCommand:[@"JOIN " stringByAppendingString:chan]];
        [delegate joinChannel:chan onServer:hostname userInitiated:NO fromBroker:self];
    }];
}

- (void) joinChannel:(NSString *) channelName {
    [writer addCommand:[@"JOIN " stringByAppendingString:channelName]];
    [delegate joinChannel:channelName onServer:hostname userInitiated:YES fromBroker:self];
    [server addChannelNamed:channelName];

    NSMutableArray *occupants = [self.channelOccupants valueForKey:channelName];
    if (occupants == nil) {
        occupants = [[NSMutableArray alloc] init];
        [self.channelOccupants setValue:occupants forKey:channelName];
    }
}

- (void) partChannel:(NSString *) channelName userInitiated:(BOOL) byUser {
    __block NSString *name = channelName;
    NSManagedObjectContext *context = [GLGManagedObjectContext managedObjectContext];

    NSMutableSet *channels = [[server channels] mutableCopy];

    __block IRCChannel *theChannel;
    [[server channels] enumerateObjectsUsingBlock:^(IRCChannel *channel, BOOL *stop) {
        if ([[channel properName] isEqualToString:name]) {
            theChannel = channel;
            // *stop = YES;
        }
    }];

    if (theChannel) {
        [channels removeObject:theChannel];
        [server setChannels:[channels copy]];

        NSError *error;
        [context deleteObject:theChannel];
        [context save:&error];
    }
    else {
        NSLog(@"couldn't find a channel named %@ belonging to server %@, oh no!", channelName, server.hostname);
    }

    if (byUser) {
        [writer addCommand:[NSString stringWithFormat:@"PART %@ http://twIRCk.com (sometimes you just gotta twIRCk it!)", channelName]];
    }
}

- (void) partChannel:(NSString *) channelName {
    [self partChannel:channelName userInitiated:NO];
}

- (void) streamDidClose {
    [inputStream close];
    [outputStream close];
    hasReadHostname = NO;
    [self clearOccupantsInChannels];

    // TODO: at this point, we MIGHT need to close our tabs because they might "belong" to the wrong hostname
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
- (GLGIRCMessage *) didSubmitText:(NSString *)string inChannel:(NSString *) channel {

    NSString *command;
    GLGIRCMessage *ircMessage = [[GLGIRCMessage alloc] init];
    [ircMessage setTarget:channel];

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

            NSString *channelToJoin;
            // if the user says /join foo, we should rewrite this as /join #foo
            if (![[channel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                channelToJoin = [@"#" stringByAppendingString:channel];
                channel = [@"#" stringByAppendingString:channel];
            }
            else {
                channelToJoin = channel;
            }

            [ircMessage setRaw:[NSString stringWithFormat:@"JOIN %@ %@", channelToJoin, remainder]];
            [ircMessage setMessage:[NSString stringWithFormat:@"/join %@ %@", channel, remainder]];
            [ircMessage setTarget:channel];

            [self joinChannel:channel];
        }
        else if ([command isEqualToString:@"part"]) {
            NSString *theChannel;
            if ([parts count] < 2 && channel) {
                theChannel = channel;
                NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)";
                [ircMessage setRaw:[NSString stringWithFormat:@"PART %@ http://twIRCk.com (sometimes you just gotta twIRCk it!)", channel]];
                [ircMessage setMessage:[NSString stringWithFormat:@"/part %@ %@", channel, defaultMessage]];
                [ircMessage setTarget:channel];
            }
            else {
                theChannel = [[parts objectAtIndex:1] lowercaseString];
                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
                parts = [parts objectsAtIndexes:indices];
                NSString *remainder = [parts componentsJoinedByString:@" "];
                [ircMessage setRaw:[NSString stringWithFormat:@"PART %@ %@", channel, remainder]];
                [ircMessage setMessage:[NSString stringWithFormat:@"/part %@ %@", channel, remainder]];
                [ircMessage setTarget:channel];
            }
            
            [self partChannel:theChannel];
        }
        else if ([command isEqualToString:@"msg"] || [command isEqualToString:@"whisper"]) {
            NSString *whom = [parts objectAtIndex:1];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];

            [ircMessage setRaw:[NSString stringWithFormat:@"PRIVMSG %@ :%@", whom, remainder]];
            [ircMessage setMessage:[NSString stringWithFormat:@"<%@> %@", currentNick, remainder]];
            [ircMessage setTarget:whom];
        }
        else if ([command isEqualToString:@"who"]) {
            if ([parts count] < 2) {
                [ircMessage setRaw:@""];
                [ircMessage setMessage:@"/who\nWHO: not enough parameters\nusage: /who {channel}"];
            }
            else {
                NSString *whom = [parts objectAtIndex:1];
                [ircMessage setRaw:[@"WHO " stringByAppendingString:whom]];
                [ircMessage setMessage:[NSString stringWithFormat:@"/who %@", whom]];
                [ircMessage setTarget:whom];
            }
        }
        else if ([command isEqualToString:@"me"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];
            [ircMessage setRaw:[@"ACTION " stringByAppendingString:remainder]];
            [ircMessage setMessage:[NSString stringWithFormat:@"/me %@", remainder]];
        }
        else if ([command isEqualToString:@"nick"]) {
            currentNick = [parts objectAtIndex:1];
            [server setUsername:currentNick];
            [ircMessage setRaw:[@"NICK " stringByAppendingString:currentNick]];
            [ircMessage setMessage:[NSString stringWithFormat:@"/nick %@", currentNick]];
        }
        else if ([command isEqualToString:@"pass"]) {
            [server setPassword:[parts objectAtIndex:1]];
            [ircMessage setRaw:[@"PASS " stringByAppendingString:server.password]];
            [ircMessage setMessage:[NSString stringWithFormat:@"/pass %@", server.password]];
        }
        else if ([command isEqualToString:@"topic"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(1, parts.count - 1)];
            NSString *remainder = [[parts objectsAtIndexes:indices] componentsJoinedByString:@" "];
            [ircMessage setRaw:[NSString stringWithFormat:@"TOPIC %@ %@", channel, remainder]];
            [ircMessage setMessage:string];
        }
        else {
            NSString *fullCommand = [NSString stringWithFormat:@"%@ %@", [command uppercaseString], [parts componentsJoinedByString:@" "]];
            NSLog(@"sending unknown command %@ as: %@", command, fullCommand);

            [ircMessage setRaw:fullCommand];
            [ircMessage setMessage:string];
        }
    }
    else {
        [ircMessage setRaw:[NSString stringWithFormat:@"PRIVMSG %@ :%@", channel, string]];
        [ircMessage setMessage:[NSString stringWithFormat:@"<%@> %@", currentNick, string]];
    }

    [writer addCommand:[ircMessage raw]];

    return ircMessage;
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

#pragma mark - channel occupants methods
- (NSArray *) occupantsInChannel:(NSString *) channel {
    return [[self channelOccupants] valueForKey:channel];
}

- (void) clearOccupantsInChannels {
    [self setChannelOccupants:[[NSMutableDictionary alloc] init]];
}

- (void) nickChangedFrom:(NSString *) oldNick to:(NSString *) newNick {
    [[self channelOccupants] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *occupants, BOOL *stop) {
        if ([occupants containsObject:oldNick]) {
            NSMutableArray *newOccupants = [occupants mutableCopy];
            [newOccupants removeObject:oldNick];
            [newOccupants addObject:newNick];

            [[self channelOccupants] setValue:newOccupants forKey:key];
        }
    }];
}

- (void) userJoinedChannel:(NSString *) channel withNick:(NSString *) nick {
    NSMutableArray *occupants = [[self.channelOccupants valueForKey:channel] mutableCopy];
    if ([occupants containsObject:nick]) {
        return;
    }

    [occupants addObject:nick];
    [self.channelOccupants setValue:occupants forKey:channel];
    [delegate updateOccupants:occupants forChannel:channel];
}

- (BOOL) userLeftChannel:channel withNick:nick {
    NSMutableArray *occupants = [[self.channelOccupants valueForKey:channel] mutableCopy];
    if (![occupants containsObject:nick]) {
        return NO;
    }

    [occupants removeObject:nick];
    [self.channelOccupants setValue:occupants forKey:channel];
    [delegate updateOccupants:occupants forChannel:channel];

    return YES;
}

- (void) removeNickFromAllChannels:(NSString *) nick withMessage:(NSString *) message {
    [[self channelOccupants] enumerateKeysAndObjectsUsingBlock:^(NSString *channel, NSArray *occupants, BOOL *stop) {
        BOOL wasInChannel = [self userLeftChannel:channel withNick:nick];

        if (wasInChannel) {
            NSString *quitMessage = [NSString stringWithFormat:@"%@ has quit: %@\n", nick, message];
            [delegate receivedString:quitMessage inChannel:channel fromHost:hostname fromBroker:self];
        }
    }];
}

@end
