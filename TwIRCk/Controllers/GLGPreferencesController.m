//
//  GLGPreferencesController.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGPreferencesController.h"

@implementation GLGPreferencesController

// FIXME: see https://stackoverflow.com/questions/16224257/programmatically-bind-a-nstableview
- (instancetype) init {
    if (self = [super init]) {
        servers = [GLGManagedObjectContext currentServers];
    }

    return self;
}

#pragma mark - GLGFetchedServersController
- (NSArray *) currentServers {
    return servers;
}

- (IRCServer *) serverAtIndexPath:(NSUInteger)index {
    return [servers objectAtIndex:index];
}

- (IRCServer *) selectedServer {
    return selectedServer;
}

#pragma mark - NSArrayController
- (BOOL) setSelectionIndex:(NSUInteger) index {
    BOOL result = [super setSelectionIndex:index];
    if (result) {
        selectedServer = [servers objectAtIndex:index];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"preferences.server.selection.changed" object:nil];
    } else {
        selectedServer = nil;
    }

    return result;
}


@end
