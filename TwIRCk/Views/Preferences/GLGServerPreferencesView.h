//
//  GLGServerPreferencesView.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IRCServer.h"
#import "GLGFetchedServersController.h"

@interface GLGServerPreferencesView : NSView <NSTableViewDataSource, NSTableViewDelegate> {
    NSArray *currentServers;
    NSTableView *tableview;
    id <GLGFetchedServersController> serversController;
}

- (void) setFetchedServersController:(id <GLGFetchedServersController>) controller;

@end
