//
//  GLGLabelView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGLabelView.h"

@implementation GLGLabelView

- (id) init {
    if (self = [super init]) {
        [self configure];
    }
    return self;
}

- (id) initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self configure];
    }
    return self;
}

- (void) configure {
    [self setBordered:NO];
    [self setBezeled:NO];
    [self setSelectable:NO];
    [self setEditable:NO];
    [self setBackgroundColor:[NSColor clearColor]];
}

@end
