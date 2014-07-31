//
//  GLGErrorMessage.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGErrorMessage.h"

@implementation GLGErrorMessage
-(id) initWithName:(NSString *) _name {
    if (self = [super init]) {
        self.name = _name;
        self.type = @"error";
    }

    return self;
}
@end
