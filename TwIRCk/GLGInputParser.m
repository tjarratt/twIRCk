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

            if (![[channel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                channel = [@"#" stringByAppendingString:channel];
            }
            raw = [NSString stringWithFormat:@"JOIN %@", channel];
            message = [@"/join " stringByAppendingString:channel];

            return [delegate didJoinChannel:channel
                                 rawCommand:raw
                             displayMessage:message];
        }
        else if ([command isEqualToString:@"part"]) {
            NSString *theChannel;

            if (parts.count == 1) {
                NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)";
                raw = [NSString stringWithFormat:@"PART <__channel__> %@", defaultMessage];
                message = [NSString stringWithFormat:@"/part <__channel__> %@", defaultMessage];

                return [delegate didPartCurrentChannelWithRawCommand:raw
                                                      displayMessage:message];
            }
            else if (parts.count == 2) {
                theChannel = [parts objectAtIndex:1];
                if (![[theChannel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                    theChannel = [@"#" stringByAppendingString:theChannel];
                }

                NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)";
                raw = [NSString stringWithFormat:@"PART %@ %@", theChannel, defaultMessage];
                message = [NSString stringWithFormat:@"/part %@ %@", theChannel, defaultMessage];

                return [delegate didPartChannel:theChannel
                                     rawCommand:raw
                                 displayMessage:message];
            }
            else {
                theChannel = [[parts objectAtIndex:1] lowercaseString];
                if (![[theChannel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                    theChannel = [@"#" stringByAppendingString:theChannel];
                }

                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
                parts = [parts objectsAtIndexes:indices];
                NSString *remainder = [parts componentsJoinedByString:@" "];

                raw = [NSString stringWithFormat:@"PART %@ %@", theChannel, remainder];
                message = [NSString stringWithFormat:@"/part %@ %@", theChannel, remainder];

                return [delegate didPartChannel:theChannel
                                     rawCommand:raw
                                 displayMessage:message];
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
            if ([parts count] < 2) {
                return [self displayUsageForSlashWho];
            }
            else {
                NSString *whom = [parts objectAtIndex:1];
                if (whom.length == 0) {
                    return [self displayUsageForSlashWho];
                }

                raw = [@"WHO " stringByAppendingString:whom];
                message = [NSString stringWithFormat:@"/who %@", whom];

                return [delegate didSendMessageToCurrentTargetWithRawCommand:raw
                                                              displayMessage:message];
            }
        }
        else if ([command isEqualToString:@"me"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];

            // should have 0x01 at the beginning and end (before ACTION and after remainder)
            raw = [@"ACTION " stringByAppendingString:remainder];
            message = [NSString stringWithFormat:@"/me %@", remainder];

            return [delegate didSendMessageToTarget:@"<__channel__>"
                                         rawCommand:raw
                                     displayMessage:message];
        }
        else if ([command isEqualToString:@"nick"]) {
            NSString *newNick = [parts objectAtIndex:1];

            raw = [@"NICK " stringByAppendingString:newNick];
            message = [NSString stringWithFormat:@"/nick %@", newNick];

            return [delegate didChangeNick:newNick
                                rawCommand:raw
                            displayMessage:message];
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
            NSString *remainder = [[parts objectsAtIndexes:indices] componentsJoinedByString:@" "];

            raw = [NSString stringWithFormat:@"TOPIC <__channel__> %@", remainder];
            message = string;

            return [delegate didSendMessageToCurrentTargetWithRawCommand:raw
                                                          displayMessage:message];
        }
        else {
            NSString *fullCommand = [command uppercaseString];
            if ([parts count] > 1) {
                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(1, parts.count - 1)];
                NSArray *mutableParts = [parts objectsAtIndexes:indices];
                fullCommand = [[fullCommand stringByAppendingString:@" "] stringByAppendingString: [mutableParts componentsJoinedByString:@" "]];

                raw = fullCommand;
                message = string;

                return [delegate didSendUnknownMessageToCurrentTargetWithRawCommand:raw
                                                                     displayMessage:message];
            }
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

@end
