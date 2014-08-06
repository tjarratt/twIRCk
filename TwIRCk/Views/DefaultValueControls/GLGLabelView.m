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
        [self setBordered:NO];
        [self setBezeled:NO];
        [self setSelectable:NO];
        [self setEditable:NO];
        [self setBackgroundColor:[NSColor clearColor]];
    }
    return self;
}

@end
