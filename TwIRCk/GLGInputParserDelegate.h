//
//  GLGInputParserDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 11/29/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GLGInputParserDelegate <NSObject>

- (void) didJoinChannel:(NSString *)channel
             rawCommand:(NSString *)rawCommand
         displayMessage:(NSString *)display;

- (void) didPartChannel:(NSString *)channel
             rawCommand:(NSString *)rawCommand
         displayMessage:(NSString *)display;

- (void) didPartCurrentChannelWithRawCommand:(NSString *)raw
                              displayMessage:(NSString *)display;

- (void) didChangeNick:(NSString *)newNick
            rawCommand:(NSString *)rawCommand
        displayMessage:(NSString *)display;

- (void) didChangePassword:(NSString *)newPassword
                rawCommand:(NSString *)rawCommand
            displayMessage:(NSString *)display;

- (void) didSendMessageToTarget:(NSString *)channelOrUser
                     rawCommand:(NSString *)rawCommand
                 displayMessage:(NSString *)display;

- (void) didSendMessageToCurrentTargetWithRawCommand:(NSString *)rawCommand
                                      displayMessage:(NSString *)display;

- (void) didSendUnknownMessageToCurrentTargetWithRawCommand:(NSString *)raw
                                             displayMessage:(NSString *)display;
@end
