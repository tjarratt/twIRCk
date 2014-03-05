//
//  GLGFakeWindowProvider <GLGWindowProvider>.m
//  TwIRCk
//
//  Created by Tim Jarratt on 3/5/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import "GLGFakeWindowProvider.h"

@implementation GLGFakeWindowProvider
-(NSWindow *) window {
    return [[NSWindow alloc] init];
}
@end
