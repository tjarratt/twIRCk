//
//  GLGResponseParserDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 10/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGIRCMessage.h"

@protocol GLGResponseParserDelegate <NSObject>
- (void)shouldRespondToPingRequest;
- (void)receivedNoticeMessage:(NSString *) notice inChannel:(NSString *) channel;
- (void)receivedMOTDMessage:(NSString *) motd;

- (void)userWithNick:(NSString *)oldNick didChangeNickTo:(NSString *) newNick withDisplayMessage:(NSString *) displayMessage;
- (void)userWithNick:(NSString *)nick didJoinChannel:(NSString *) channel withFullName:(NSString *)longNick withDisplayMessage:(NSString *) displayMesssage;
- (void)userWithNick:(NSString *)nick didPartChannel:(NSString *) channel withFullNick:(NSString *)longNick andPartMessage:(NSString *) displayMessage;
- (void)userDidQuit:(NSString *) nick withMessage:(NSString *) quitMessage;

- (void)channel:(NSString *) theChannel didUpdateOccupants:(NSArray *) occupants;

- (void)receivedPrivateMessage:(NSString *) privateMessage
                      fromNick:(NSString *) nick
                     inChannel:(NSString *) channelName;

- (void)receivedNickInUseWithDisplayMessage:(NSString *) displayMessage;
- (void)receivedUncategorizedMessage:(NSString *) message;

@end
