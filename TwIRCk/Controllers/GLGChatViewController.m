//
//  GLGChatViewController.m
//  TwIRCk
//
//  Created by Tim Jarratt on 12/10/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGChatViewController.h"

@interface GLGChatViewController ()
@property (retain, readwrite) GLGChatView *view;
@property (retain, readwrite) NSString *currentChannel;
@property (retain, readwrite) NSMutableDictionary *chatlogs;
@property (retain, strong, readwrite) GLGIRCBroker *currentBroker;
@property (retain, strong, readwrite) NSMutableArray *brokers;
@end

@implementation GLGChatViewController

- (instancetype) initWithWindow:(NSWindow *) aWindow {
    if (self = [super init]) {
        self.view = [[GLGChatView alloc] initWithWindow:aWindow andDelegate:self];
        [self setBrokers:[[NSMutableArray alloc] init]];
        [self setChatlogs:[[NSMutableDictionary alloc] init]];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTabSelection:) name:@"did_switch_tabs" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabClosed:) name:@"removed_last_tab" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabCloseButtonClicked:) name:@"chatview_closed_tab" object:nil];
    }

    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) connectToServer:(IRCServer *) server {
    GLGIRCBroker *broker = [[GLGIRCBroker alloc] initWithDelegate:self];
    [broker connectToServer:server];
    [self.brokers addObject:broker];

    if ([self.brokers count] == 1) {
        [self setCurrentBroker:broker];
    }
}

#pragma mark - GLGChatViewDelegate methods
- (void) didSubmitText:(NSString *)text {
    [self.currentBroker didSubmitText:text inChannel:self.currentChannel];
}

- (void) closeCurrentChannel {
    [self closedTabNamed:self.currentChannel forBroker:self.currentBroker];
}

- (void) didClickOnNick:(NSString *) nick {
    NSString *key = [self.currentBroker.hostname stringByAppendingString:nick];
    GLGChatLogView *theChatLog = [self.chatlogs objectForKey:key];
    if (theChatLog == nil) {
        theChatLog = [self.view newChatlog];

        NSString *key = [self.currentBroker.hostname stringByAppendingString:nick];
        [self.chatlogs setValue:theChatLog forKey:key];
        [self.view.tabView addItem:nick selected:YES forOwner:self.currentBroker];
    }

    [self setCurrentChannel:nick];
    [self.view.scrollview setDocumentView:theChatLog];
    [self.view.tabView setSelectedChannelNamed:nick];

    NSArray *occupants = [self.currentBroker occupantsInChannel:self.currentChannel];
    [self updateOccupants:occupants forChannel:self.currentChannel];

}

#pragma mark - NSNotification methods
- (void) tabClosed:(NSNotification *) notification {
    [self.view.window close];
}

- (void) tabCloseButtonClicked:(NSNotification *) notification {
    NSDictionary *obj = [notification object];
    GLGIRCBroker *theBroker = [obj valueForKey:@"owner"];
    [self closedTabNamed:[obj valueForKey:@"name"] forBroker:theBroker];
}

- (void) handleTabSelection:(NSNotification *) notification {
    [self setCurrentChannel:[[notification object] name]];
    [self setCurrentBroker:[[notification object] owner]];
    NSString *key = [self.currentBroker.hostname stringByAppendingString:self.currentChannel];
    GLGChatLogView *chat = [self.chatlogs objectForKey:key];

    assert( chat != nil );

    [self.view.scrollview setDocumentView:chat];
    NSPoint newOrigin = NSMakePoint(0, NSMaxY([self.view.scrollview.documentView frame]) -
                                    [self.view.scrollview.contentView bounds].size.height);
    [self.view.scrollview.documentView scrollPoint:newOrigin];

    NSArray *occupants = [self.currentBroker occupantsInChannel:self.currentChannel];
    [self updateOccupants:occupants forChannel:self.currentChannel];
}

#pragma mark - IRCBroker delegate methods
- (void) mentionedInChannel:(NSString *) channel fromBroker:(GLGIRCBroker *)broker {
    
}

- (void) connectedToServer:(NSString *)hostname fromBroker:(GLGIRCBroker *) broker {
    [self.view didConnectToHost:hostname];
    NSString *key = [hostname stringByAppendingString:hostname];

    if ([self.chatlogs objectForKey:key] != nil) {
        return;
    }

    [self.view.tabView addItem:hostname forOwner:broker];
    GLGChatLogView *newLog = [self.view newChatlog];
    [self.chatlogs setValue:newLog forKey:key];

    if ([self.view.tabView count] == 1) {
        [self setCurrentBroker:broker];
        [self setCurrentChannel:hostname];
        [self.view.scrollview setDocumentView:newLog];
    }

}

- (void) joinChannel:(NSString *) channel
            onServer:(NSString *) hostname
       userInitiated:(BOOL)initiatedByUser
          fromBroker:(GLGIRCBroker *) broker {
    NSString *key = [broker.hostname stringByAppendingString:channel];
    GLGChatLogView *theChatLog = [self.chatlogs objectForKey:key];
    if (theChatLog == nil) {
        theChatLog = [self.view newChatlog];

        NSString *key = [broker.hostname stringByAppendingString:channel];
        [self.chatlogs setValue:theChatLog forKey:key];
        [self.view.tabView addItem:channel selected:initiatedByUser forOwner:broker];
    }

    if (initiatedByUser) {
        [self setCurrentBroker:broker];
        [self setCurrentChannel:channel];
        [self.view.scrollview setDocumentView:theChatLog];
        [self.view.tabView setSelectedChannelNamed:channel];

        NSArray *occupants = [self.currentBroker occupantsInChannel:self.currentChannel];
        [self updateOccupants:occupants forChannel:self.currentChannel];
    }
}

- (void) receivedString:(NSString *)string
              inChannel:(NSString *)channel
               fromHost:(NSString *)host
             fromBroker:(GLGIRCBroker *)broker
{
    if (broker == nil) {
        return NSLog(@"nil broker trying to send message to channel %@ to host %@", channel, host);
    }

    NSString *key = [broker.hostname stringByAppendingString:channel];
    GLGChatLogView *log = [self.chatlogs objectForKey:key];

    if (log == nil) {
        [self.view.tabView addItem:channel selected:NO forOwner:broker];
        log = [self.view newChatlog];
        [self.chatlogs setValue:log forKey:key];
    }

    if (channel == nil) {
        channel = self.currentChannel;
    }

    [log setEditable:YES];
    [log setSelectedRange:NSMakeRange([[log textStorage] length], 0)];
    [log insertText:string];
    [log setEditable:NO];

    NSDictionary *dict = @{@"name" : channel, @"owner" : broker};
    NSString *notificationName = [@"message_received_" stringByAppendingString:channel];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:dict];
}

-(void) updateOccupants:(NSArray *) occupants forChannel:(NSString *) channel {
    if ([channel isEqualToString:self.currentChannel]) {
        [self.view.sidebar showChannelOccupants:occupants];
    }
}

- (void) mentionedInChannel:(NSString *) channel fromBroker:(GLGIRCBroker *)broker byUser:(NSString *) whom {
    NSDictionary *dict = @{@"name": channel, @"owner" :broker};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"highlight_tab" object:nil userInfo:dict];

    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:[NSString stringWithFormat:@"You were mentioned in %@ on %@", channel, broker.hostname]];
    [notification setInformativeText:[NSString stringWithFormat:@"You were pinged in %@ by %@ on %@", channel, whom, broker.hostname]];
    [notification setSoundName:@"Ping"];

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void) closedTabNamed:(NSString *) channel forBroker:(GLGIRCBroker *) broker {
    [self.view.tabView removeTabNamed:channel fromOwner:broker];
    [broker willPartChannel:channel];

    NSString *key = [broker.hostname stringByAppendingString:channel];
    [self.chatlogs removeObjectForKey:key];
}

#pragma mark - Occupant Delegate methods
- (void) clickedOnNick:(NSString *) nick {

}

@end
