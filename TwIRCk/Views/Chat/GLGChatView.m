//
//  GLGChatView.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGChatView.h"

const CGFloat tabHeight = 30;
const CGFloat inputHeight = 50;
const CGFloat occupantsSidebarWidth = 150;

@implementation GLGChatView

@synthesize connectView;

- (id) initWithWindow:(NSWindow *) theWindow {
    if (self = [super init]) {
        window = theWindow;
        [window setMinSize:NSMakeSize(300, 200)];
        NSView *content = [window contentView];
        NSRect frame = [content frame];
        [self setFrame:frame];

        input = [[GLGChatTextField alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, inputHeight)];
        [input setTarget:self];
        [input setAction:@selector(didSubmitText)];
        [input setNextKeyView:self];
        [self addSubview:input];

        tabView = [[GLGTabView alloc] initWithFrame:NSMakeRect(0, frame.size.height - tabHeight, frame.size.width, tabHeight)];
        [tabView setNextKeyView:input];
        [self addSubview:tabView];

        NSRect chatRect = NSMakeRect(0, inputHeight, frame.size.width - occupantsSidebarWidth, frame.size.height - tabHeight - inputHeight);
        scrollview = [[NSScrollView alloc] initWithFrame:chatRect];
        [scrollview setBorderType:NSNoBorder];
        [scrollview setHasVerticalScroller:YES];
        [scrollview setHasHorizontalScroller:NO];
        [scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollview setScrollsDynamically:YES];
        [scrollview setNextKeyView:input];
        [self addSubview:scrollview];

        NSRect channelRect = NSMakeRect(frame.size.width - occupantsSidebarWidth, inputHeight, occupantsSidebarWidth, frame.size.height - tabHeight - inputHeight);
        sidebar = [[GLGChannelSidebar alloc] initWithFrame:channelRect];
        [self addSubview:sidebar];

        [window makeFirstResponder:input];
        [window makeKeyAndOrderFront:nil];
        [window setDelegate:self];

        currentChannel = nil;
        brokers = [[NSMutableArray alloc] init];
        chatlogs = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTabSelection:) name:@"did_switch_tabs" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(close:) name:@"removed_last_tab" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabCloseButtonClicked:) name:@"chatview_closed_tab" object:nil];
    }

    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSWindow delegate methods
- (void) windowDidResize:(NSNotification *) notification {
    NSWindow *theWindow = [notification object];
    NSRect frame = [[theWindow contentView] frame];
    [self setFrame:frame];

    NSRect tabFrame = NSMakeRect(0, frame.size.height - tabHeight, frame.size.width, tabHeight);
    [tabView setFrame:tabFrame];

    NSRect scrollFrame = NSMakeRect(0, inputHeight, frame.size.width - occupantsSidebarWidth, frame.size.height - tabHeight - inputHeight);
    [scrollview setFrame:scrollFrame];

    NSRect sidebarFrame = NSMakeRect(frame.size.width - occupantsSidebarWidth, inputHeight, occupantsSidebarWidth, frame.size.height - tabHeight - inputHeight);
    [sidebar setFrame:sidebarFrame];

    NSRect inputFrame = NSMakeRect(0, 0, frame.size.width, inputHeight);
    [input setFrame:inputFrame];

    [chatlogs enumerateKeysAndObjectsUsingBlock:^(id key, GLGChatTextField *obj, BOOL *stop) {
        [obj setFrame:scrollFrame];
    }];
}

#pragma mark - handling chat logs
- (GLGChatLogView *) newChatlog {
    NSSize contentSize = [scrollview contentSize];
    GLGChatLogView *textview = [[GLGChatLogView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
    [textview setMinSize:NSMakeSize(0, contentSize.height)];
    [textview setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [textview setVerticallyResizable:YES];
    [textview setHorizontallyResizable:NO];
    [textview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[textview textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
    [[textview textContainer] setWidthTracksTextView:YES];
    [textview setEditable:NO];
    [textview setRichText:YES];
    [textview setNextKeyView:input];
    [textview setBackgroundColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];

    return textview;
}

- (GLGChatLogView *) currentChatlogTextView {
    NSString *key = [currentBroker.hostname stringByAppendingString:currentChannel];
    return [chatlogs objectForKey:key];
}


#pragma mark - NSNotificationCenter actions
- (void) close:(NSNotification *) notification {
    [[self window] close];
}

- (void) tabCloseButtonClicked:(NSNotification *) notification {
    NSDictionary *obj = [notification object];
    GLGIRCBroker *theBroker = [obj valueForKey:@"owner"];
    [self closedTabNamed:[obj valueForKey:@"name"] forBroker:theBroker];
}

- (void) handleTabSelection:(NSNotification *) notification {
    currentChannel = [[notification object] name];
    currentBroker = [[notification object] owner];
    NSString *key = [currentBroker.hostname stringByAppendingString:currentChannel];
    GLGChatLogView *chat = [chatlogs objectForKey:key];

    assert( chat != nil );

    [scrollview setDocumentView:chat];
    NSPoint newOrigin = NSMakePoint(0, NSMaxY([[scrollview documentView] frame]) -
                                    [[scrollview contentView] bounds].size.height);
    [[scrollview documentView] scrollPoint:newOrigin];

    NSArray *occupants = [currentBroker occupantsInChannel:currentChannel];
    [self updateOccupants:occupants forChannel:currentChannel];
}

#pragma mark - connection methods
- (void) connectToServer:(IRCServer *) server {
    GLGIRCBroker *broker = [[GLGIRCBroker alloc] initWithDelegate:self];
    [broker connectToServer:server];
    [brokers addObject:broker];

    if ([brokers count] == 1) {
        currentBroker = broker;
    }
}

#pragma mark - notifications
- (void) didConnectToHost:(NSString *) host {
    [connectView shouldClose];
}

- (void) didSubmitText {
    NSString *string = [input stringValue];
    if ([string isEqualToString:@""]) { return; }

    if (currentChannel == nil || currentBroker == nil) {
        NSLog(@"currentChannel is nil. Probably not connected");
        return [self receivedString:@"Error: not in any channel. Probably still waiting for connection" inChannel:@"error" fromHost:[currentBroker hostname] fromBroker:nil];
    }

    GLGIRCMessage *msg = [currentBroker didSubmitText:string inChannel:currentChannel];
    NSString *messageToDisplay = [msg message];
    NSString *channelToDisplay = [msg target];
    NSString *activeHost = [currentBroker hostname];

    if (currentChannel != channelToDisplay) {
        currentChannel = channelToDisplay;
        [self joinChannel:currentChannel onServer:activeHost userInitiated:YES fromBroker:currentBroker];
    }

    [input clearTextField];
    [self receivedString:[messageToDisplay stringByAppendingString:@"\n"] inChannel:currentChannel fromHost:activeHost fromBroker:currentBroker];
}

#pragma mark - IRC Broker Delegate methods
- (void) connectedToServer:(NSString *)hostname fromBroker:(GLGIRCBroker *) broker {
    [self didConnectToHost:hostname];
    NSString *key = [hostname stringByAppendingString:hostname];

    if ([chatlogs objectForKey:key] != nil) {
        return;
    }
    
    [tabView addItem:hostname forOwner:broker];
    GLGChatLogView *newLog = [self newChatlog];
    [chatlogs setValue:newLog forKey:key];
    if ([tabView count] == 1) {
        currentBroker = broker;
        currentChannel = hostname;
        [scrollview setDocumentView:newLog];
    }
}

- (void) joinChannel:(NSString *) channel
            onServer:(NSString *) hostname
       userInitiated:(BOOL)initiatedByUser
          fromBroker:(GLGIRCBroker *) broker {
    NSString *key = [broker.hostname stringByAppendingString:channel];
    GLGChatLogView *theChatLog = [chatlogs objectForKey:key];
    if (theChatLog == nil) {
        theChatLog = [self newChatlog];

        NSString *key = [broker.hostname stringByAppendingString:channel];
        [chatlogs setValue:theChatLog forKey:key];
        [tabView addItem:channel selected:initiatedByUser forOwner:broker];
    }

    if (initiatedByUser) {
        currentBroker = broker;
        currentChannel = channel;
        [scrollview setDocumentView:theChatLog];
        [tabView setSelectedChannelNamed:channel];

        NSArray *occupants = [currentBroker occupantsInChannel:currentChannel];
        [self updateOccupants:occupants forChannel:currentChannel];
    }
}

- (void) receivedString:(NSString *)string
              inChannel:(NSString *)channel
               fromHost:(NSString *)host
             fromBroker:(GLGIRCBroker *)broker
{
    [self receivedString:string inChannel:channel fromHost:host fromBroker:broker withPresenter:[[GLGRegularMessagePresenter alloc] init]];
}

- (void) receivedSystemString:(NSString *)string
                  inChannel:(NSString *)channel
                   fromHost:(NSString *)host
                 fromBroker:(GLGIRCBroker *)broker
{
    [self receivedString:string inChannel:channel fromHost:host fromBroker:broker withPresenter:[[GLGSystemMessagePresenter alloc] init]];
}

- (void) receivedString:(NSString *)string
              inChannel:(NSString *)channel
               fromHost:(NSString *)host
             fromBroker:(GLGIRCBroker *)broker
               withPresenter:(id<GLGMessagePresenter>)presenter
{
    if (broker == nil) {
        return NSLog(@"nil broker trying to send message to channel %@ to host %@", channel, host);
    }

    // http://devmag.org.za/2012/07/29/how-to-choose-colours-procedurally-algorithms/
    NSArray *occupants = [broker occupantsInChannel:channel];
    NSArray *colors = [self colorsForOccupants:occupants];

    NSString *key = [broker.hostname stringByAppendingString:channel];
    GLGChatLogView *log = [chatlogs objectForKey:key];

    if (log == nil) {
        [tabView addItem:channel selected:NO forOwner:broker];
        log = [self newChatlog];
        [chatlogs setValue:log forKey:key];
     }

    [log setEditable:YES];
    NSUInteger length = [[log textStorage] length];
    [log setSelectedRange:NSMakeRange(length, 0)];
    [log insertText:string];

    NSRange theRange = NSMakeRange(length, string.length);
    [log setSelectedRange:theRange];

    [log.textStorage removeAttribute:NSForegroundColorAttributeName range:theRange];
    [log.textStorage addAttribute:NSForegroundColorAttributeName value:presenter.color range:theRange];

    // walk the occupants and see if we need to colorize any of the string
    [occupants enumerateObjectsUsingBlock:^(NSString * occupant, NSUInteger idx, BOOL *stop) {
        NSRange searchRange = NSMakeRange(0, string.length);
        NSRange foundRange;
        while (searchRange.location < string.length) {
            searchRange.length = string.length - searchRange.location;
            foundRange = [string rangeOfString:occupant options:nil range:searchRange];
            if (foundRange.location != NSNotFound) {
                searchRange.location = foundRange.location+foundRange.length;

                NSColor *color = [colors objectAtIndex:idx];
                NSRange range = NSMakeRange(length + foundRange.location, foundRange.length);
                [log.textStorage removeAttribute:NSForegroundColorAttributeName range:range];
                [log.textStorage addAttribute:NSForegroundColorAttributeName value:color range:range];
            } else {
                break;
            }
        }
    }];

    [log setSelectedRange:NSMakeRange(0, 0)];

    [log setEditable:NO];

    NSDictionary *dict = @{@"name" : channel, @"owner" : broker};
    NSString *notificationName = [@"message_received_" stringByAppendingString:channel];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:dict];
}

-(void) updateOccupants:(NSArray *) occupants forChannel:(NSString *) channel {
    NSArray *colors = [self colorsForOccupants:occupants];
    if ([channel isEqualToString:currentChannel]) {
        [sidebar showChannelOccupants:occupants withColors:colors];
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

#pragma mark - NSResponder methods
- (void) keyUp:(NSEvent *) theEvent {
    unsigned short keycode = [theEvent keyCode];
    NSUInteger flags = [theEvent modifierFlags];

    if (!(flags & NSControlKeyMask) || keycode != 48) {
        return;
    }

    if (flags & NSShiftKeyMask) {
        [tabView tabBackward];
    }
    else {
        [tabView tabForward];
    }
}

- (void) closedTabNamed:(NSString *) channel forBroker:(GLGIRCBroker *) broker {
    [tabView removeTabNamed:channel fromOwner:broker];
    [broker partChannel:channel userInitiated:YES];

    NSString *key = [broker.hostname stringByAppendingString:channel];
    [chatlogs removeObjectForKey:key];
}

#pragma mark - IBActions
- (void) closeActiveTabOrWindow {
    if ([tabView count] == 1) {
        [[self window] close];
    }
    else {
        NSString *channel = currentChannel;
        [self closedTabNamed:channel forBroker:currentBroker];
    }
}

- (IBAction) copy:(id) sender {
    GLGChatLogView *chat = [self currentChatlogTextView];
    NSArray *selectedRanges = [chat selectedRanges];
    if ([selectedRanges count] == 0) {
        return;
    }

    NSMutableArray *selections = [[NSMutableArray alloc] init];
    [selectedRanges enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        NSRange range = [obj rangeValue];
        NSString *selection = [[chat string] substringWithRange:range];
        [selections addObject:selection];
    }];

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    
    if (![pasteboard writeObjects:selections]) {
        NSLog(@"error: could not copy to pasteboard");
    }
}


#pragma mark - Occupant Delegate methods
- (void) clickedOnNick:(NSString *) nick {
    NSString *key = [currentBroker.hostname stringByAppendingString:nick];
    GLGChatLogView *theChatLog = [chatlogs objectForKey:key];
    if (theChatLog == nil) {
        theChatLog = [self newChatlog];

        NSString *key = [currentBroker.hostname stringByAppendingString:nick];
        [chatlogs setValue:theChatLog forKey:key];
        [tabView addItem:nick selected:YES forOwner:currentBroker];
    }

    currentChannel = nick;
    [scrollview setDocumentView:theChatLog];
    [tabView setSelectedChannelNamed:nick];

    NSArray *occupants = [currentBroker occupantsInChannel:currentChannel];
    [self updateOccupants:occupants forChannel:currentChannel];
}

#pragma mark - Occupant colorizing
- (NSArray *) colorsForOccupants:(NSArray *) occupants {
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    [occupants enumerateObjectsUsingBlock:^(NSString * occupant, NSUInteger idx, BOOL *stop) {
        CGFloat hue = fmodf((0.618033988749895f * idx), 1);
        CGFloat saturation = 0.8;
        CGFloat brightness = 0.75;
        NSColor *color = [NSColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0];
        [colors addObject:color];
    }];

    return colors;
}

@end
