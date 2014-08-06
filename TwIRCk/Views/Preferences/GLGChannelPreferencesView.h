//
//  GLGChannelPreferencesView.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGLabelView.h"
#import "IRCServer.h"
#import "GLGPreferencesController.h"

@interface GLGChannelPreferencesView : NSView <NSTableViewDelegate, NSTableViewDataSource> {
    NSTableView *tableView;
    GLGPreferencesController *controller;
}

- (void) setChannelsBinding:(id) source;

@end
