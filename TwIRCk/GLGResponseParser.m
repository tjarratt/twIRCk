//
//  GLGResponseParser.m
//  TwIRCk
//
//  Created by Tim Jarratt on 11/29/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGResponseParser.h"

@implementation GLGResponseParser

- (void) setDelegate:(id <GLGResponseParserDelegate>) _delegate {
    delegate = _delegate;
}

-(void) parseRawIRCString:(NSString *) string {
//    GLGIRCMessage *msg = [[GLGIRCMessage alloc] init];
//    [msg setFromHost:[self readHostnameFromString:string]];
//

    if ([self isPing:string]) {
        return [delegate shouldRespondToPingRequest];
    }
    else {
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^:([a-z0-9!~`_/|@:\\[\.\-]+) ([a-z0-9]+) (.+)" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];

        if ([matches count] == 0) {
            NSLog(@"_______FAILED to parse message with regex: %@", string);
//            [msg setType:@"error"];
//            [msg setRaw:string];
//            return msg;
        }

        NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];
        NSString *theSender = [string substringWithRange:[channelMatch rangeAtIndex:1]];
        NSString *theType = [string substringWithRange:[channelMatch rangeAtIndex:2]];
        NSString *theMessage = [string substringWithRange:[channelMatch rangeAtIndex:3]];

        // when you connect to some servers eg: chat.freenode.net, your requests will actually
        // be handled by what is effectively a mirror, or a shard eg: hitchcock.
//        [msg setFromHost:theSender];

        if ([theType isEqualToString:@"433"]) {
            return [delegate receivedNickInUse];
        }
        else if ([theType isEqualToString:@"353"]) {
            [self readChannelOccupantsFromString:theMessage];
        }
        else if ([theType isEqualToString:@"372"]) {
            [self readMOTDFromString:theMessage];
        }
        else if ([theType isEqualToString:@"NOTICE"]) {
            [self readNOTICEFromString:theMessage];
        }
        else if ([theType isEqualToString:@"QUIT"]) {
            [self readQuitFromString:theMessage];
        }
        else if ([theType isEqualToString:@"JOIN"]) {
            [self readJOINFromString:theMessage];
        }
        else if ([theType isEqualToString:@"PART"]) {
            [self readPARTFromString:theMessage];
        }
        else if ([theType isEqualToString:@"PRIVMSG"]) {
            [self readPRIVMSGFromString:theMessage];
        }
        else if ([theType isEqualToString:@"NICK"]) {
            NSString *newNick = [theMessage substringWithRange:NSMakeRange(1, theMessage.length - 1)];
            NSString *oldNick = [[theSender componentsSeparatedByString:@"!"] objectAtIndex:0];

            [delegate user:oldNick didChangeNickTo:newNick];
        }
        else {
            NSLog(@"unhandled response: %@", theMessage);
            [delegate receivedUncategorizedMessage:theMessage];
        }
    }
}

#pragma mark - Private
-(void) readQuitFromString:(NSString *)string {
    [delegate userDidQuit:nil withMessage:nil];
}

-(void) readPARTFromString:(NSString *)string {
    [delegate user:nil didPartChannel:nil withFullNick:nil];
}

-(void) readJOINFromString:(NSString *)string {
    [delegate user:nil didJoinChannel:nil withFullName:nil];
}

-(void) readPRIVMSGFromString:(NSString *)string {
    [delegate receivedPrivateMessage:nil fromNick:nil];
}

-(void) readMOTDFromString:(NSString *)string {
    [delegate receivedMOTDMessage:[[string substringFromIndex:[string rangeOfString:@":"].location + 3] stringByAppendingString:@"\n"]];
}

-(void) readNOTICEFromString:(NSString *)string {
    NSUInteger startIndex = [string rangeOfString:@":"].location;
    // TODO: in channel?
    [delegate receivedNoticeMessage:[[string substringFromIndex:startIndex + 1] stringByAppendingString:@"\n"] inChannel:nil];
}

-(BOOL) isPing:(NSString *) maybePing {
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
        return nil;
    }

    NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];
    return [string substringWithRange:[channelMatch rangeAtIndex:1]];
}

-(void) readChannelOccupantsFromString:(NSString *)string {
    // read the channel and all of the occupants
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(.*) :" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];

    if (matches.count == 0) {
        NSLog(@"no matches for occupants");
        return;
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

    [delegate channel:theChannel didUpdateOccupants:cleanedNames];
}
@end
