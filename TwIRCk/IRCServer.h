//
//  IRCServer.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/15/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "IRCChannel.h"

@interface IRCServer : NSManagedObject

@property (nonatomic, retain) NSArray * channels;
@property (nonatomic, retain) NSString * hostname;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSString * username;
@property (nonatomic) BOOL useSSL;

@end
