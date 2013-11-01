//
//  GLGIRCParser.m
//  TwIRCk
//
//  Created by Tim Jarratt on 10/18/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGIRCParser.h"

@implementation GLGIRCParser

+(GLGIRCMessage *) parseUserInput:(NSString *) string {
    GLGIRCMessage *ircMessage = [[GLGIRCMessage alloc] init];
    [ircMessage setTarget:@"<__channel__>"];

    NSString *raw;
    NSString *type;
    NSString *message;
    NSString *payload;

    if ([[string substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"] ) {
        NSUInteger length = [string length];
        NSString *substring = [string substringWithRange:NSMakeRange(1, length - 1)];
        NSArray *parts = [substring componentsSeparatedByString:@" "];
        NSString *command = [[parts objectAtIndex:0] lowercaseString];

        if ([command isEqualToString:@"join"]) {
            NSString *channel = [[parts objectAtIndex:1] lowercaseString];

            if (![[channel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                channel = [@"#" stringByAppendingString:channel];
            }

            type = @"join";
            raw = [NSString stringWithFormat:@"JOIN %@", channel];
            message = [NSString stringWithFormat:@"/join %@", channel];
            payload = channel;

        }
        else if ([command isEqualToString:@"part"]) {
            NSString *theChannel;

            if (parts.count == 1) {
                theChannel = @"<__channel__>";
                NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)";

                type = @"part";
                raw = [NSString stringWithFormat:@"PART <__channel__> %@", defaultMessage];
                message = [NSString stringWithFormat:@"/part <__channel__> %@", defaultMessage];
            }
            else if (parts.count == 2) {
                theChannel = [parts objectAtIndex:1];
                if (![[theChannel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                    theChannel = [@"#" stringByAppendingString:theChannel];
                }

                NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)";

                type = @"part";
                raw = [NSString stringWithFormat:@"PART %@ %@", theChannel, defaultMessage];
                message = [NSString stringWithFormat:@"/part %@ %@", theChannel, defaultMessage];
            }
            else {
                theChannel = [[parts objectAtIndex:1] lowercaseString];
                if (![[theChannel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                    theChannel = [@"#" stringByAppendingString:theChannel];
                }

                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
                parts = [parts objectsAtIndexes:indices];
                NSString *remainder = [parts componentsJoinedByString:@" "];

                type = @"part";
                raw = [NSString stringWithFormat:@"PART %@ %@", theChannel, remainder];
                message = [NSString stringWithFormat:@"/part %@ %@", theChannel, remainder];
            }
            payload = theChannel;
        }
        else if ([command isEqualToString:@"msg"] || [command isEqualToString:@"whisper"]) {
            NSString *whom = [parts objectAtIndex:1];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];

            type = @"msg";
            raw = [NSString stringWithFormat:@"PRIVMSG %@ :%@", whom, remainder];
            message = [NSString stringWithFormat:@"<<__nick__>> %@", remainder];
            payload = whom;
        }
        else if ([command isEqualToString:@"who"]) {
            if ([parts count] < 2) {
                type = @"who";
                raw = @"";
                message = @"/who\nWHO: not enough parameters\nusage: /who {channel}";
            }
            else {
                NSString *whom = [parts objectAtIndex:1];
                type = @"who";
                raw = [@"WHO " stringByAppendingString:whom];
                message = [NSString stringWithFormat:@"/who %@", whom];
                payload = whom;
            }
        }
        else if ([command isEqualToString:@"me"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];

            type = @"me";
            raw = [@"ACTION " stringByAppendingString:remainder];
            message = [NSString stringWithFormat:@"/me %@", remainder];
        }
        else if ([command isEqualToString:@"nick"]) {
            NSString *newNick = [parts objectAtIndex:1];

            type = @"nick";
            raw = [@"NICK " stringByAppendingString:newNick];
            message = [NSString stringWithFormat:@"/nick %@", newNick];
            payload = newNick;
        }
        else if ([command isEqualToString:@"pass"]) {
            NSString *newPassword = [parts objectAtIndex:1];

            type = @"pass";
            raw = [@"PASS " stringByAppendingString:newPassword];
            message = [NSString stringWithFormat:@"/pass %@", newPassword];
            payload = newPassword;
        }
        else if ([command isEqualToString:@"topic"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(1, parts.count - 1)];
            NSString *remainder = [[parts objectsAtIndexes:indices] componentsJoinedByString:@" "];

            type = @"topic";
            raw = [NSString stringWithFormat:@"TOPIC <__channel__> %@", remainder];
            message = string;
        }
        else {
            NSString *fullCommand = [command uppercaseString];
            if ([parts count] > 1) {
                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(1, parts.count - 1)];
                NSArray *mutableParts = [parts objectsAtIndexes:indices];
                fullCommand = [[fullCommand stringByAppendingString:@" "] stringByAppendingString: [mutableParts componentsJoinedByString:@" "]];

                type = command;
                raw = fullCommand;
                message = string;

            }
        }
    }
    else {
        type = @"msg";
        raw = [NSString stringWithFormat:@"PRIVMSG <__channel__> :%@", string];
        message = [NSString stringWithFormat:@"<<__nick__>> %@", string];
    }

    [ircMessage setType:type];
    [ircMessage setMessage:message];
    [ircMessage setRaw:raw];
    [ircMessage setPayload:payload];

    return ircMessage;
}

+(GLGIRCMessage *) parseRawIRCString:(NSString *) string {
    GLGIRCMessage *msg = [[GLGIRCMessage alloc] init];
    [msg setFromHost:[self readHostnameFromString:string]];

    // ping
    if ([self isPing:string]) {
        [msg setType:@"ping"];
    }
    else {
        NSLog(@"%@", string);

        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^:([a-z0-9!~`_/|@:\\[\.\-]+) ([a-z0-9]+) (.+)" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];

        if ([matches count] == 0) {
            NSLog(@"looks like we got a boo boo: %@", string);
            [msg setType:@"error"];
            [msg setRaw:string];
            return msg;
        }

        NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];
        NSString *theSender = [string substringWithRange:[channelMatch rangeAtIndex:1]];
        NSString *theType = [string substringWithRange:[channelMatch rangeAtIndex:2]];
        NSString *theMessage = [string substringWithRange:[channelMatch rangeAtIndex:3]];

        // when you connect to some servers eg: chat.freenode.net, your requests will actually
        // be handled by what is effectively a mirror, or a shard eg: hitchcock.
        [msg setFromHost:theSender];

        if ([theType isEqualToString:@"433"]) {
            NSArray *components = [theMessage componentsSeparatedByString:@" "];
            NSString *unavailableNick = [components objectAtIndex:1];

            [msg setType:@"NickInUse"];
            [msg setRaw:string];
            [msg setMessage:[NSString stringWithFormat:@"The nick '%@' is already in use. Attempting to use '%@_'", unavailableNick, unavailableNick]];
            [msg setPayload:[unavailableNick stringByAppendingString:@"_"]];
        }
        else if ([theType isEqualToString:@"353"]) {
            [self readChannelOccupantsFromString:theMessage intoMessage:&msg];
        }
    }

    return msg;
}

#pragma mark - Private
+(BOOL) isPing:(NSString *) maybePing {
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
        return YES;
    }

    return NO;
}

+(NSString *) readHostnameFromString:(NSString *) string {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^:([a-z0-9!~`/@:.-]+) ([a-z0-9]+) (.+)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];

    if ([matches count] == 0) {
        NSLog(@"SNAP. Could not read internal hostname from message : %@", string);
        return nil;
    }

    NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];
    return [string substringWithRange:[channelMatch rangeAtIndex:1]];
}

+(void) readChannelOccupantsFromString:(NSString *)string intoMessage:(GLGIRCMessage **)message {
    // read the channel and all of the occupants
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(.*) :" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];

    if (matches.count == 0) {
        return NSLog(@"could not parse occupants for channel in message : %@", string);
    }

    NSTextCheckingResult *result = [matches objectAtIndex:0];
    NSRange channelRange = [result rangeAtIndex:1];
    NSString *theChannel = [@"#" stringByAppendingString:[string substringWithRange:channelRange]];

    NSUInteger start = channelRange.location + channelRange.length + 2;
    NSUInteger remaining = string.length - start;
    NSString *nameString = [string substringWithRange:NSMakeRange(start, remaining)];
    NSArray *names = [nameString componentsSeparatedByString:@" "];

    NSMutableArray *cleanedNames = [[NSMutableArray alloc] init];
    [names enumerateObjectsUsingBlock:^(NSString *occupant, NSUInteger index, BOOL *stop) {
        [cleanedNames addObject:[occupant stringByReplacingOccurrencesOfString:@"@" withString:@""]];
    }];

    (* message).type = @"ChannelOccupants";
    (* message).payload = @{@"channel": theChannel, @"occupants": cleanedNames};
}

@end
