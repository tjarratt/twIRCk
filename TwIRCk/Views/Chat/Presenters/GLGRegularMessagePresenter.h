//
//  GLGRegularMessagePresenter.h
//  TwIRCk
//
//  Created By Tim Jarratt on 8/1/14
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGMessagePresenter.h"

@interface GLGRegularMessagePresenter : NSObject <GLGMessagePresenter> {}
- (NSColor *) color;
@end