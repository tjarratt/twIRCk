//
//  GLGChatTextField.h
//  TwIRCk
//
//  Created by Tim Jarratt on 8/3/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLGChatTextField : NSView <NSTextFieldDelegate> {
    NSTextField *textfield;
    NSUInteger currentTextPointer;
    NSMutableArray *history;
}

- (void) forward;
- (void) backward;
- (NSString *) currentText;

- (NSString *) stringValue;
- (void) clearTextField;
- (void) setTarget:(id) target;
- (void) setAction:(SEL) action;

@end
