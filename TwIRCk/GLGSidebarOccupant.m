//
//  GLGSidebarOccupant.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/30/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGSidebarOccupant.h"

@implementation GLGSidebarOccupant

@synthesize delegate;

- (void) mouseUp:(NSEvent *) theEvent {
    if (self.delegate) {
        [self.delegate clickedOnNick:[self stringValue]];
    }
}

@end
