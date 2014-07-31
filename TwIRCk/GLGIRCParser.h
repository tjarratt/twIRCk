//
//  GLGIRCParser.h
//  TwIRCk
//
//  Created by Tim Jarratt on 10/18/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGIRCMessage.h"

@interface GLGIRCParser : NSObject
+(GLGIRCMessage *) parseUserInput:(NSString *) string;
+(GLGIRCMessage *) parseRawIRCString:(NSString *) string;
@end
