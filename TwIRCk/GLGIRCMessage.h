//
//  GLGIRCMessage.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLGIRCMessage : NSObject

@property NSString *type;
@property NSString *message;
@property NSString *target;
@property NSString *raw;
@property id payload;
@property NSString *fromHost;

-(void) interpolateChannel:(NSString *) channel andNick:(NSString *) nick;

@end
