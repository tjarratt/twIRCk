//
//  GLGFetchedServersController.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/4/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRCServer.h"

@protocol GLGFetchedServersController <NSObject>
- (NSArray *) currentServers;
- (IRCServer *) serverAtIndexPath:(NSUInteger) index;
@end
