//
//  GLGIRCParser.h
//  TwIRCk
//
//  Created by Tim Jarratt on 10/18/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGIRCMessage.h"
#import "GLGInputParserDelegate.h"

@interface GLGInputParser : NSObject {
    id<GLGInputParserDelegate> delegate;
}


-(void) setDelegate:(id<GLGInputParserDelegate>) delegate;
-(void) parseUserInput:(NSString *) string;
@end
