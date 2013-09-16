//
//  GLGDefaultValueTextField.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/16/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLGDefaultValueTextField : NSTextField {
    NSString *defaultValue;
}

- (void) setDefaultValue:(NSString *) value;

@end
