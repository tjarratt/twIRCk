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
        }];

        selected_tab_index = 0;
        [[tabs objectAtIndex:selected_tab_index] setSelected:YES];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTabSelection:) name:@"tab_selected" object:nil];

    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - tab notifications 
- (void) handleTabSelection:(NSNotification *) notification {
    GLGTabItem *the_tab = (GLGTabItem *)[notification object];

    selected_tab_index = [tabs indexOfObject:the_tab];
    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        [tab setSelected:NO];
        [tab setNeedsDisplay:YES];
    }];

    [the_tab setSelected:YES];
}

#pragma mark - adding / removing tabs
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

#pragma mark - moving between tabs
- (void) tabForward {
    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        [tab setSelected:NO];
        [tab setNeedsDisplay:YES];
    }];

    ++selected_tab_index;
    if (selected_tab_index == [tabs count]) {
        selected_tab_index = 0;
    }

    GLGTabItem *the_tab = [tabs objectAtIndex:selected_tab_index];
    [the_tab setSelected:YES];
    [the_tab setNeedsDisplay:YES];
}

- (void) tabBackward {
    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        [tab setSelected:NO];
        [tab setNeedsDisplay:YES];
    }];

    if (selected_tab_index == 0) {
        selected_tab_index = [tabs count] - 1;
    }
    else {
        --selected_tab_index;
    }

    GLGTabItem *the_tab = [tabs objectAtIndex:selected_tab_index];
    [the_tab setSelected:YES];
    [the_tab setNeedsDisplay:YES];
}

#pragma mark - drawing code
- (void) drawRect:(NSRect) dirtyRect {
    [super drawRect:dirtyRect];

    NSColor *startingColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
    NSColor *endingColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
    [gradient drawInRect:dirtyRect angle:270];
}

@end
