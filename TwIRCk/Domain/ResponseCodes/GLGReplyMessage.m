//
//  GLGReplyMessage.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGReplyMessage.h"

@implementation GLGReplyMessage

- (id) initWithName:(NSString *)_name {
    if (self = [super init]) {
        self.name = _name;
        self.type = @"reply";
    }

    return self;
}

@end
