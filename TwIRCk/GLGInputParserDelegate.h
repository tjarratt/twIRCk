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
             rawCommand:(NSString *)rawCommand;
- (void) didPartChannel:(NSString *)channel
             rawCommand:(NSString *)rawCommand;
- (void) didChangeNick:(NSString *)newNick
            rawCommand:(NSString *)rawCommand;
- (void) didChangePassword:(NSString *)newPassword
                rawCommand:(NSString *)rawCommand;
@end
