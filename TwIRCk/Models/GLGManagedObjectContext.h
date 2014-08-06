//
//  GLGManagedObjectContext.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/18/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "IRCserver.h"

@interface GLGManagedObjectContext : NSObject
+ (NSManagedObjectContext *) managedObjectContext;
+ (NSArray *) currentServers;
@end
