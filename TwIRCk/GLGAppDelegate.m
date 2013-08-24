//
//  GLGAppDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGAppDelegate.h"

@implementation GLGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *) aNotification {
    responseLookup = [[GLGResponseCodes alloc] init];

    NSSize minSize = NSMakeSize(400, 80);
    NSSize maxSize = NSMakeSize(500, 300);
    [[self window] setMinSize:minSize];
    [[self window] setMaxSize:maxSize];

    NSView *contentView = [[self window] contentView];
    GLGNewServer *newServerView = [[GLGNewServer alloc] initWithSuperView:contentView];
    [contentView addSubview:newServerView];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end
