//
//  GLGChatViewDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 1/1/14.
//  Copyright (c) 2014 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GLGChatViewDelegate <NSObject>
@required
- (void) didSubmitText:(NSString *) text;
- (void) didClickOnNick:(NSString *) nick;
- (void) closeCurrentChannel;

@end
