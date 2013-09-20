//
//  GLGBrokerDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/19/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GLGBrokerDelegate <NSObject>
@required
-(void) connectedToServer:(NSString *)hostname;
-(void) joinChannel:(NSString *)channel onServer:(NSString *)hostname userInitiated:(BOOL)initiatedByUser;
-(void) receivedString:(NSString *) string inChannel:(NSString *) channel fromHost:(NSString *) host;
-(void) didPartChannel:(NSString *) channel;
-(void) willPartChannel:(NSString *) channel;
@end
