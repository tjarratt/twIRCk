//
//  GLGManagedObjectContext.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/18/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

@interface GLGManagedObjectContext : NSObject
+ (NSManagedObjectContext *) managedObjectContext;
@end
