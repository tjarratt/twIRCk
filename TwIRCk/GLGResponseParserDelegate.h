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

- (void)user:(NSString *)oldNick didChangeNickTo:(NSString *) newNick;
- (void)user:(NSString *)nick didJoinChannel:(NSString *) channel withFullName:(NSString *)longNick;
- (void)user:(NSString *)nick didPartChannel:(NSString *) channel withFullNick:(NSString *)longNick;
- (void)userDidQuit:(NSString *) nick withMessage:(NSString *) quitMessage;

- (void)channel:(NSString *) theChannel didUpdateOccupants:(NSArray *) occupants;

- (void)receivedPrivateMessage:(NSString *) privateMessage fromNick:(NSString *) nick;
- (void)receivedNickInUse;
- (void)receivedUncategorizedMessage:(NSString *) message;

@end
