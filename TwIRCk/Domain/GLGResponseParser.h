//
//  GLGResponseParser.h
//  TwIRCk
//
//  Created by Tim Jarratt on 11/29/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGResponseParserDelegate.h"

@interface GLGResponseParser : NSObject {
    id<GLGResponseParserDelegate> delegate;
}

- (void) setDelegate:(id <GLGResponseParserDelegate>) _delegate;
- (void) parseRawIRCString:(NSString *) string;
@end
