//
//  GLGReadDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGReadDelegate.h"
@implementation GLGReadDelegate
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent) eventCode {
    NSLog(@"reader stream delegate");

    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"has space available");
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"open completed!");
            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"bytes available");

            {
                NSNumber *bytesRead = @0;
                NSMutableData *data = [NSMutableData alloc];
                uint8_t buffer[1024];
                NSInteger length = 0;
                length = [(NSInputStream *)stream read:buffer maxLength:1024];

                if (length) {
                    [data appendBytes:(const void *)buffer length:length];
                    bytesRead = [NSNumber numberWithInteger:[bytesRead intValue] + length ];
                }
                else {
                    NSLog(@"no buffer, nothing to read!");
                }
            }

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
