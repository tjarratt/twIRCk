//
//  NSView+GLGDebugView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/6/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "NSView+GLGDebugView.h"

static char kBackgroundColorKey;

@implementation NSView (GLGDebugView)
- (void) setBackgroundColor:(NSColor *) color {
    objc_setAssociatedObject(self, &kBackgroundColorKey, color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[self class] redirectSelector:@selector(drawRect:) to:@selector(__glg__drawRect:) andRenameItTo:@selector(originalDrawRect:)];
}

- (void) __glg__drawRect:(NSRect)dirtyRect {
    NSColor *color = objc_getAssociatedObject(self, &kBackgroundColorKey);
    [color setFill];
    NSRectFill(dirtyRect);

    [self originalDrawRect:dirtyRect];
}

@end
