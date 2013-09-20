//
//  GLGTabView.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGTabItem.h"

@interface GLGTabView : NSView {
    NSMutableArray *tabs;
    GLGTabItem *test_tab;
    NSUInteger selected_tab_index;
}

- (NSUInteger) count;
- (void) addItem:(NSString *) title;
- (void) addItem:(NSString *) title selected:(BOOL) isSelected;
- (void) tabForward;
- (void) tabBackward;

- (void) removeTabNamed:(NSString *) name;

@end
