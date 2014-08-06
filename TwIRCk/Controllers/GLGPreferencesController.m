//
//  GLGPreferencesController.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGPreferencesController.h"

@implementation GLGPreferencesController

- (instancetype) init {
    if (self = [super init]) {
        servers = [GLGManagedObjectContext currentServers];
    }

    return self;
}

- (IRCServer *) serverAtIndexPath:(NSUInteger)index {
    return [servers objectAtIndex:index];
}

@end
