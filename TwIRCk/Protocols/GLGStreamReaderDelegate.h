//
//  GLGStreamReaderDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/19/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GLGStreamReaderDelegate <NSObject>
@required
- (void) receivedString:(NSString *) string;
- (void) didConnectToHost;
- (void) streamDidClose;
@end