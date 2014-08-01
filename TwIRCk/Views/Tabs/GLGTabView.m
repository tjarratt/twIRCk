//
//  GLGTabView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGTabView.h"

const CGFloat max_width_of_tab = 130;
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

    NSUInteger count = tabs.count;
    CGFloat frameWidthWithPadding = frameRect.size.width - (tab_padding * (count - 1));
    CGFloat tabWidth = MIN(max_width_of_tab, frameWidthWithPadding / count);

    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        CGFloat x_offset = (tabWidth + tab_padding) * index;
        NSRect frame = NSMakeRect(x_offset, 0, tabWidth, height_of_tab);
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

    [[NSNotificationCenter defaultCenter] postNotificationName:@"did_switch_tabs" object:the_tab];
}

- (void) setSelectedChannelNamed:(NSString *) name {
    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        [tab setNeedsDisplay:YES];

        if ([[tab name] isEqualToString:name]) {
            [tab setSelected:YES];
            selected_tab_index = index;
        }
        else {
            [tab setSelected:NO];
        }
    }];

    [self setNeedsDisplay:YES];

}

- (void) handleTabClosure:(NSNotification *) notification {
    GLGTabItem *the_tab = (GLGTabItem *)[notification object];
    [self removeTab:the_tab];
}

#pragma mark - adding tabs
- (void) addItem:(NSString *) title forOwner:(id) theOwner {
    [self addItem:title selected:NO forOwner:theOwner];
}

- (void) addItem:(NSString *) title selected:(BOOL) isSelected forOwner:(id) theOwner {
    CGFloat count = [tabs count];
    CGFloat frameWidthWithPadding = self.frame.size.width - (tab_padding * (count));
    CGFloat tabWidth = MIN(max_width_of_tab, frameWidthWithPadding / (count + 1));

    if (tabWidth < max_width_of_tab) {
        [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
            CGFloat x_offset = (tabWidth + tab_padding) * index;
            NSRect frame = NSMakeRect(x_offset, 0, tabWidth, height_of_tab);
            [tab setFrame:frame];
            [tab setNeedsDisplay:YES];
        }];
    }

    CGFloat x_offset = (tabWidth + tab_padding) * count;
    NSRect tab_frame = NSMakeRect(x_offset, 0, tabWidth, height_of_tab);

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

#pragma mark - removing tabs
- (void) removeTabNamed:(NSString *) name fromOwner:(id) owner {
    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        if ([[tab name] isEqualToString:name] && [[tab owner] isEqualTo:owner]) {
            [self removeTab:tab];
            *stop = YES;
        }
    }];
}

- (void) removeTab:(GLGTabItem *) the_tab {
    NSUInteger index = [tabs indexOfObject:the_tab];
    [the_tab removeFromSuperview];
    [tabs removeObjectAtIndex:index];

    NSDictionary *notificationObject = @{@"name" : the_tab.name, @"owner" : the_tab.owner};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"chatview_closed_tab" object:notificationObject];

    if ([tabs count] == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removed_last_tab" object:nil];
    }

    if (index == selected_tab_index) {
        if (selected_tab_index >= [tabs count]) {
            selected_tab_index = [tabs count] - 1;
        }

        [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
            [tab setNeedsDisplay:YES];

            if (index == selected_tab_index) {
                [tab setSelected:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"did_switch_tabs" object:tab];
            }
            else {
                [tab setSelected:NO];
            }
        }];
    }

    CGFloat frameWidthWithPadding = self.frame.size.width - (tab_padding * (tabs.count - 1));
    CGFloat tabWidth = MIN(max_width_of_tab, frameWidthWithPadding / tabs.count);
    [tabs enumerateObjectsUsingBlock:^(GLGTabItem *tab, NSUInteger index, BOOL *stop) {
        CGFloat x_offset = (tabWidth + tab_padding) * index;
        NSRect frame = NSMakeRect(x_offset, 0, tabWidth, height_of_tab);
        [tab setFrame:frame];
        [tab setNeedsDisplay:YES];
    }];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"did_switch_tabs" object:the_tab];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"did_switch_tabs" object:the_tab];
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
