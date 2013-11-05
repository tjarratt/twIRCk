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

- (id) initWithFrame:(NSRect) rect {
    if (self = [super initWithFrame:rect]) {
        NSTrackingAreaOptions opts = NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect;
        NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect options:opts owner:self userInfo:nil];
        [self addTrackingArea:area];

        [self setWantsLayer:YES];
        self.layer.masksToBounds = YES;
        self.layer.frame = self.frame;

        [[self layer] setCornerRadius:5.0];
        [[self layer] setBorderColor:[[NSColor clearColor] CGColor]];
        [[self layer] setBorderWidth:1.0];

    }

    return self;
}

- (void) mouseUp:(NSEvent *) theEvent {
    if (self.delegate) {
        [self.delegate clickedOnNick:[self stringValue]];
    }
}

- (void) mouseEntered:(NSEvent *) theEvent {
    [[self layer] setBorderColor:[[NSColor twirckBlue] CGColor]];
}

- (void) mouseExited:(NSEvent *) theEvent {
    [[self layer] setBorderColor:[[NSColor clearColor] CGColor]];
}

@end
