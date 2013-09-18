//
//  GLGReadDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GLGReaderDelegate;

@interface GLGReadDelegate : NSObject <NSStreamDelegate> {
    NSString *previousBuffer;
}

@property id <GLGReaderDelegate> delegate;
@end

#pragma mark - reader delegate
@protocol GLGReaderDelegate

@required
- (void) receivedString:(NSString *) string;
- (void) didConnectToHost:(NSString *) hostname;

@end