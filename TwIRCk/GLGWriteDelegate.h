//
//  GLGWriteDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLGWriteDelegate : NSObject <NSStreamDelegate> {
    NSMutableArray *commands;
}

- (void) addCommand:(NSString *) command;

@end
