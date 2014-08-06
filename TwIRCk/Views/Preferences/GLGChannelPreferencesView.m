//
//  GLGChannelPreferencesView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGChannelPreferencesView.h"

@implementation GLGChannelPreferencesView

- (id) initWithFrame:(NSRect) frame {
    if (self = [super initWithFrame:frame]) {
        NSRect innerFrame = NSMakeRect(0, 0, frame.size.width, frame.size.height - 25);

        NSTableView *channelTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, innerFrame.size.width, innerFrame.size.height)];
        NSTableColumn *channelNameColumn = [[NSTableColumn alloc] initWithIdentifier:@"channel-name"];
        [channelNameColumn.headerCell setTitle:@"Name"];
        [channelNameColumn setIdentifier:@"channel-name"];
        [channelNameColumn setWidth:150];
        [channelTable addTableColumn:channelNameColumn];

        NSScrollView *channelsListView = [[NSScrollView alloc] initWithFrame:innerFrame];
        [channelsListView setBorderType:NSBezelBorder];
        [channelsListView setDocumentView:channelTable];
        [channelsListView setFocusRingType:NSFocusRingTypeExterior];
        [self addSubview:channelsListView];

        NSTextField *channelsLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, frame.size.height - 20, 150, 20)];
        [channelsLabel setIdentifier:@"Channels-Label"];
        [[channelsLabel cell] setControlSize:NSSmallControlSize];
        [channelsLabel setBordered:NO];
        [channelsLabel setBezeled:NO];
        [channelsLabel setSelectable:NO];
        [channelsLabel setEditable:NO];
        [channelsLabel setFont:[NSFont systemFontOfSize:13.0]];
        [channelsLabel setBackgroundColor:[NSColor clearColor]];
        [channelsLabel setStringValue:NSLocalizedString(@"Saved Channels:", @"Saved-Channels-Label")];
        [self addSubview:channelsLabel];
    }
    return self;
}

@end
