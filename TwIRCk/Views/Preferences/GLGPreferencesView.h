//
//  GLGPreferencesView.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/3/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGFetchedServersController.h"
#import "GLGManagedObjectContext.h"
#import "IRCServer.h"

@interface GLGPreferencesView : NSView {
    NSTableView *tableview;
    id <GLGFetchedServersController> fetchedServersController;

}

- (NSTableView *) tableview;
- (void) setFetchedServersController:(id <GLGFetchedServersController>) controller;

@end
