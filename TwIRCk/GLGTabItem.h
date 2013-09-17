//
//  GLGTabItem.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLGTabItem : NSTextField

@property BOOL selected;

- (id)initWithFrame:(NSRect)frame andLabel:(NSString *) label;

@end
