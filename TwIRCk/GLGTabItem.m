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
        [self setSelected:NO];

        [self setIdentifier:[theLabel stringByAppendingString:@"-tab-item"]];
        [[self cell] setControlSize:NSSmallControlSize];
        [self setBackgroundColor:[NSColor grayColor]];
        [self setAlignment:NSCenterTextAlignment];
        [self setBordered:NO];
        [self setBezeled:NO];
        [self setSelectable:NO];
        [self setEditable:NO];
        [self setFont:[NSFont systemFontOfSize:11.0]];
        [self setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setStringValue:theLabel];
    }
    
    return self;
}

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

    [[NSColor grayColor] set];
    NSRectFill(self.bounds);

    [super drawRect:dirtyRect];
    [NSGraphicsContext restoreGraphicsState];
}

@end
