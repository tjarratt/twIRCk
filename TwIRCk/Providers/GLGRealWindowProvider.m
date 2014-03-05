//
//  GLGWindowProvider.m
//  TwIRCk
//
//  Created by Tim Jarratt on 1/6/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGRealWindowProvider.h"

@implementation GLGRealWindowProvider
- (NSWindow *) window {
    GLGAppDelegate *delegate = [NSApp delegate];

    return [delegate window];
}
@end
