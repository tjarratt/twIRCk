//
//  GLGWriteDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGWriteDelegate.h"

@implementation GLGWriteDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent) eventCode {
    NSLog(@"write stream delegate");
    
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"has space available");
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"open completed!");

            if (YES) {
                NSString *string = @"PASS password\r\nNICK timbot\r\nUSER timbot\r\n";
                NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
                unsigned long length = [data length];

                uint8_t *readBytes = (uint8_t *) [data bytes];

                NSLog(@"going to write %lu bytes", length);
                uint8_t buffer[length];
                (void)memcpy(buffer, readBytes, length);

                length = [(NSOutputStream *)stream write:(const uint8_t *)buffer maxLength:length];
                NSLog(@"remaining bytes to write: %lu", length);
            }

            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"bytes available");
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"event end encountered");
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"event error occurred");
            break;
        case NSStreamEventNone:
            NSLog(@"event none?");
            break;
    }
}


@end
