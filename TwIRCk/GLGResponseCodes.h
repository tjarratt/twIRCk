//
//  GLGResponseCodes.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGErrorMessage.h"
#import "GLGReplyMessage.h"

@interface GLGResponseCodes : NSObject {
    NSDictionary *codes;
}

- (GLGReplyMessage *) replyForCode:(NSNumber *) code;
@end
