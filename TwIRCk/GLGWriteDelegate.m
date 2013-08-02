//
//  GLGWriteDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGWriteDelegate.h"

@implementation GLGWriteDelegate

@synthesize canWrite, writeStream;

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
                    [self writeNextCommandInQueue:stream];
                }
                else {
                    [self setCanWrite:YES];
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
            {
                NSError *err = [stream streamError];
                NSLog(@"write error: %ld ... %@", (long)[err code], [err localizedDescription]);
            }
            break;
        case NSStreamEventNone:
            NSLog(@"write: event none?");
            break;
    }
}

- (void) writeNextCommandInQueue:(NSStream *)stream {
    NSString *command = [commands objectAtIndex:0];
    NSData *data = [[command stringByAppendingString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned long length = [data length];

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

    [self setCanWrite:NO];
}

- (void) addCommand:(NSString *)command {
    [commands addObject:command];

    if ([self canWrite]) {
        [self writeNextCommandInQueue:writeStream];
    }
}


@end
