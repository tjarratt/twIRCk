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
             rawCommand:(NSString *)command
         displayMessage:(NSString *)display { }

- (void) didPartChannel:(NSString *)channel
             rawCommand:(NSString *)command
         displayMessage:(NSString *)display { }

- (void) didPartCurrentChannelWithRawCommand:(NSString *)rawCommand
                              displayMessage:(NSString *)display { }

- (void) didChangeNick:(NSString *)newNick
            rawCommand:(NSString *)command
        displayMessage:(NSString *)display { }

- (void) didChangePassword:(NSString *)newPassword
                rawCommand:(NSString *)command
            displayMessage:(NSString *)display { }

- (void) didSendMessageToCurrentTargetWithRawCommand:(NSString *)rawCommand
                                      displayMessage:(NSString *)display { }

- (void) didSendMessageToTarget:(NSString *)channelOrUser
                     rawCommand:(NSString *)rawCommand
                 displayMessage:(NSString *)display { }

- (void) didSendUnknownMessageToCurrentTargetWithRawCommand:(NSString *)raw
                                             displayMessage:(NSString *)display { }

@end
