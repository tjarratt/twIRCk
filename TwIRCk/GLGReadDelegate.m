//
//  GLGReadDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGReadDelegate.h"
@implementation GLGReadDelegate

@synthesize delegate;

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent) eventCode {
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            break;
        case NSStreamEventOpenCompleted:
            if (delegate) {
                [delegate didConnectToHost:@"dummyValue"];
            }
            break;
        case NSStreamEventHasBytesAvailable:
            {
                NSNumber *bytesRead = @0;
                NSMutableData *data = [NSMutableData alloc];
                uint8_t buffer[1024];
                NSInteger length = 0;
                length = [(NSInputStream *)stream read:buffer maxLength:1024];

                if (length) {
                    [data appendBytes:(const void *)buffer length:length];
                    bytesRead = [NSNumber numberWithInteger:[bytesRead intValue] + length ];

                    if (delegate) {
                        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        [delegate receivedString:str];
                    }
                }
                else {
                    NSLog(@"reader: no buffer, nothing to read!");
                }
            }

            break;
        case NSStreamEventEndEncountered:
            NSLog(@"reader: event end encountered");
            break;
        case NSStreamEventErrorOccurred:
            {
                NSError *error = [stream streamError];
                NSLog(@"read errr: %ld ... %@", [error code], [error localizedDescription]);
            }
            break;
        case NSStreamEventNone:
            NSLog(@"event none?");
            break;
    }
}
@end
