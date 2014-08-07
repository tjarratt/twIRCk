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
#import "GLGServerPreferencesView.h"
#import "GLGChannelPreferencesView.h"
#import "GLGPreferencesController.h"

@interface GLGPreferencesView : NSView {
    id <GLGFetchedServersController> fetchedServersController;
    GLGServerPreferencesView *serverView;
    GLGChannelPreferencesView *channelView;

}

- (void) setFetchedServersController:(GLGPreferencesController *) controller;

@end
