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

        tableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, innerFrame.size.width, innerFrame.size.height)];
        NSTableColumn *channelNameColumn = [[NSTableColumn alloc] initWithIdentifier:@"channel-name"];
        [channelNameColumn.headerCell setTitle:@"Name"];
        [channelNameColumn setIdentifier:@"channel-name"];
        [channelNameColumn setWidth:150];
        [tableView addTableColumn:channelNameColumn];
        [tableView setDelegate:self];
        [tableView setDataSource:self];

        NSScrollView *channelsListView = [[NSScrollView alloc] initWithFrame:innerFrame];
        [channelsListView setBorderType:NSBezelBorder];
        [channelsListView setDocumentView:tableView];
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

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadTable:)
                                                     name:@"preferences.server.selection.changed"
                                                   object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSNotificationCenter selectors
- (void) reloadTable:(NSNotification *) notification {
    [tableView reloadData];
}

- (void) setChannelsBinding:(id) source {
    controller = source;
}

#pragma mark - NSTableViewDataSource
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    if (controller != nil && controller.selectedServer != nil) {
        return [[[[controller selectedServer] channels] allObjects] count];
    } else {
        return 0;
    }
}

#pragma mark - NSTableViewDelegate
- (NSView *) tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *) tableColumn row:(NSInteger) row {
    GLGLabelView *label = [aTableView makeViewWithIdentifier:@"channelNameView" owner:self];
    if (label  == nil) {
        label = [[GLGLabelView alloc] init];
        [label setIdentifier:@"channelNameView"];
    }

    IRCServer *currentServer = [controller selectedServer];
    if (currentServer != nil) {
        NSString *channelName = [[[[currentServer channels] allObjects] objectAtIndex:row] name];
        [label setStringValue:channelName];
    }

    return label;
}

@end
