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

        NSRect innerFrameTop = NSMakeRect(innerFrame.origin.x, innerFrame.origin.y + innerFrame.size.height * 0.4, innerFrame.size.width, innerFrame.size.height * 0.6);
        serverView = [[GLGServerPreferencesView alloc] initWithFrame:innerFrameTop];
        [self addSubview:serverView];

        NSRect innerFrameBottom = NSMakeRect(innerFrame.origin.x, innerFrame.origin.y, innerFrame.size.width, innerFrame.size.height * 0.35);
        channelView = [[GLGChannelPreferencesView alloc] initWithFrame:innerFrameBottom];
        [self addSubview:channelView];
    }

    return self;
}

- (void) setFetchedServersController:(GLGPreferencesController *) controller {
    [serverView setFetchedServersController: controller];
    [channelView setChannelsBinding:controller];
}

@end
