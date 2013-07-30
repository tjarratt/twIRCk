//
//  GLGWriteDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGWriteDelegate.h"

@implementation GLGWriteDelegate

- (id) init {
    if (self = [super init]) {
        commands = [[NSMutableArray alloc] initWithCapacity:0];
    }

    return self;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent) eventCode {
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            {
                if ([commands count] > 0) {
                    NSString *command = [commands objectAtIndex:0];
                    NSData *data = [[command stringByAppendingString:@"\r\n"] dataUsingEncoding:NSASCIIStringEncoding];
                    unsigned long length = [data length];

                    NSLog(@"writing command: %@", command);

                    uint8_t *readBytes = (uint8_t *) [data bytes];
                    uint8_t buffer[length];
                    (void)memcpy(buffer, readBytes, length);

                    length = [(NSOutputStream *)stream write:(const uint8_t *)buffer maxLength:length];

                    if (length < [command length]) {
                        [commands insertObject:[command substringFromIndex:length] atIndex:0];
                    }
                    else {
                        [commands removeObjectAtIndex:0];
                    }
                }
            }

            break;
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasBytesAvailable:
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"write: event end encountered");
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"write: event error occurred");
            {
                NSError *err = [stream streamError];
                NSLog(@"error: %ld ... %@", (long)[err code], [err localizedDescription]);
            }
            break;
        case NSStreamEventNone:
            NSLog(@"write: event none?");
            break;
    }
}

- (void) addCommand:(NSString *)command {
    [commands addObject:command];
}


@end
