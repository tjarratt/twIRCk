//
//  GLGServer.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLGServer : NSObject

@property NSString *hostname;
@property NSInteger port;
@property BOOL useSSL;
@property NSString *username;
@property NSString *password;
@property NSArray *channels;

@end
