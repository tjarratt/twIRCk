//
//  GLGChatViewProvider.m
//  TwIRCk
//
//  Created by Tim Jarratt on 1/6/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGChatViewProvider.h"

@implementation GLGChatViewProvider
- (GLGChatView *) viewWithWindow:(NSWindow *) window delegate:(id) delegate {
    return [[GLGChatView alloc] initWithWindow:window andDelegate:delegate];
}
@end
