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
}

- (void) addItem:(NSString *) title;

@end
