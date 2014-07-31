//
//  GLGIRCMessage.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLGIRCMessage : NSObject

@property(retain) NSString *type;
@property(retain) NSString *message;
@property(retain) NSString *target;
@property(retain) NSString *raw;
@property(retain) id payload;
@property(retain) NSString *fromHost;

-(void) interpolateChannel:(NSString *) channel andNick:(NSString *) nick;

@end
