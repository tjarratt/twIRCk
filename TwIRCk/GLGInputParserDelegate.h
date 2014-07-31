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
             rawCommand:(NSString *)command;
- (void) didPartChannel:(NSString *)channel
             rawCommand:(NSString *)channel;
- (void) didChangeNick:(NSString *)newNick
            rawCommand:(NSString *)channel;
- (void) didChangePassword:(NSString *)newPassword
                rawCommand:(NSString *)channel;
@end
