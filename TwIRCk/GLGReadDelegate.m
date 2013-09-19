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
        previousBuffer = @"";
    }

    return self;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent) eventCode {
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            break;
        case NSStreamEventOpenCompleted:
            if (delegate) {
                [delegate didConnectToHost];
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
                    return NSLog(@"reader: no buffer, nothing to read!");
                }

                [data appendBytes:(const void *)buffer length:length];
                bytesRead = [NSNumber numberWithInteger:[bytesRead intValue] + length ];

                if (delegate) {
                    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if (previousBuffer == nil ) {
                        NSLog(@"ANOTHER interesting edge case! got message %@", str);
                    }
                    str = [previousBuffer stringByAppendingString:str];
                    previousBuffer = @"";

                    NSMutableArray *components = [[str componentsSeparatedByString:@"\n"] mutableCopy];

                    // if the last character is not \n, pull it apart and store it in previousBuffer
                    unichar lastChar = [str characterAtIndex:(str.length - 1)];
                    if (lastChar != 10) {
                        previousBuffer = [components objectAtIndex:(components.count - 1)];
                        if (previousBuffer == nil ) {
                            NSLog(@"interesting edge case! got message %@", str);
                            NSLog(@"with %lu components, last char was %d and previous buffer was set to 'last component': %@", [components count], lastChar, [components objectAtIndex:(components.count - 1)]);
                        }
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
            [delegate streamDidClose];
            break;
        case NSStreamEventErrorOccurred:
            {
                NSError *error = [stream streamError];
                NSLog(@"read errr: %ld ... %@", [error code], [error localizedDescription]);
                [delegate streamDidClose];
            }
            break;
        case NSStreamEventNone:
            break;
    }
}
@end
