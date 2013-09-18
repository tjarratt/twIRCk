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

- (id) init {
    if (self = [super init]) {
        previousBuffer = nil;
    }

    return self;
}

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

                if (!length) {
                    NSLog(@"reader: no buffer, nothing to read!");
                    return;
                }

                [data appendBytes:(const void *)buffer length:length];
                bytesRead = [NSNumber numberWithInteger:[bytesRead intValue] + length ];

                if (delegate) {
                    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if (previousBuffer != nil) {
                        str = [previousBuffer stringByAppendingString:str];
                        previousBuffer = nil;
                    }

                    NSMutableArray *components = [[str componentsSeparatedByString:@"\n"] mutableCopy];

                    // if the last character is not \n, pull it apart and store it in previousBuffer
                    unichar lastChar = [str characterAtIndex:(str.length - 1)];
                    if (lastChar != 10) {
                        previousBuffer = [components objectAtIndex:(components.count - 1)];
                        [components removeObjectAtIndex:(components.count -1)];
                    }

                    [components enumerateObjectsUsingBlock:^(NSString * string, NSUInteger index, BOOL *stop) {
                        if ([string length] > 0) {
                            [delegate receivedString:string];
                        }
                    }];
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
