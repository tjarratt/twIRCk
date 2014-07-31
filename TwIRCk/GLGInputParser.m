//
//  GLGIRCParser.m
//  TwIRCk
//
//  Created by Tim Jarratt on 10/18/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGInputParser.h"

@implementation GLGInputParser

-(void) setDelegate:(id<GLGInputParserDelegate>) _delegate {
    delegate = _delegate;
}

-(void) parseUserInput:(NSString *) string {
    NSString *raw, *message;

    if ([[string substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"] ) {
        NSUInteger length = [string length];
        NSString *substring = [string substringWithRange:NSMakeRange(1, length - 1)];
        NSArray *parts = [substring componentsSeparatedByString:@" "];
        NSString *command = [[parts objectAtIndex:0] lowercaseString];

        if ([command isEqualToString:@"join"]) {
            NSString *channel = [[parts objectAtIndex:1] lowercaseString];
            return [self createJoinCommandForChannel:channel];
        }
        else if ([command isEqualToString:@"part"]) {
            NSString *theChannel;

            if (parts.count == 1) {
                return [self createPartCommandForCurrentChannel];
            }
            else if (parts.count == 2) {
                theChannel = [parts objectAtIndex:1];
                return [self createPartCommandForChannel:theChannel];
            }
            else {
                theChannel = [[parts objectAtIndex:1] lowercaseString];
                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
                parts = [parts objectsAtIndexes:indices];
                NSString *remainder = [parts componentsJoinedByString:@" "];

                return [self createPartCommandForChannel:theChannel withMessage:remainder];
            }
        }
        else if ([command isEqualToString:@"msg"] || [command isEqualToString:@"whisper"]) {
            NSString *whom = [parts objectAtIndex:1];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];

            raw = [NSString stringWithFormat:@"PRIVMSG %@ :%@", whom, remainder];
            message = [NSString stringWithFormat:@"<<__nick__>> %@", remainder];

            return [delegate didSendMessageToTarget:whom
                                         rawCommand:raw
                                     displayMessage:message];
        }
        else if ([command isEqualToString:@"who"]) {
            return [self createWhoCommandFromArray:parts];
        }
        else if ([command isEqualToString:@"me"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            return [self createActionCommandFromArray:[parts objectsAtIndexes:indices]];
        }
        else if ([command isEqualToString:@"nick"]) {
            return [self createNickCommandForNewNick:[parts objectAtIndex:1]];
        }
        else if ([command isEqualToString:@"pass"]) {
            NSString *newPassword = [parts objectAtIndex:1];
            raw = [@"PASS " stringByAppendingString:newPassword];

            return [delegate didChangePassword:newPassword
                                    rawCommand:raw
                                displayMessage:@"/pass ********"];
        }
        else if ([command isEqualToString:@"topic"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(1, parts.count - 1)];
            return [self createTopicCommandFromArray:[parts objectsAtIndexes:indices]];
        }
        else {
            [self createUnknownCommandFromCommand:command andParts:parts];
        }
    }
    else {
        raw = [NSString stringWithFormat:@"PRIVMSG <__channel__> :%@", string];
        message = [NSString stringWithFormat:@"<<__nick__>> %@", string];

        return [delegate didSendMessageToCurrentTargetWithRawCommand:raw
                                                      displayMessage:message];
    }
}

#pragma mark - Private

- (void) displayUsageForSlashWho {
    NSString *message = @"/who\nWHO: not enough parameters (usage: /who {channel})";

    return [delegate didSendMessageToCurrentTargetWithRawCommand:@""
                                                  displayMessage:message];

}

- (void) createJoinCommandForChannel:(NSString *) channel {
    if (![[channel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
        channel = [@"#" stringByAppendingString:channel];
    }

    NSString *raw = [NSString stringWithFormat:@"JOIN %@", channel];
    NSString *message = [@"/join " stringByAppendingString:channel];

    return [delegate didJoinChannel:channel
                         rawCommand:raw
                     displayMessage:message];
}

- (void) createPartCommandForCurrentChannel {
    NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)";
    NSString *raw = [NSString stringWithFormat:@"PART <__channel__> %@", defaultMessage];
    NSString *message = [NSString stringWithFormat:@"/part <__channel__> %@", defaultMessage];

    [delegate didPartCurrentChannelWithRawCommand:raw
                                   displayMessage:message];
}

- (void) createPartCommandForChannel:(NSString *) channel {
    NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)"; // TODO: static var
    [self createPartCommandForChannel:channel withMessage:defaultMessage];
}

- (void) createPartCommandForChannel:(NSString *) channel withMessage:(NSString *) message {
    if (![[channel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
        channel = [@"#" stringByAppendingString:channel];
    }

    NSString *raw = [NSString stringWithFormat:@"PART %@ %@", channel, message];
    NSString *displayMessage = [NSString stringWithFormat:@"/part %@ %@", channel, message];

    return [delegate didPartChannel:channel
                         rawCommand:raw
                     displayMessage:displayMessage];
}

- (void) createUnknownCommandFromCommand:(NSString *) command andParts:(NSArray *) parts {
    NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(1, parts.count - 1)];
    NSString *remainder = [[parts objectsAtIndexes:indices] componentsJoinedByString:@" "];
    NSString *raw = [[[command uppercaseString] stringByAppendingString:@" "] stringByAppendingString: remainder];
    NSString *display = [NSString stringWithFormat:@"/%@ %@", command, remainder];

    return [delegate didSendUnknownMessageToCurrentTargetWithRawCommand:raw
                                                         displayMessage:display];
}

- (void) createActionCommandFromArray:(NSArray *) parts {
    NSString *remainder = [parts componentsJoinedByString:@" "];

    // TODO: should have 0x01 at the beginning and end (before ACTION and after remainder)
    NSString *byte = @""; // @"\u0001";
    NSString *raw = [NSString stringWithFormat:@"%@ACTION %@%@", byte, remainder, byte];
    NSString *message = [NSString stringWithFormat:@"/me %@", remainder];

    return [delegate didSendMessageToTarget:@"<__channel__>"
                                 rawCommand:raw
                             displayMessage:message];

}

- (void) createNickCommandForNewNick:(NSString *) nick {
    return [delegate didChangeNick:nick
                        rawCommand:[@"NICK " stringByAppendingString:nick]
                    displayMessage:[NSString stringWithFormat:@"/nick %@", nick]];
}

- (void) createTopicCommandFromArray:(NSArray *) parts {
    NSString *remainder = [parts componentsJoinedByString:@" "];
    return [delegate didSendMessageToCurrentTargetWithRawCommand:[NSString stringWithFormat:@"TOPIC <__channel__> %@", remainder]
                                                  displayMessage:[@"/topic " stringByAppendingString:remainder]];
}

- (void) createWhoCommandFromArray:(NSArray *) parts {
    if ([parts count] < 2) {
        return [self displayUsageForSlashWho];
    }
    else {
        NSString *whom = [parts objectAtIndex:1];
        if (whom.length == 0) { return [self displayUsageForSlashWho]; }

        return [delegate didSendMessageToCurrentTargetWithRawCommand:[@"WHO " stringByAppendingString:whom]
                                                      displayMessage:[NSString stringWithFormat:@"/who %@", whom]];
    }
}

@end
