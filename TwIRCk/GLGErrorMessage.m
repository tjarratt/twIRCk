//
//  GLGErrorMessage.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGErrorMessage.h"

@implementation GLGErrorMessage
-(id) initWithName:(NSString *) aName {
    if (self = [super init]) {
        self.name = aName;
        self.type = @"error";
    }

    return self;
}
@end
