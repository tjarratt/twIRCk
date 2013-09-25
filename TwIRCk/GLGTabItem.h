//
//  GLGTabItem.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLGTabItem : NSView {
    NSTextField *textfield;
    NSImageView *imageView;
    NSImage *closeButton;
    NSImage *closeButtonSelected;

    BOOL _selected;
    BOOL _hover;

    NSRect selectedRect;
    NSRect unselectedRect;
    NSTrackingArea *trackingArea;
    NSTrackingArea *trackingAreaSelected;
}

@property NSString *name;
@property id owner;

- (id)initWithFrame:(NSRect)frame andLabel:(NSString *) label;
- (void)setSelected:(BOOL)flag;
- (void)setHover:(BOOL)flag;

@end
