//
//  GLGTabView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGTabView.h"

const CGFloat width_of_tab = 130;
const CGFloat height_of_tab = 25;
const CGFloat tab_padding = -15;

@implementation GLGTabView

- (id) initWithFrame:(NSRect) frame {
    if (self = [super initWithFrame:frame]) {
        tabs = [[NSMutableArray alloc] initWithCapacity:10];

        [@[@"testing", @"foobar", @"techendo", @"freenode", @"twerk"] enumerateObjectsUsingBlock:^(NSString *chan, NSUInteger index, BOOL *stop) {
            [self addItem:chan];
        }];    }

    return self;
}

- (void) addItem:(NSString *) title {
    CGFloat count = [tabs count];
    CGFloat width = width_of_tab;
    CGFloat a_width = width + tab_padding;
    CGFloat x_offset = a_width * count;
    NSRect tab_frame = NSMakeRect(x_offset, 0, width, height_of_tab);

    GLGTabItem *item = [[GLGTabItem alloc] initWithFrame:tab_frame andLabel:title];
    [self addSubview:item];
    [tabs addObject:item];
}

- (void) drawRect:(NSRect) dirtyRect {
    [super drawRect:dirtyRect];

    [[NSColor purpleColor] set];
    NSRectFill(dirtyRect);
}

@end
