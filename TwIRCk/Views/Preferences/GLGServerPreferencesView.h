//
//  GLGServerPreferencesView.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IRCServer.h"

@interface GLGServerPreferencesView : NSView <NSTableViewDataSource, NSTableViewDelegate> {
    NSArray *currentServers;
}

@end
