//
//  GLGOccupantDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/30/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GLGOccupantDelegate <NSObject>
- (void) clickedOnNick:(NSString *) nick;
@end
