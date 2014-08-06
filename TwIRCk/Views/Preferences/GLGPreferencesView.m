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
        CGFloat innerWidth = frame.size.width * 0.8;
        CGFloat innerHeight = frame.size.height * 0.85;
        NSRect innerFrame = NSMakeRect(
                                       (frame.size.width - innerWidth) / 2,
                                       (frame.size.height - innerHeight) / 2,
                                       innerWidth,
                                       innerHeight
                                       );

        NSRect innerFrameTop = NSMakeRect(innerFrame.origin.x, innerFrame.origin.y + innerFrame.size.height / 2, innerFrame.size.width, innerFrame.size.height / 2);
        GLGServerPreferencesView *serverView = [[GLGServerPreferencesView alloc] initWithFrame:innerFrameTop];
        [self addSubview:serverView];

        NSRect innerFrameBottom = NSMakeRect(innerFrame.origin.x, innerFrame.origin.y, innerFrame.size.width, innerFrame.size.height * 0.35);
        GLGChannelPreferencesView *channelView = [[GLGChannelPreferencesView alloc] initWithFrame:innerFrameBottom];
        [self addSubview:channelView];

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
