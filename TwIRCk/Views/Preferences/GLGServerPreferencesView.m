//
//  GLGServerPreferencesView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGServerPreferencesView.h"

@implementation GLGServerPreferencesView

- (id) initWithFrame:(NSRect) frame {
    if (self = [super initWithFrame:frame]) {
        currentServers = [GLGManagedObjectContext currentServers];

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

        NSRect innerFrame = NSMakeRect(0, -25, frame.size.width, frame.size.height);
        NSTableView *tableview = [[NSTableView alloc] initWithFrame:innerFrame];
        [tableview setDelegate:self];
        [tableview setDataSource:self];

        [tableview setRowHeight:20];
        [tableview setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle | NSTableViewUniformColumnAutoresizingStyle];
        [tableview addTableColumn:nameColumn];
        [tableview addTableColumn:portColumn];
        [tableview addTableColumn:sslColumn];
        [tableview addTableColumn:usernameColumn];
        [tableview addTableColumn:passwordColumn];
        [tableview setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];

        NSScrollView *serverListView  = [[NSScrollView alloc] initWithFrame:innerFrame];
        [serverListView setBorderType:NSBezelBorder];
        [serverListView setDocumentView:tableview];
        [serverListView setFocusRingType:NSFocusRingTypeExterior];
        [self addSubview:serverListView];

        NSTextField *serversLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, frame.size.height - 20, 100, 20)];
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
    }
    return self;
}

#pragma mark - NSTableViewDelegate
- (NSInteger) numberOfRowsInTableView:(NSTableView *) tableview {
    return [currentServers count];
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    id result;
    NSString *identifier = [tableColumn identifier];
    IRCServer *server = [currentServers objectAtIndex:row];

    if ([identifier isEqualToString:@"hostname"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:@"serverNameRowView" owner:self];
        if (textField == nil) {
            textField = [[NSTextField alloc] init];
            textField.identifier = @"serverNameRowView";
            [textField setBordered:NO];
            [textField setBezeled:NO];
            [textField setEditable:NO];
            [textField setBackgroundColor:[NSColor clearColor]];
        }

        [textField setStringValue: [server hostname]];
        result = textField;
    }
    else if ([identifier isEqualToString:@"port"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:@"port" owner:self];
        if (textField == nil) {
            textField = [[NSTextField alloc] init];
            textField.identifier = @"port";
            [textField setBordered:NO];
            [textField setBezeled:NO];
            [textField setSelectable:NO];
            [textField setEditable:NO];
            [textField setBackgroundColor:[NSColor clearColor]];
        }

        [textField setStringValue: [server.port stringValue]];
        result = textField;
    } else if ([identifier isEqualToString:@"ssl"]) {
        NSButton *checkbox = [tableView makeViewWithIdentifier:@"useSSLCheckBox" owner:self];
        if (checkbox == nil ) {
            checkbox = [[NSButton alloc] init];
            [checkbox setButtonType:NSSwitchButton];
            [checkbox setIdentifier:@"useSSLCheckBox"];
            [checkbox setTitle:@""];
            [checkbox setEnabled:NO];
        }

        if (server.useSSL) {
            [checkbox setState:NSOnState];
        } else {
            [checkbox setState:NSOffState];
        }

        result = checkbox;
    }
    else if ([identifier isEqualToString:@"username"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:@"serverUsername" owner:self];

        if (textField == nil) {
            textField = [[NSTextField alloc] init];
            textField.identifier = @"serverUsername";
            [textField setBordered:NO];
            [textField setBezeled:NO];
            [textField setSelectable:NO];
            [textField setEditable:NO];
            [textField setBackgroundColor:[NSColor clearColor]];
        }

        [textField setStringValue:[server username]];
        result = textField;
    } else if ([identifier isEqualToString:@"password"]) {
        NSSecureTextField *textField = [tableView makeViewWithIdentifier:@"password" owner:self];

        if (textField == nil) {
            textField = [[NSSecureTextField alloc] init];
            [textField setIdentifier:@"password"];
            [textField setBordered:NO];
            [textField setBezeled:NO];
            [textField setSelectable:NO];
            [textField setEditable:NO];
            [textField setBackgroundColor:[NSColor clearColor]];
        }

        [textField setStringValue:[server password]];
        result = textField;
    }

    return result;
}

- (void) tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    if ([tableView selectedRow] == -1) {
        [tableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row] byExtendingSelection:NO];
    }
}

- (BOOL) selectionShouldChangeInTableView:(NSTableView *)aTableView {
    return [currentServers count] > 1;
}

@end
