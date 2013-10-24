//
//  GLGIRCParser.m
//  TwIRCk
//
//  Created by Tim Jarratt on 10/18/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGIRCParser.h"

@implementation GLGIRCParser

+(GLGIRCMessage *) parseString:(NSString *) string {
    GLGIRCMessage *ircMessage = [[GLGIRCMessage alloc] init];
    [ircMessage setTarget:@"<__channel__>"];

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

            [ircMessage setType:@"join"];
            [ircMessage setRaw:[NSString stringWithFormat:@"JOIN %@", channel]];
            [ircMessage setMessage:[NSString stringWithFormat:@"/join %@", channel]];
            [ircMessage setPayload:channel];

        }
        else if ([command isEqualToString:@"part"]) {
            NSString *theChannel;

            if (parts.count == 1) {
                theChannel = @"<__channel__>";
                NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)";

                [ircMessage setType:@"part"];
                [ircMessage setRaw:[NSString stringWithFormat:@"PART <__channel__> %@", defaultMessage]];
                [ircMessage setMessage:[NSString stringWithFormat:@"/part <__channel__> %@", defaultMessage]];
            }
            else if (parts.count == 2) {
                theChannel = [parts objectAtIndex:1];
                if (![[theChannel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                    theChannel = [@"#" stringByAppendingString:theChannel];
                }

                NSString *defaultMessage = @"http://twIRCk.com (sometimes you just gotta twIRCk it!)";

                [ircMessage setType:@"part"];
                [ircMessage setRaw:[NSString stringWithFormat:@"PART %@ %@", theChannel, defaultMessage]];
                [ircMessage setMessage:[NSString stringWithFormat:@"/part %@ %@", theChannel, defaultMessage]];
            }
            else {
                theChannel = [[parts objectAtIndex:1] lowercaseString];
                if (![[theChannel substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
                    theChannel = [@"#" stringByAppendingString:theChannel];
                }

                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
                parts = [parts objectsAtIndexes:indices];
                NSString *remainder = [parts componentsJoinedByString:@" "];

                [ircMessage setType:@"part"];
                [ircMessage setRaw:[NSString stringWithFormat:@"PART %@ %@", theChannel, remainder]];
                [ircMessage setMessage:[NSString stringWithFormat:@"/part %@ %@", theChannel, remainder]];
            }
            [ircMessage setPayload: theChannel];
        }
        else if ([command isEqualToString:@"msg"] || [command isEqualToString:@"whisper"]) {
            NSString *whom = [parts objectAtIndex:1];
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];

            [ircMessage setType:@"msg"];
            [ircMessage setRaw:[NSString stringWithFormat:@"PRIVMSG %@ :%@", whom, remainder]];
            [ircMessage setMessage:[NSString stringWithFormat:@"<<__nick__>> %@", remainder]];
            [ircMessage setTarget:whom];
        }
        else if ([command isEqualToString:@"who"]) {
            if ([parts count] < 2) {
                [ircMessage setRaw:@""];
                [ircMessage setMessage:@"/who\nWHO: not enough parameters\nusage: /who {channel}"];
            }
            else {
                NSString *whom = [parts objectAtIndex:1];
                [ircMessage setType:@"who"];
                [ircMessage setRaw:[@"WHO " stringByAppendingString:whom]];
                [ircMessage setMessage:[NSString stringWithFormat:@"/who %@", whom]];
                [ircMessage setTarget:whom];
            }
        }
        else if ([command isEqualToString:@"me"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(2, [parts count] - 2)];
            parts = [parts objectsAtIndexes:indices];
            NSString *remainder = [parts componentsJoinedByString:@" "];

            [ircMessage setType:@"me"];
            [ircMessage setRaw:[@"ACTION " stringByAppendingString:remainder]];
            [ircMessage setMessage:[NSString stringWithFormat:@"/me %@", remainder]];
        }
        else if ([command isEqualToString:@"nick"]) {
            NSString *newNick = [parts objectAtIndex:1];

            [ircMessage setType:@"nick"];
            [ircMessage setRaw:[@"NICK " stringByAppendingString:newNick]];
            [ircMessage setMessage:[NSString stringWithFormat:@"/nick %@", newNick]];
            [ircMessage setPayload:newNick];
        }
        else if ([command isEqualToString:@"pass"]) {
            NSString *newPassword = [parts objectAtIndex:1];

            [ircMessage setType:@"pass"];
            [ircMessage setRaw:[@"PASS " stringByAppendingString:newPassword]];
            [ircMessage setMessage:[NSString stringWithFormat:@"/pass %@", newPassword]];
            [ircMessage setPayload:newPassword];
        }
        else if ([command isEqualToString:@"topic"]) {
            NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(1, parts.count - 1)];
            NSString *remainder = [[parts objectsAtIndexes:indices] componentsJoinedByString:@" "];

            [ircMessage setType:@"topic"];
            [ircMessage setRaw:[NSString stringWithFormat:@"TOPIC <__channel__> %@", remainder]];
            [ircMessage setMessage:string];
        }
        else {
            NSString *fullCommand = [command uppercaseString];
            if ([parts count] > 1) {
                NSIndexSet *indices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(1, parts.count - 1)];
                NSArray *mutableParts = [parts objectsAtIndexes:indices];
                fullCommand = [[fullCommand stringByAppendingString:@" "] stringByAppendingString: [mutableParts componentsJoinedByString:@" "]];
            }

            [ircMessage setType:command];
            [ircMessage setRaw:fullCommand];
            [ircMessage setMessage:string];
        }
    }
    else {
        [ircMessage setType:@"msg"];
        [ircMessage setRaw:[NSString stringWithFormat:@"PRIVMSG <__channel__> :%@", string]];
        [ircMessage setMessage:[NSString stringWithFormat:@"<<__nick__>> %@", string]];
    }

    return ircMessage;
}
@end
