//
//  GLGSidebarOccupant.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/30/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGOccupantDelegate.h"
#import "NSColor+GLG.h"
#import "GLGLabelView.h"

@interface GLGSidebarOccupant : GLGLabelView

@property id <GLGOccupantDelegate> delegate;

@end
