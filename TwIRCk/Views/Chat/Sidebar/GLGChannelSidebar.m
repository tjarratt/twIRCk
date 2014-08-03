//
//  GLGChannelSidebar.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGChannelSidebar.h"

@implementation GLGChannelSidebar

- (id)initWithFrame:(NSRect) frame {
    if (self = [super initWithFrame:frame]) {
        scrollView = [[GLGGradientSidebar alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollView setScrollsDynamically:YES];
        [scrollView setWantsLayer:YES];
        [scrollView setBackgroundColor:[NSColor clearColor]];
         [self addSubview:scrollView];

        innerView = [[GLGChannelContent alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [innerView setWantsLayer:YES];
        [[innerView layer] setBackgroundColor:[[NSColor clearColor] CGColor]];
        [scrollView setDocumentView:innerView];
    }
    
    return self;
}

- (void) showChannelOccupants:(NSArray *) occupants withColors:(NSArray *)colors {
    [innerView setSubviews:@[]];
    NSRect frame = [innerView frame];
    CGFloat height = frame.size.height;
    CGFloat fullHeight = MAX(height, 35 * 2 + 25 * occupants.count);
    frame = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, fullHeight);
    [innerView setFrame:frame];

    [occupants enumerateObjectsUsingBlock:^(NSString *name, NSUInteger i, BOOL *stop) {
        NSRect rect = NSMakeRect(15, frame.size.height - (35 + 25 * i), 120, 15);
        GLGSidebarOccupant *label = [[GLGSidebarOccupant alloc] initWithFrame:rect];

        [label setDelegate:self.superview];
        [[label cell] setControlSize:NSSmallControlSize];
        [label setAlignment:NSLeftTextAlignment];
        [label setBordered:NO];
        [label setBezeled:NO];
        [label setSelectable:NO];
        [label setEditable:NO];
        [label setFont:[NSFont systemFontOfSize:11.0]];
        [label setStringValue:name];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setFrame:NSMakeRect(rect.origin.x, rect.origin.y, label.intrinsicContentSize.width + 6, rect.size.height)];
        [label setAlignment:NSCenterTextAlignment];
        [label setTextColor:[colors objectAtIndex:i]];

        [innerView addSubview:label];
        ++i;
    }];

    [self setNeedsDisplay:YES];
    [scrollView setNeedsDisplay:YES];
    [[scrollView documentView] scrollPoint:NSMakePoint(0, fullHeight)];
}

@end
