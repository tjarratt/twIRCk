//
//  GLGTabItem.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGTabItem.h"

@implementation GLGTabItem

- (id)initWithFrame:(NSRect)frame andLabel:(NSString *) theLabel {
    if (self = [super initWithFrame:frame]) {
        selectedRect = NSMakeRect(13, 8, frame.size.width - 38, frame.size.height);
        unselectedRect = NSMakeRect(13, 8, frame.size.width - 23, frame.size.height);
        textfield = [[NSTextField alloc] initWithFrame:unselectedRect];

        NSRect imageFrame = NSMakeRect(frame.size.width - 30, 6, 15, 15);
        imageView = [[NSImageView alloc] initWithFrame:imageFrame];
        [self addSubview:imageView];
        [imageView setTarget:self];
        [imageView setAction:@selector(closeButtonClicked:)];

        NSBundle *bundle = [NSBundle mainBundle];
        NSString *imagePath = [bundle pathForImageResource:@"close_no_rollover"];
        closeButton = [[NSImage alloc] initWithContentsOfFile:imagePath];

        imagePath = [bundle pathForImageResource:@"close_rollover"];
        closeButtonSelected = [[NSImage alloc] initWithContentsOfFile:imagePath];

        [self setName:theLabel];
        [self setSelected:NO];
        [self setHover:NO];

        [textfield setIdentifier:[theLabel stringByAppendingString:@"-tab-item"]];
        [[textfield cell] setControlSize:NSSmallControlSize];
        [textfield setBackgroundColor:[NSColor clearColor]];
        [textfield setAlignment:NSLeftTextAlignment];
        [textfield setBordered:NO];
        [textfield setBezeled:NO];
        [textfield setSelectable:NO];
        [textfield setEditable:NO];
        [textfield setFont:[NSFont systemFontOfSize:11.0]];
        [textfield setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
        [textfield setTranslatesAutoresizingMaskIntoConstraints:NO];
        [textfield setStringValue:theLabel];
        [textfield setWantsLayer:YES];
        [self addSubview:textfield];

        // setup mouse events
        NSRect trackingRect = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        NSRect trackingRectSelected = NSMakeRect(0, 0, frame.size.width - 20, frame.size.height);

        NSTrackingAreaOptions opts = NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect;
        
        trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:opts owner:self userInfo:nil];
        trackingAreaSelected = [[NSTrackingArea alloc] initWithRect:trackingRectSelected options:opts owner:self userInfo:nil];

        [self addTrackingArea:trackingArea];

        NSString *notification_name = [@"message_received_" stringByAppendingString:theLabel];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(tabMessageReceived:) name:notification_name object:nil];
        [center addObserver:self selector:@selector(tabHighlightReceived:) name:@"highlight_tab" object:nil];
    }

    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) isFlipped {
    return YES;
}

- (void) setFrame:(NSRect) frame {
    [super setFrame:frame];
    [self removeTrackingArea:trackingArea];
    [self removeTrackingArea:trackingAreaSelected];

    selectedRect = NSMakeRect(13, 8, frame.size.width - 38, frame.size.height);
    unselectedRect = NSMakeRect(13, 8, frame.size.width - 23, frame.size.height);

    NSRect imageFrame = NSMakeRect(frame.size.width - 30, 6, 15, 15);
    [imageView setFrame:imageFrame];

    NSRect trackingRect = NSMakeRect(0, 0, frame.size.width, frame.size.height);
    NSRect trackingRectSelected = NSMakeRect(0, 0, frame.size.width - 20, frame.size.height);

    NSTrackingAreaOptions opts = NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect;
    trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:opts owner:self userInfo:nil];
    trackingAreaSelected = [[NSTrackingArea alloc] initWithRect:trackingRectSelected options:opts owner:self userInfo:nil];

    if (_selected) {
        [textfield setFrame:selectedRect];
        [self addTrackingArea:trackingAreaSelected];
    }
    else {
        [textfield setFrame:unselectedRect];
        [self addTrackingArea:trackingArea];
    }
}

#pragma mark - NSNotifications
- (void) tabMessageReceived:(NSNotification *) notification {
    NSDictionary *dict = [notification userInfo];
    BOOL matchingName = [[dict objectForKey:@"name"] isEqualToString:[self name]];
    BOOL matchingOwner = [[dict objectForKey:@"owner"] isEqualTo:[self owner]];

    if (matchingName && matchingOwner && !_selected) {
        _emphasis = YES;
        [self updateHighlights];
    }
}

- (void) tabHighlightReceived:(NSNotification *) notification {
    NSDictionary *dict = [notification userInfo];
    BOOL matchingName = [[dict objectForKey:@"name"] isEqualToString:[self name]];
    BOOL matchingOwner = [[dict objectForKey:@"owner"] isEqualTo:[self owner]];

    if (matchingName && matchingOwner && !_selected) {
        _highlighted = YES;
    }
}

#pragma mark - highlighting
- (void) updateHighlights {
    NSRange range = NSMakeRange(0, self.name.length);
    NSMutableAttributedString *value = [[NSMutableAttributedString alloc] initWithString:self.name];

    if (_emphasis) {
        NSDictionary *labelAttrs = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:11]};
        [value setAttributes:labelAttrs range:range];
    }
    if (_highlighted) {
        NSColor *theColor = [NSColor colorWithDeviceRed:0.14 green:0.52 blue:0.93 alpha:1.0];
        [value addAttribute:NSForegroundColorAttributeName value:theColor range:range];
    }

    [textfield setAttributedStringValue:value];
}

#pragma mark - accessors
- (BOOL) selected {
    return _selected;
}

- (void) setSelected:(BOOL)selected {
    _selected = selected;

    if (_selected) {
        _emphasis = NO;
        _highlighted = NO;
        [self removeTrackingArea:trackingArea];
        [self addTrackingArea:trackingAreaSelected];
    }
    else {
        [self removeTrackingArea:trackingAreaSelected];
        [self addTrackingArea:trackingArea];
    }

    [self updateHighlights];
}

- (BOOL) hover {
    return _hover;
}

- (void) setHover:(BOOL)flag {
    _hover = flag;

    if (_hover) {
        [imageView setImage:closeButton];
        [textfield setFrame:selectedRect];
    }
    else {
        [imageView setImage:nil];
        [textfield setFrame:unselectedRect];
    }
}

#pragma mark - Mouse Events
- (void) mouseEntered:(NSEvent *) theEvent {
    [self setHover:YES];
    [self setNeedsDisplay:YES];
    [[self superview] setNeedsDisplay:YES];
}

- (void) mouseExited:(NSEvent *) theEvent {
    [self setHover:NO];
    [self setNeedsDisplay:YES];
    [[self superview] setNeedsDisplay:YES];
}

- (void) mouseUp:(NSEvent *) theEvent {
    NSPoint windowPoint = [theEvent locationInWindow];
    NSPoint localPoint = [self convertPoint:windowPoint fromView:nil];

    if (NSPointInRect(localPoint, imageView.frame)) {
        [self closeButtonClicked:theEvent];
    }
    else {
        [[self superview] setNeedsDisplay:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"tab_selected" object:self];
    }
}

- (void) closeButtonClicked:(NSEvent *) event {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tab_closed" object:self];
}

#pragma mark - Drawing
- (void) drawRect:(NSRect) dirtyRect {
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setShouldAntialias:YES];

    // setup path just below the edge of the view
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, self.bounds.size.height + 3)];

    // curve to an initial point
    NSPoint curveToPoint = NSMakePoint(5, self.bounds.size.height - 2);
    [path curveToPoint:curveToPoint controlPoint1:curveToPoint controlPoint2:curveToPoint];

    // draw the remaining left edge of the trapezoidal shape
    [path lineToPoint:NSMakePoint(11, 4)];

    // draw the remaining curve up to the top of the trapezoid
    curveToPoint = NSMakePoint(17, 1);
    NSPoint controlPoint = NSMakePoint(13, 2);
    [path curveToPoint:curveToPoint controlPoint1:controlPoint controlPoint2:controlPoint];

    // draw the top
    [path lineToPoint:NSMakePoint(self.bounds.size.width - 17, 1)];

    // draw the first part of the right edge curve
    curveToPoint = NSMakePoint(self.bounds.size.width - 11, 4);
    controlPoint = NSMakePoint(self.bounds.size.width - 13, 2);
    [path curveToPoint:curveToPoint controlPoint1:controlPoint controlPoint2:controlPoint];

    // draw the straight part of the right trapezoidal edge
    [path lineToPoint:NSMakePoint(self.bounds.size.width - 5, self.bounds.size.height - 2)];

    curveToPoint = NSMakePoint(self.bounds.size.width, self.bounds.size.height + 3);
    [path curveToPoint:curveToPoint controlPoint1:curveToPoint controlPoint2:curveToPoint];

    [path setLineWidth:1];
    [[NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.4 alpha:1.0] set];
    [path stroke];
    [path setClip];

    if ([self selected]) {
        NSColor *start = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
        NSColor *end = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        [gradient drawInRect:dirtyRect angle:270];
    }
    else if ([self hover]) {
        NSColor *start = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
        NSColor *end = [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        [gradient drawInRect:dirtyRect angle:270];
    }
    else {
        NSColor *start = [NSColor colorWithCalibratedWhite:0.68 alpha:1.0];
        NSColor *end = [NSColor colorWithCalibratedWhite:0.65 alpha:1.0];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        [gradient drawInRect:dirtyRect angle:270];
    }

    [super drawRect:dirtyRect];

    [NSGraphicsContext restoreGraphicsState];
}

@end
