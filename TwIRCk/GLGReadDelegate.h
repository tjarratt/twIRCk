//
//  GLGReadDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/24/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGStreamReaderDelegate.h"

@interface GLGReadDelegate : NSObject <NSStreamDelegate> {
    NSString *previousBuffer;
}

@property id <GLGStreamReaderDelegate> delegate;
@end
