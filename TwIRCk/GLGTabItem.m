//
//  GLGTabItem.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGTabItem.h"

@implementation GLGTabItem

- (id)initWithFrame:(NSRect)frame andLabel:(NSString *) theLabel {
    if (self = [super initWithFrame:frame]) {
        [self setName:theLabel];
        [self setSelected:NO];
        [self setHover:NO];

        [self setIdentifier:[theLabel stringByAppendingString:@"-tab-item"]];
        [[self cell] setControlSize:NSSmallControlSize];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setAlignment:NSCenterTextAlignment];
        [self setBordered:NO];
        [self setBezeled:NO];
        [self setSelectable:NO];
        [self setEditable:NO];
        [self setFont:[NSFont systemFontOfSize:11.0]];
        [self setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setStringValue:theLabel];

        // setup mouse events
        NSRect trackingRect = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        [self addTrackingRect:trackingRect owner:self userData:nil assumeInside:YES];
    }

    return self;
}

#pragma mark - Mouse Events
- (void) mouseEntered:(NSEvent *) theEvent {
    [self setHover:YES];
    [self setNeedsDisplay:YES];
}

- (void) mouseExited:(NSEvent *) theEvent {
    [self setHover:NO];
    [self setNeedsDisplay:YES];
}

- (void) mouseUp:(NSEvent *) theEvent {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tab_selected" object:self];
}

#pragma mark - Drawing
- (void) drawRect:(NSRect) dirtyRect {
    [NSGraphicsContext saveGraphicsState];

    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, self.bounds.size.height)];
    [path lineToPoint:NSMakePoint(15, 1)];
    [path lineToPoint:NSMakePoint(self.bounds.size.width - 15, 1)];
    [path lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height)];
    [path setLineWidth:1];
    [path stroke];
    [path setClip];

    if ([self selected]) {
        NSColor *start = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
        NSColor *end = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        [gradient drawInRect:dirtyRect angle:270];
    }
    else if ([self hover]) {
        NSColor *start = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
        NSColor *end = [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        [gradient drawInRect:dirtyRect angle:270];
    }
    else {
        NSColor *start = [NSColor colorWithCalibratedWhite:0.68 alpha:1.0];
        NSColor *end = [NSColor colorWithCalibratedWhite:0.65 alpha:1.0];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        [gradient drawInRect:dirtyRect angle:270];
    }

    [super drawRect:dirtyRect];

    [NSGraphicsContext restoreGraphicsState];
}

@end
