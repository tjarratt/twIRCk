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
    if ([self isPing:string]) {
        return [delegate shouldRespondToPingRequest];
    }
    else {
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^:([a-z0-9!~`_/|@:\\[\.\-]+) ([a-z0-9]+) (.+)" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];

        if ([matches count] == 0) {
            return NSLog(@"_______FAILED to parse message with regex: %@", string);
        }

        NSTextCheckingResult *channelMatch = [matches objectAtIndex:0];
        NSString *theSender = [string substringWithRange:[channelMatch rangeAtIndex:1]];
        NSString *theType = [string substringWithRange:[channelMatch rangeAtIndex:2]];
        NSString *theMessage = [string substringWithRange:[channelMatch rangeAtIndex:3]];

        if ([theType isEqualToString:@"433"]) {
            NSArray *components = [theMessage componentsSeparatedByString:@" "];
            NSString *unavailableNick = [components objectAtIndex:1];
            NSString *display = [NSString stringWithFormat:@"The nick '%@' is already in use. Attempting to use '%@_'", unavailableNick, unavailableNick];

            return [delegate receivedNickInUseWithDisplayMessage:display];
        }
        else if ([theType isEqualToString:@"353"]) {
            [self readChannelOccupantsFromString:theMessage];
        }
        else if ([theType isEqualToString:@"372"]) {
            [self readMOTDFromString:theMessage fromSender:theSender];
        }
        else if ([theType isEqualToString:@"NOTICE"]) {
            [self readNOTICEFromString:theMessage fromSender:theSender];
        }
        else if ([theType isEqualToString:@"QUIT"]) {
            [self readQuitFromString:theMessage fromUser:(NSString *)theSender];
        }
        else if ([theType isEqualToString:@"JOIN"]) {
            [self readJOINFromString:theMessage fromUser:(NSString *)theSender];
        }
        else if ([theType isEqualToString:@"PART"]) {
            [self readPARTFromString:theMessage fromUser:(NSString *)theSender];
        }
        else if ([theType isEqualToString:@"PRIVMSG"]) {
            [self readPRIVMSGFromString:theMessage fromUser:(NSString *)theSender];
        }
        else if ([theType isEqualToString:@"NICK"]) {
            NSString *newNick = [theMessage substringWithRange:NSMakeRange(1, theMessage.length - 1)];
            NSString *oldNick = [[theSender componentsSeparatedByString:@"!"] objectAtIndex:0];

            NSString *display = [NSString stringWithFormat:@"'%@' is now known as '%@'", oldNick, newNick];
            [delegate userWithNick:oldNick didChangeNickTo:newNick withDisplayMessage:display];
        }
        else {
            NSLog(@"unhandled response: %@", string);
            [delegate receivedUncategorizedMessage:string];
        }
    }
}

#pragma mark - Private
-(void) readQuitFromString:(NSString *)string fromUser:(NSString *) userInfo {
    NSArray *nameComponents = [userInfo componentsSeparatedByString:@"!"];
    NSString *shortName = [nameComponents objectAtIndex:0];
    NSString *fullName = [nameComponents objectAtIndex:1];

    NSUInteger indexOfColon = [string rangeOfString:@":"].location;
    NSString *reasonForQuit = [string substringWithRange:NSMakeRange(indexOfColon + 1, string.length - indexOfColon - 1)];
    NSString *displayMessage = [NSString stringWithFormat:@"%@ (%@) has quit (%@).", shortName, fullName, reasonForQuit];

    [delegate userDidQuit:shortName withMessage:displayMessage];
}

-(void) readPARTFromString:(NSString *)string fromUser:(NSString *)userInfo {
    NSUInteger indexOfColon = [string rangeOfString:@":"].location;
    NSString *channel;
    NSString *partMessage;

    if (indexOfColon > 0 && indexOfColon < string.length) {
        channel = [string substringWithRange:NSMakeRange(0, indexOfColon -1)];
        partMessage = [string substringWithRange:NSMakeRange(indexOfColon + 1, string.length - indexOfColon - 1)];
        if (partMessage.length > 0) {
            partMessage = [NSString stringWithFormat:@" (%@)", partMessage];
        }
    }
    else {
        channel = string;
        partMessage = @"";
    }

    NSArray *nameComponents = [userInfo componentsSeparatedByString:@"!"];
    NSString *shortName = [nameComponents objectAtIndex:0];
    NSString *fullName = [nameComponents objectAtIndex:1];
    NSString *displayMessage = [NSString stringWithFormat:@"%@ (%@) has left%@.", shortName, fullName, partMessage];

    [delegate userWithNick:shortName didPartChannel:channel withFullNick:fullName andPartMessage:displayMessage];
}

-(void) readJOINFromString:(NSString *)string  fromUser:(NSString *)userInfo {
    NSArray *nameComponents = [userInfo componentsSeparatedByString:@"!"];
    NSString *shortName = [nameComponents objectAtIndex:0];
    NSString *longName = [nameComponents objectAtIndex:1];
    NSString *displayMessage = [NSString stringWithFormat:@"%@ (%@) has joined.", shortName, longName];

    [delegate userWithNick:shortName
    didJoinChannel:string
      withFullName:[nameComponents objectAtIndex:1]
withDisplayMessage:displayMessage];
}

-(void) readPRIVMSGFromString:(NSString *)string fromUser:(NSString *)userInfo {
    NSArray *nameComponents = [userInfo componentsSeparatedByString:@"!"];
    NSString *shortName = [nameComponents objectAtIndex:0];

    NSUInteger firstSpace = [string rangeOfString:@" "].location;
    NSString *channelName = [string substringWithRange:NSMakeRange(0, firstSpace)];
    NSString *theMessage = [string substringWithRange:NSMakeRange(firstSpace + 2, string.length - firstSpace - 2)];

    NSString *displayMessage = [NSString stringWithFormat:@"<%@> %@", shortName, theMessage];

    [delegate receivedPrivateMessage:displayMessage
                            fromNick:shortName
                           inChannel:channelName];
}

-(void) readMOTDFromString:(NSString *)string fromSender:(NSString *) sender {
    [delegate receivedMOTDMessage:[[string substringFromIndex:[string rangeOfString:@":"].location + 3] stringByAppendingString:@"\n"]];
}

-(void) readNOTICEFromString:(NSString *)string fromSender:(NSString *) sender {
    NSUInteger startIndex = [string rangeOfString:@":"].location;
    [delegate receivedNoticeMessage:[[string substringFromIndex:startIndex + 1] stringByAppendingString:@"\n"] inChannel:sender];
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
