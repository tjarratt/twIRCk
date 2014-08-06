//
//  GLGPreferencesController.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGFetchedServersController.h"
#import "GLGManagedObjectContext.h"
#import "IRCServer.h"

@interface GLGPreferencesController : NSObject <GLGFetchedServersController> {
    NSArray *servers;
}

@end
