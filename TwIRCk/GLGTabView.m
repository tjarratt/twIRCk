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
        selected_tab_index = 0;
        tabs = [[NSMutableArray alloc] initWithCapacity:10];
        [self setWantsLayer:YES];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTabSelection:) name:@"tab_selected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTabClosure:) name:@"tab_closed" object:nil];

    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSUInteger) count {
    return [tabs count];
}

- (void) setFrame:(NSRect) frameRect {
    [super setFrame:frameRect];
    [self setNeedsDisplay:YES];

    [self positionSubviews];
}

- (void) positionSubviews {
    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        CGFloat x_offset = (width_of_tab + tab_padding) * index;
        NSRect frame = NSMakeRect(x_offset, 0, width_of_tab, height_of_tab);
        [tab setFrame:frame];
        [tab setNeedsDisplay:YES];
    }];
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
    [self setNeedsDisplay:YES];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"did_switch_tabs" object:[the_tab name]];
}

- (void) removeTabNamed:(NSString *) name {
    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        if ([[tab name] isEqualToString:name]) {
            [self removeTab:tab];
            *stop = YES;
        }
    }];
}

- (void) removeTab:(GLGTabItem *) the_tab {
    NSUInteger index = [tabs indexOfObject:the_tab];
    [the_tab removeFromSuperview];
    [tabs removeObjectAtIndex:index];

    if ([tabs count] == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removed_last_tab" object:nil];
    }


    if (index == selected_tab_index) {
        if (selected_tab_index > 0) {
            --selected_tab_index;
        }

        [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
            [tab setNeedsDisplay:YES];

            if (index == selected_tab_index) {
                [tab setSelected:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"did_switch_tabs" object:[tab name]];
            }
            else {
                [tab setSelected:NO];
            }
        }];
    }

    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        CGFloat x_offset = (width_of_tab + tab_padding) * index;
        NSRect frame = NSMakeRect(x_offset, 0, width_of_tab, height_of_tab);
        [tab setFrame:frame];
        [tab setNeedsDisplay:YES];
    }];
}

- (void) handleTabClosure:(NSNotification *) notification {
    GLGTabItem *the_tab = (GLGTabItem *)[notification object];
    [self removeTab:the_tab];
}

#pragma mark - adding / removing tabs
- (void) addItem:(NSString *) title forOwner:(NSString *) theOwner {
    [self addItem:title selected:NO forOwner:theOwner];
}

- (void) addItem:(NSString *) title selected:(BOOL) isSelected forOwner:(NSString *) theOwner {
    CGFloat count = [tabs count];
    CGFloat a_width = width_of_tab + tab_padding;
    CGFloat x_offset = a_width * count;
    NSRect tab_frame = NSMakeRect(x_offset, 0, width_of_tab, height_of_tab);

    GLGTabItem *item = [[GLGTabItem alloc] initWithFrame:tab_frame andLabel:title];
    [item setOwner:theOwner];
    [self addSubview:item];
    [self setNeedsDisplay:YES];
    [tabs addObject:item];

    if (isSelected) {
        [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
            [tab setSelected:NO];
            [tab setNeedsDisplay:YES];
        }];
        [item setSelected:YES];
        selected_tab_index = [tabs count] - 1;
    }
    else if ([tabs count] == 1) {
        [item setSelected:YES];
        selected_tab_index = 0;
    }
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

    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"did_switch_tabs" object:[the_tab name]];
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

    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"did_switch_tabs" object:[the_tab name]];
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
