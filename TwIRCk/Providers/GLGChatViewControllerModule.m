//
//  GLGChatViewControllerModule.m
//  TwIRCk
//
//  Created by Tim Jarratt on 1/6/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGChatViewControllerModule.h"

@implementation GLGChatViewControllerModule

- (void) configure:(id) binder {
    [binder bind:@"window" toInstance:[[GLGWindowProvider alloc] init]];
    [binder bind:@"brokerProvider" toInstance:[[GLGIRCBrokerProvider alloc] init]];
    [binder bind:@"chatViewProvider" toInstance:[[GLGChatViewProvider alloc] init]];
}

@end
