//
//  GLGServerChannelPreferencesView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGServerChannelPreferencesView.h"

@implementation GLGServerChannelPreferencesView

- (id) initWithFrame:(NSRect) frame {
    if (self = [super initWithFrame:frame]) {
        [self setDividerStyle:NSSplitViewDividerStyleThick];
        [self setDelegate:self];
    }
    return self;
}

-(CGFloat) dividerThickness {
    return 25;
}

- (BOOL) splitView:(NSSplitView *) splitView shouldHideDividerAtIndex:(NSInteger) dividerIndex {
    return NO;
}

- (NSRect) splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
    return NSZeroRect;
}


@end
