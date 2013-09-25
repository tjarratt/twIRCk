//
//  IRCChannel.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "IRCChannel.h"


@implementation IRCChannel

@dynamic name;
@dynamic server;
@dynamic autojoin;

- (NSString *) properName {
    if (![[self.name substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
        return [@"#" stringByAppendingString:self.name];
    }
    else {
        return self.name;
    }
}

@end
