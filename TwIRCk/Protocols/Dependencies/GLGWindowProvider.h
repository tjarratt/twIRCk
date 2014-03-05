//
//  GLGWindowProvider.h
//  TwIRCk
//
//  Created by Tim Jarratt on 3/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol GLGWindowProvider <NSObject>
@required
-(NSWindow *) window;
@end
