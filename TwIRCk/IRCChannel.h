//
//  IRCChannel.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IRCServer;

@interface IRCChannel : NSManagedObject

@property (nonatomic, retain) IRCServer * server;
@property (nonatomic, retain) NSString * name;

@end
