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
        NSTableColumn *nameColumn = [[NSTableColumn alloc] initWithIdentifier:@"preferences-server-list-header"];
        [nameColumn.headerCell setTitle:@"Server Hostname"];

        tableview = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, innerFrame.size.width, innerFrame.size.height)];
        [tableview setRowHeight:25];
        [tableview addTableColumn:nameColumn];

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
