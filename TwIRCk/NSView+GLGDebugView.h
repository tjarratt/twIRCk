//
//  NSView+GLGDebugView.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/6/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/objc-runtime.h>
#import "NSObject+MethodRedirection.h"

@interface NSView (GLGDebugView)
- (void) setBackgroundColor:(NSColor *) color;
- (void) originalDrawRect:(NSRect) rect;
@end
