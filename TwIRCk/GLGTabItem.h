//
//  GLGTabItem.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLGTabItem : NSTextField

@property NSString *name;
@property BOOL selected;
@property BOOL hover;

- (id)initWithFrame:(NSRect)frame andLabel:(NSString *) label;

@end
