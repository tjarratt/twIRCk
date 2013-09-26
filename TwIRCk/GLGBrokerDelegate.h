//
//  GLGBrokerDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/19/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLGIRCBroker;

@protocol GLGBrokerDelegate <NSObject>
@required
-(void) connectedToServer:(NSString *)hostname
               fromBroker:(GLGIRCBroker *) broker;

-(void) joinChannel:(NSString *) channel
           onServer:(NSString *) hostname
      userInitiated:(BOOL) initiatedByUser
         fromBroker:(GLGIRCBroker *) broker;

-(void) receivedString:(NSString *) string
             inChannel:(NSString *) channel
              fromHost:(NSString *) host
            fromBroker:(GLGIRCBroker *) broker;

-(void) updateOccupants:(NSArray *) occupants forChannel:(NSString *) channel;
@end
