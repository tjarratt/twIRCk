//
//  GLGChatViewProvider.h
//  TwIRCk
//
//  Created by Tim Jarratt on 1/6/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGChatView.h"

@interface GLGChatViewProvider : NSObject
- (GLGChatView *) viewWithWindow:(NSWindow *) window delegate:(id) delegate;
@end
