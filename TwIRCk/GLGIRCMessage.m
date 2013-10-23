//
//  GLGIRCMessage.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGIRCMessage.h"

@implementation GLGIRCMessage

-(void) interpolateChannel:(NSString *) channel andNick:(NSString *) nick {
    [self setRaw:[[self.raw stringByReplacingOccurrencesOfString:@"<__channel__>" withString:channel] stringByReplacingOccurrencesOfString:@"<__nick__>" withString:nick]];
    [self setMessage:[[self.message stringByReplacingOccurrencesOfString:@"<__channel__>" withString:channel] stringByReplacingOccurrencesOfString:@"<__nick__>" withString:nick]];
    [self setTarget:[self.target stringByReplacingOccurrencesOfString:@"<__channel__>" withString:channel]];
}

@end
