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
        scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollView setScrollsDynamically:YES];
        [scrollView setWantsLayer:YES];
         [self addSubview:scrollView];

        innerView = [[GLGChannelContent alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [innerView setWantsLayer:YES];
        [[innerView layer] setBackgroundColor:[[NSColor clearColor] CGColor]];
        [scrollView setDocumentView:innerView];
    }
    
    return self;
}

- (void) showChannelOccupants:(NSArray *) occupants {
    [innerView setSubviews:@[]];
    NSRect frame = [innerView frame];

    [occupants enumerateObjectsUsingBlock:^(NSString *name, NSUInteger index, BOOL *stop) {
        NSRect rect = NSMakeRect(15, frame.size.height - (35 + 25 * index), 120, 20);
        NSTextField *label = [[NSTextField alloc] initWithFrame:rect];
        [[label cell] setControlSize:NSSmallControlSize];
        [label setAlignment:NSLeftTextAlignment];
        [label setBordered:NO];
        [label setBezeled:NO];
        [label setSelectable:NO];
        [label setEditable:NO];
        [label setFont:[NSFont systemFontOfSize:11.0]];
        [label setStringValue:name];
        [label setBackgroundColor:[NSColor clearColor]];

        [innerView addSubview:label];
    }];
}

@end
