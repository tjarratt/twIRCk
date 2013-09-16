//
//  GLGDefaultValueTextField.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGDefaultValueTextField.h"

@implementation GLGDefaultValueTextField

- (id) initWithFrame:(NSRect) frame defaultValue:(NSString *) value {
    if (self = [super initWithFrame:frame]) {
        defaultValue = value;
    }
    
    return self;
}

- (void) setDefaultValue:(NSString *) value {
    defaultValue = value;
    [[self cell] setPlaceholderString:NSLocalizedString(defaultValue, self.identifier)];
}

- (NSString *) stringValue {
    NSString *value = [super stringValue];
    if ([value isEqualToString:@""]) {
        return defaultValue;
    }
    else {
        return value;
    }
}

@end
