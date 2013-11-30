//
//  GLGFakeInputParserDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 11/29/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGFakeInputParserDelegate.h"

@implementation GLGFakeInputParserDelegate
- (void) didJoinChannel:(NSString *)channel
             rawCommand:(NSString *)command { }

- (void) didPartChannel:(NSString *)channel
             rawCommand:(NSString *)command { }

- (void) didChangeNick:(NSString *)newNick
            rawCommand:(NSString *)command{ }
- (void) didChangePassword:(NSString *)newPassword
                rawCommand:(NSString *)command{ }
@end
