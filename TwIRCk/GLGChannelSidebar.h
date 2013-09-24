//
//  GLGChannelSidebar.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGChannelContent.h"
#import "GLGGradientSidebar.h"

@interface GLGChannelSidebar : NSView {
    GLGChannelContent *innerView;
    GLGGradientSidebar *scrollView;
}

- (void) showChannelOccupants:(NSArray *) occupants;

@end
