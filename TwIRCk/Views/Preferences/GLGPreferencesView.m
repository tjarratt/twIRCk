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
        NSSize innerSize = NSMakeSize(frame.size.width * 0.8, frame.size.height * 0.6);
        NSRect innerFrame = NSMakeRect((frame.size.width - innerSize.width) / 2, (frame.size.height - innerSize.height) / 2, innerSize.width, innerSize.height);
        NSScrollView *scrollview  = [[NSScrollView alloc] initWithFrame:innerFrame];
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

        tableview = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, innerFrame.size.width, innerFrame.size.height)];
        [tableview setRowHeight:20];
        [tableview setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle | NSTableViewUniformColumnAutoresizingStyle];
        [tableview addTableColumn:nameColumn];
        [tableview addTableColumn:portColumn];
        [tableview addTableColumn:sslColumn];
        [tableview addTableColumn:usernameColumn];
        [tableview addTableColumn:passwordColumn];
        [tableview setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        [scrollview setBorderType:NSBezelBorder];

        [scrollview setDocumentView:tableview];
        [scrollview setFocusRingType:NSFocusRingTypeExterior];
        [self addSubview:scrollview];

        NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(innerFrame.origin.x, innerFrame.origin.y + innerFrame.size.height, 100, 20)];
        [label setIdentifier:@"Saved-Servers-Label"];
        [[label cell] setControlSize:NSSmallControlSize];
        [label setBordered:NO];
        [label setBezeled:NO];
        [label setSelectable:NO];
        [label setEditable:NO];
        [label setFont:[NSFont systemFontOfSize:13.0]];
        [label setBackgroundColor:[NSColor clearColor]];
        [label setStringValue:@"Saved Servers:"];
        [self addSubview:label];

        NSButton *removeServer = [[NSButton alloc] initWithFrame:NSMakeRect(innerFrame.origin.x + 2, innerFrame.origin.y - 30, 22, 20)];
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
