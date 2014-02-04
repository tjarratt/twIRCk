//
//  GLGIRCBroker.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/19/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGIRCBroker.h"

@interface GLGIRCBroker ()
@property (weak, readwrite) id <GLGBrokerDelegate> delegate;
@property (retain, strong, readwrite) NSTimer *reconnectTimer;
@property (retain, strong, readwrite) NSString *hostname;
@property (retain, strong, readwrite) NSString *currentNick;
@property (retain, strong, readwrite) NSString *internalHostname;
@property (retain, strong, readwrite) NSMutableArray *channelsToJoin;
@property (retain, strong, readwrite) NSMutableDictionary *channelOccupants;
@property (retain, strong, readwrite) GLGReadDelegate *reader;
@property (retain, strong, readwrite) GLGWriteDelegate *writer;
@property (retain, strong, readwrite) IRCServer *server;
@property (retain, strong, readwrite) NSInputStream *inputStream;
@property (retain, strong, readwrite) NSOutputStream *outputStream;
@property (retain, strong, readwrite) GLGInputParser *inputParser;
@end

@implementation GLGIRCBroker

- (id) initWithDelegate:(id <GLGBrokerDelegate>) delegate {
    if (self = [super init]) {
        [self setDelegate:delegate];
        hasReadHostname = NO;
        reconnectAttempts = 0;
        [self setChannelOccupants:[[NSMutableDictionary alloc] init]];

        GLGInputParser *inputParser = [[GLGInputParser alloc] init];
        [inputParser setDelegate:self];
        [self setInputParser:inputParser];
    }

    return self;
}

#pragma mark - connection methods
- (void) connectToServer: (NSString *) theHostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL {

    [self setCurrentNick:username];
    [self setHostname:theHostname];

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef) theHostname, port, &readStream, &writeStream);

    if(!CFWriteStreamOpen(writeStream)) {
        // failed validation, or maybe not connected to the internet
        return NSLog(@"big trouble in little IRC client. Could not open write stream to %@ on port %d", theHostname, port);
    }

    NSInputStream *inputStream = (__bridge_transfer NSInputStream *) readStream;
    GLGReadDelegate *reader = [[GLGReadDelegate alloc] init];
    [reader setDelegate:self];
    [self setReader:reader];

    [inputStream setDelegate:reader];
    [self setInputStream:inputStream];

    NSOutputStream *outputStream = (__bridge_transfer NSOutputStream *) writeStream;
    GLGWriteDelegate *writer = [[GLGWriteDelegate alloc] init];
    [writer setWriteStream:outputStream];
    [self setWriter:writer];

    [outputStream setDelegate:writer];
    [self setOutputStream:outputStream];

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
    [self setChannelsToJoin:channels];
}

- (void) connectToServer:(IRCServer *) server {
    [self setServer:server];

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

    // NSLog(@"%@", string);

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
    if ([theSender isEqualToString:self.internalHostname]) {
        theSender = self.hostname;
    }

    NSString *theChannel;
    if ([theType isEqualToString:@"433"]) {
        NSArray *components = [theMessage componentsSeparatedByString:@" "];
        NSString *unavailableNick = [components objectAtIndex:1];

        string = [NSString stringWithFormat:@"The nick '%@' is already in use. Attempting to use '%@_'", unavailableNick, unavailableNick];
        theChannel = theSender;
        [self setCurrentNick:[unavailableNick stringByAppendingString:@"_"]];

        [self.server setUsername:self.currentNick];
        [self.writer addCommand:[@"NICK " stringByAppendingString:self.currentNick]];
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
        [self.delegate updateOccupants:occupants forChannel:theChannel];
    }
    else if ([theType isEqualToString:@"366"] || [theType isEqualToString:@"376"]) {
        string = @""; // "end of /NAMES list" or "end of MOTD"
        theChannel = theSender;
    }
    else if ([theType isEqualToString:@"NOTICE"]) {
        theChannel = theSender;
        NSUInteger startIndex = [theMessage rangeOfString:@":"].location + 1;
        string = [[theMessage substringFromIndex:startIndex] stringByAppendingString:@"\n"];
    }
    else if ([theType isEqualToString:@"372"]) {
        theChannel = theSender;
        NSUInteger indexOfMessageStart = [string rangeOfString:@":-"].location;
        string = [[string substringFromIndex:indexOfMessageStart + 2] stringByAppendingString:@"\n"];
    }
    else if ([theType isEqualToString:@"NICK"]) {
        theChannel = self.hostname;
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
        if ([shortName isEqualToString:self.currentNick]) {
            string = @"";
            theChannel = self.server.hostname;
        }
        else {
            [self userLeftChannel:theChannel withNick:shortName];
            NSMutableArray *occupants = [self.channelOccupants valueForKey:theChannel];
            [occupants removeObject:shortName];
            [self.channelOccupants setValue:occupants forKey:theChannel];
            [self.delegate updateOccupants:occupants forChannel:theChannel];
        }
    }
    else if ([theType isEqualToString:@"QUIT"]) {
        NSString *nick = [[theSender componentsSeparatedByString:@"!"] objectAtIndex:0];
        theChannel = self.server.hostname;
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
        if ([theChannel isEqualToString:self.currentNick]) {
            theChannel = whom;
        }

        // if the message matches currentNick, alert delegate
        NSRange substringRange = [theMessage rangeOfString:self.currentNick];
        if (substringRange.location != NSNotFound) {
            [self.delegate mentionedInChannel:theChannel fromBroker:self byUser:whom];
        }
    }
    else {
        theChannel = theSender;
    }

    [self.delegate receivedString:string inChannel:theChannel fromHost:self.hostname fromBroker:self];
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
    [self setInternalHostname:[message substringWithRange:[channelMatch rangeAtIndex:1]]];
}

- (void) didConnectToHost {
    reconnectAttempts = 0;
    [self.delegate connectedToServer:self.hostname fromBroker:self];

    for (int i = 0; i < self.channelsToJoin.count; ++i) {
        NSString *channel = [self.channelsToJoin objectAtIndex:i];
        [self.writer addCommand:[@"JOIN " stringByAppendingString:channel]];
        [self.delegate joinChannel:channel onServer:self.hostname userInitiated:NO fromBroker:self];
    }
}

- (void) streamDidClose {
    [self.inputStream close];
    [self.outputStream close];
    hasReadHostname = NO;
    [self setInternalHostname:nil];
    [self clearOccupantsInChannels];

    // TODO: at this point, we MIGHT need to close our tabs because they might "belong" to the wrong hostname
    // maybe the broker should know what the internal name is, and the
    // chatview and tabs will only know about the hostname the user entered?

    NSUInteger waitInterval = pow(2, reconnectAttempts);
    ++reconnectAttempts;
    waitInterval = MIN(waitInterval, 60);
    NSLog(@"going to wait for %lu seconds before firing timer", waitInterval);
    [self setReconnectTimer:[NSTimer timerWithTimeInterval:waitInterval target:self selector:@selector(attemptReconnect) userInfo:nil repeats:NO]];
    [[NSRunLoop currentRunLoop] addTimer:self.reconnectTimer forMode:NSRunLoopCommonModes];
}

- (void) attemptReconnect {
    int port = [self.server.port intValue];
    [self connectToServer:self.server.hostname onPort:port withUsername:self.server.username withPassword:self.server.password useSSL:self.server.useSSL];
}

#pragma mark - Input Parsing
- (void) didSubmitText:(NSString *) string inChannel:(NSString *) channel {
    [self.inputParser parseUserInput:string];
}

- (void) didJoinChannel:(NSString *) channelName rawCommand:(NSString *) rawCommand displayMessage:(NSString *) display {
    [self.writer addCommand:[@"JOIN " stringByAppendingString:channelName]];
    [self.delegate joinChannel:channelName onServer:self.hostname userInitiated:YES fromBroker:self];
    [self.delegate receivedString:display inChannel:channelName fromHost:self.hostname fromBroker:self];
    [self.server addChannelNamed:channelName];

    NSMutableArray *occupants = [self.channelOccupants valueForKey:channelName];
    if (occupants == nil) {
        occupants = [[NSMutableArray alloc] init];
        [self.channelOccupants setValue:occupants forKey:channelName];
    }
}

- (void) didPartCurrentChannelWithRawCommand:(NSString *) raw displayMessage:(NSString *) display {
    [self partChannel:nil userInitiated:NO]; // TODO:NOPE (currentChannel should be here, not on chatView)
    [self.delegate receivedString:display inChannel:nil fromHost:self.hostname fromBroker:self];
}

- (void) didPartChannel:(NSString *)channel rawCommand:(NSString *) rawCommand displayMessage:(NSString *) display {
    [self partChannel:channel userInitiated:NO];
    [self.delegate receivedString:display inChannel:channel fromHost:self.hostname fromBroker:self];
}

- (void) didChangeNick:(NSString *) newNick rawCommand:(NSString *) rawCommand displayMessage:(NSString *) display {
    [self setCurrentNick:newNick];
    [self.server setUsername:newNick];
    [self.delegate receivedString:display inChannel:nil fromHost:self.hostname fromBroker:self];
}

- (void) didChangePassword:(NSString *)newPassword rawCommand:(NSString *) rawCommand displayMessage:(NSString *) display {
    [self.server setPassword:newPassword];
    [self.delegate receivedString:display inChannel:nil fromHost:self.hostname fromBroker:self];
}

- (void) didSendMessageToTarget:(NSString *) channelOrUser rawCommand:(NSString *) rawCommand displayMessage:(NSString *)
display {
    [self.writer addCommand:rawCommand];
    [self.delegate receivedString:display inChannel:channelOrUser fromHost:self.hostname fromBroker:self];
}

- (void) didSendMessageToCurrentTargetWithRawCommand:(NSString *) rawCommand displayMessage:(NSString *) display {
    [self.writer addCommand:rawCommand];
    [self.delegate receivedString:display inChannel:nil fromHost:self.hostname fromBroker:self];
}

- (void) didSendUnknownMessageToCurrentTargetWithRawCommand:(NSString *) rawCommand displayMessage:(NSString *) display {
    [self.writer addCommand:rawCommand];
    [self.delegate receivedString:display inChannel:nil fromHost:self.hostname fromBroker:self];
}

- (void) willPartChannel:(NSString *)channelName {
    [self partChannel:channelName userInitiated:YES];
}

- (void) partChannel:(NSString *) channelName userInitiated:(BOOL) byUser {
    __block NSString *name = channelName;
    NSManagedObjectContext *context = [GLGManagedObjectContext managedObjectContext];

    NSMutableSet *channels = [self.server.channels mutableCopy];

    __block IRCChannel *theChannel;
    [self.server.channels enumerateObjectsUsingBlock:^(IRCChannel *channel, BOOL *stop) {
        if ([[channel properName] isEqualToString:name]) {
            theChannel = channel;
            // *stop = YES;
        }
    }];

    if (theChannel) {
        [channels removeObject:theChannel];
        [self.server setChannels:[channels copy]];

        NSError *error;
        [context deleteObject:theChannel];
        [context save:&error];
    }
    else {
        NSLog(@"couldn't find a channel named %@ belonging to server %@, oh no!", channelName, self.server.hostname);
    }

    if (byUser) {
        [self.writer addCommand:[NSString stringWithFormat:@"PART %@ http://twIRCk.com (sometimes you just gotta twIRCk it!)", channelName]];
    }
}

#pragma mark - Response Parsing (needs to be refactored out of this class)
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
        [self.writer addCommand:[@"PONG " stringByAppendingString:self.hostname]];
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
    [self.delegate updateOccupants:occupants forChannel:channel];
}

- (BOOL) userLeftChannel:channel withNick:nick {
    NSMutableArray *occupants = [[self.channelOccupants valueForKey:channel] mutableCopy];
    if (![occupants containsObject:nick]) {
        return NO;
    }

    [occupants removeObject:nick];
    [self.channelOccupants setValue:occupants forKey:channel];
    [self.delegate updateOccupants:occupants forChannel:channel];

    return YES;
}

- (void) removeNickFromAllChannels:(NSString *) nick withMessage:(NSString *) message {
    [[self channelOccupants] enumerateKeysAndObjectsUsingBlock:^(NSString *channel, NSArray *occupants, BOOL *stop) {
        BOOL wasInChannel = [self userLeftChannel:channel withNick:nick];

        if (wasInChannel) {
            NSString *quitMessage = [NSString stringWithFormat:@"%@ has quit: %@\n", nick, message];
            [self.delegate receivedString:quitMessage inChannel:channel fromHost:self.hostname fromBroker:self];
        }
    }];
}

@end