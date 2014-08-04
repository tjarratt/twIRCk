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
        [nameColumn setEditable:NO];
        [nameColumn setWidth:150];

        NSTableColumn *portColumn = [[NSTableColumn alloc] initWithIdentifier:@"port"];
        [portColumn.headerCell setTitle:@"port"];
        [portColumn setIdentifier:@"port"];
        [portColumn setEditable:NO];
        [portColumn setWidth:50];

        NSTableColumn *sslColumn = [[NSTableColumn alloc] initWithIdentifier:@"ssl"];
        [sslColumn.headerCell setTitle:@"Use SSL"];
        [sslColumn setIdentifier:@"ssl"];
        [sslColumn setEditable:NO];
        [sslColumn setWidth:50];

        NSTableColumn *usernameColumn = [[NSTableColumn alloc] initWithIdentifier:@"username"];
        [usernameColumn.headerCell setTitle:@"username"];
        [usernameColumn setIdentifier:@"username"];
        [usernameColumn setEditable:NO];
        [usernameColumn setWidth:100];

        NSTableColumn *passwordColumn = [[NSTableColumn alloc] initWithIdentifier:@"password"];
        [passwordColumn.headerCell setTitle:@"password"];
        [passwordColumn setIdentifier:@"password"];
        [passwordColumn setEditable:NO];
        [passwordColumn setWidth:100];

        tableview = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, innerFrame.size.width, innerFrame.size.height)];
        [tableview setRowHeight:20];
        [tableview setColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle | NSTableViewUniformColumnAutoresizingStyle];
        [tableview addTableColumn:nameColumn];
        [tableview addTableColumn:portColumn];
        [tableview addTableColumn:sslColumn];
        [tableview addTableColumn:usernameColumn];
        [tableview addTableColumn:passwordColumn];

        [scrollview setDocumentView:tableview];
        [self addSubview:scrollview];
        [scrollview setFocusRingType:NSFocusRingTypeExterior];
    }

    return self;
}

- (NSTableView *) tableview {
    return tableview;
}

@end
