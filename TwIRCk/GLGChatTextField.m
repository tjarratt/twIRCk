//
//  GLGChatTextField.m
//  TwIRCk
//
//  Created by Tim Jarratt on 8/3/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGChatTextField.h"

@implementation GLGChatTextField

const int capacity = 50;

- (id) initWithFrame:(NSRect) frame {
    if (self = [super initWithFrame:frame]) {
        currentTextPointer = 0;
        history = [[NSMutableArray alloc] initWithCapacity:capacity];
        for (int i = 0; i < capacity; ++i) {
            [history insertObject:@"" atIndex:i];
        }


        textfield = [[NSTextField alloc] initWithFrame:frame];
        [textfield setDelegate:self];
        [[textfield cell] setPlaceholderString:NSLocalizedString(@"Send a message...", @"input placeholder message")];
        [self addSubview:textfield];

    }

    return self;
}

- (void) setFrame:(NSRect) frameRect {
    [super setFrame:frameRect];
    [textfield setFrame:frameRect];
}

- (NSString *) currentText {
    return [history objectAtIndex:currentTextPointer];
}

- (void) recordHistory {
    NSString *string = [textfield stringValue];
    [history insertObject:string atIndex:currentTextPointer++];

    if (currentTextPointer == capacity) {
        --currentTextPointer;
        for (int i = 0; i < capacity - 1; ++i) {
            [history insertObject:[history objectAtIndex:i+1] atIndex:i];
        }

        [history insertObject:@"" atIndex:currentTextPointer];
    }
}

# pragma mark - textfield methods
- (NSString *) stringValue {
    return [textfield stringValue];
}

- (void) clearTextField {
    [self recordHistory];
    [textfield setStringValue:@""];
}

- (void) setTarget:(id) target {
    [textfield setTarget:target];
}

- (void) setAction:(SEL) action {
    [textfield setAction:action];
}

# pragma mark - history control
- (BOOL) control:(NSControl *) control textView:(NSTextView *) textView
doCommandBySelector:(SEL) commandSelector {
    if (commandSelector == @selector(scrollPageUp:) || commandSelector == @selector(scrollPageDown:)) {
        SEL action = [self historyActionForEvent:[NSApp currentEvent]];

#       pragma clang diagnostic push
#       pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:action];
#       pragma clang diagnostic pop

        return YES;
    }

    return NO;
}

- (SEL) historyActionForEvent:(NSEvent *) e {
    NSUInteger flags = (e.modifierFlags & NSDeviceIndependentModifierFlagsMask);
    BOOL isControl = (flags & NSControlKeyMask) == NSControlKeyMask;

    if (isControl && e.keyCode == 125) {
        return @selector(forward);
    }
    else if (isControl && e.keyCode == 126) {
        return @selector(backward);
    }
    else {
        return nil;
    }
}

- (void) forward {
    if (currentTextPointer == capacity - 1) { return; }

    NSString *nextValue = [history objectAtIndex:currentTextPointer + 1];
    if ([nextValue isEqualToString:@""]) { return; }

    [textfield setStringValue:[history objectAtIndex:++currentTextPointer]];
}

- (void) backward {
    if (currentTextPointer == 0) { return; }

    [textfield setStringValue:[history objectAtIndex:--currentTextPointer]];
}

@end
