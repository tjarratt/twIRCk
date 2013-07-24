//
//  GLGAppDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGResponseCodes.h"

@interface GLGAppDelegate : NSObject <NSApplicationDelegate> {
    GLGResponseCodes *responseLookup;
}

@property (assign) IBOutlet NSWindow *window;

@end
