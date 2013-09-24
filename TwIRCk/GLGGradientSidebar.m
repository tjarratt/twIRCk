//
//  GLGGradientSidebar.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGGradientSidebar.h"

@implementation GLGGradientSidebar

- (void)drawRect:(NSRect) dirtyRect {
    [super drawRect:dirtyRect];

    NSColor *startingColor = [NSColor colorWithDeviceRed:0.8 green:0.8 blue:0.85 alpha:1.0];
    NSColor *endingColor = [NSColor colorWithDeviceRed:0.78 green:0.78 blue:0.8 alpha:1.0];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
    [gradient drawInRect:dirtyRect angle:270];
}

@end
