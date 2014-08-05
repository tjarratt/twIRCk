//
//  GLGPreferencesView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/3/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGPreferencesView.h"

@implementation GLGPreferencesView

- (id)initWithFrame:(NSRect) frame {
    if (self = [super initWithFrame:frame]) {
        NSSize innerSize = NSMakeSize(frame.size.width * 0.8, frame.size.height * 0.8);
        NSRect innerFrameTop = NSMakeRect(
                                          (frame.size.width - innerSize.width) / 2,
                                          frame.size.height - innerSize.height * 0.4 - 45,
                                          innerSize.width,
                                          innerSize.height * 0.4
                                          );
        NSRect innerFrameBottom = NSMakeRect(
                                             innerFrameTop.origin.x,
                                             innerFrameTop.origin.y - innerFrameTop.size.height - 65,
                                             innerSize.width,
                                             innerSize.height * 0.4
                                             );

        NSTableColumn *nameColumn = [[NSTableColumn alloc] initWithIdentifier:@"hostname"];
        [nameColumn.headerCell setTitle:@"Server Hostname"];
        [nameColumn setIdentifier:@"hostname"];
        [nameColumn setWidth:150];

        NSTableColumn *portColumn = [[NSTableColumn alloc] initWithIdentifier:@"port"];
        [portColumn.headerCell setTitle:@"port"];
        [portColumn setIdentifier:@"port"];
        [portColumn setWidth:50];

        NSTableColumn *sslColumn = [[NSTableColumn alloc] initWithIdentifier:@"ssl"];
        [sslColumn.headerCell setTitle:@"Use SSL"];
        [sslColumn setIdentifier:@"ssl"];
        [sslColumn setWidth:50];

        NSTableColumn *usernameColumn = [[NSTableColumn alloc] initWithIdentifier:@"username"];
        [usernameColumn.headerCell setTitle:@"username"];
        [usernameColumn setIdentifier:@"username"];
        [usernameColumn setWidth:100];

        NSTableColumn *passwordColumn = [[NSTableColumn alloc] initWithIdentifier:@"password"];
        [passwordColumn.headerCell setTitle:@"password"];
        [passwordColumn setIdentifier:@"password"];
        [passwordColumn setWidth:100];

        tableview = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, innerFrameTop.size.width, innerFrameTop.size.height)];
        [tableview setRowHeight:20];
        [tableview setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle | NSTableViewUniformColumnAutoresizingStyle];
        [tableview addTableColumn:nameColumn];
        [tableview addTableColumn:portColumn];
        [tableview addTableColumn:sslColumn];
        [tableview addTableColumn:usernameColumn];
        [tableview addTableColumn:passwordColumn];
        [tableview setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];

        NSTableView *channelTable = [[NSTableView alloc] initWithFrame:innerFrameBottom];
        NSTableColumn *channelNameColumn = [[NSTableColumn alloc] initWithIdentifier:@"channel-name"];
        [channelNameColumn.headerCell setTitle:@"Name"];
        [channelNameColumn setIdentifier:@"channel-name"];
        [channelNameColumn setWidth:150];
        [channelTable addTableColumn:channelNameColumn];

        NSScrollView *channelsListView = [[NSScrollView alloc] initWithFrame:innerFrameBottom];
        [channelsListView setBorderType:NSBezelBorder];
        [channelsListView setDocumentView:channelTable];
        [channelsListView setFocusRingType:NSFocusRingTypeExterior];
        [self addSubview:channelsListView];

        NSScrollView *serverListView  = [[NSScrollView alloc] initWithFrame:innerFrameTop];
        [serverListView setBorderType:NSBezelBorder];
        [serverListView setDocumentView:tableview];
        [serverListView setFocusRingType:NSFocusRingTypeExterior];
        [self addSubview:serverListView];

        NSTextField *serversLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(innerFrameTop.origin.x, innerFrameTop.origin.y + innerFrameTop.size.height, 100, 20)];
        [serversLabel setIdentifier:@"Saved-Servers-Label"];
        [[serversLabel cell] setControlSize:NSSmallControlSize];
        [serversLabel setBordered:NO];
        [serversLabel setBezeled:NO];
        [serversLabel setSelectable:NO];
        [serversLabel setEditable:NO];
        [serversLabel setFont:[NSFont systemFontOfSize:13.0]];
        [serversLabel setBackgroundColor:[NSColor clearColor]];
        [serversLabel setStringValue:NSLocalizedString(@"Saved Servers:", @"Saved-Servers-Label")];
        [self addSubview:serversLabel];

        NSTextField *channelsLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(innerFrameBottom.origin.x, innerFrameBottom.origin.y + innerFrameBottom.size.height, 150, 20)];
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

        NSButton *removeServer = [[NSButton alloc] initWithFrame:NSMakeRect(innerFrameTop.origin.x + 2, innerFrameTop.origin.y - 30, 22, 20)];
        [removeServer setTitle:@"-"];
        [removeServer setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [removeServer setBezelStyle:NSShadowlessSquareBezelStyle];
        [removeServer setTarget:self];
        [removeServer setAction:@selector(removeSelectedRow:)];
        [self addSubview:removeServer];
    }

    return self;
}

- (NSTableView *) tableview {
    return tableview;
}

- (IBAction) removeSelectedRow:(id)sender {
    NSInteger index = [tableview selectedRow];
    if (index < 0) {
        return;
    }

    IRCServer *server = [fetchedServersController serverAtIndexPath:index];
    if (server == nil) { return; }
    
    NSManagedObjectContext *context = [GLGManagedObjectContext  managedObjectContext];
    [context deleteObject:server];
    [context save:nil];

    NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:index];
    [tableview removeRowsAtIndexes:set withAnimation:NSTableViewAnimationEffectFade];
}

- (void) setFetchedServersController:(id <GLGFetchedServersController>) controller {
    fetchedServersController = controller;
}

@end
