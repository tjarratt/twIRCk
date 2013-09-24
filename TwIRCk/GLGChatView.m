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
        [self addSubview:input];

        tabView = [[GLGTabView alloc] initWithFrame:NSMakeRect(0, frame.size.height - tabHeight, frame.size.width, tabHeight)];
        [tabView setNextKeyView:input];
        [self addSubview:tabView];

        NSRect chatRect = NSMakeRect(0, inputHeight, frame.size.width - 150, frame.size.height - 80);
        scrollview = [[NSScrollView alloc] initWithFrame:chatRect];
        [scrollview setBorderType:NSNoBorder];
        [scrollview setHasVerticalScroller:YES];
        [scrollview setHasHorizontalScroller:NO];
        [scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollview setScrollsDynamically:YES];
        [scrollview setNextKeyView:input];
        [self addSubview:scrollview];

        NSRect channelRect = NSMakeRect(frame.size.width - 150, inputHeight, 150, frame.size.height - 80);
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

    NSRect scrollFrame = NSMakeRect(0, inputHeight, frame.size.width - 150, frame.size.height - 80);
    [scrollview setFrame:scrollFrame];

    NSRect sidebarFrame = NSMakeRect(frame.size.width - 150, inputHeight, 150, frame.size.height - 80);
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
    [textview setSelectable:YES];
    [textview setRichText:YES];
    [textview setNextKeyView:input];

    return textview;
}

- (GLGChatLogView *) currentChatlogTextView {
    return [chatlogs objectForKey:currentChannel];
}


#pragma mark - NSNotificationCenter actions
- (void) close:(NSNotification *) notification {
    [[self window] close];
}

- (void) handleTabSelection:(NSNotification *) notification {
    NSString *newChannel = [notification object];
    GLGChatLogView *chat = [chatlogs objectForKey:newChannel];

    assert( chat != nil );

    currentChannel = newChannel;
    [scrollview setDocumentView:chat];
    NSPoint newOrigin = NSMakePoint(0, NSMaxY([[scrollview documentView] frame]) -
                                    [[scrollview contentView] bounds].size.height);
    [[scrollview documentView] scrollPoint:newOrigin];

    NSArray *occupants = [[self activeBroker] occupantsInChannel:currentChannel];
    [self updateOccupants:occupants forChannel:currentChannel];
}

#pragma mark - connection methods
- (void) connectToServer:(IRCServer *) server {
    GLGIRCBroker *broker = [[GLGIRCBroker alloc] initWithDelegate:self];
    [broker connectToServer:server];
    [brokers addObject:broker];
}

#pragma mark - notifications
- (void) didConnectToHost:(NSString *) host {
    [connectView shouldClose];
}

- (GLGIRCBroker *) activeBroker {
    return [brokers objectAtIndex:0];
}

- (void) didSubmitText {
    NSString *string = [input stringValue];
    if ([string isEqualToString:@""]) { return; }

    assert( currentChannel != nil ); // nb : probably a good idea to let the tabview tell us what the current chan is

    NSString *messageToDisplay = [[self activeBroker] didSubmitText:string inChannel:currentChannel];

    [input clearTextField];
    NSString *activeHost = [[self activeBroker] hostname];
    [self receivedString:[messageToDisplay stringByAppendingString:@"\n"] inChannel:currentChannel fromHost:activeHost];
}

#pragma mark - IRC Broker Delegate methods
- (void) connectedToServer:(NSString *)hostname {
    [self didConnectToHost:hostname];

    [tabView addItem:hostname forOwner:hostname];
    GLGChatLogView *newLog = [self newChatlog];
    [chatlogs setValue:newLog forKey:hostname];

    if ([tabView count] == 1) {
        currentChannel = hostname;
        [scrollview setDocumentView:newLog];
    }
}

- (void) joinChannel:(NSString *)channel onServer:(NSString *)hostname userInitiated:(BOOL)initiatedByUser {
    // check if we need to create a new one
    GLGChatLogView *theChatLog = [chatlogs objectForKey:channel];
    if (theChatLog == nil) {
        theChatLog = [self newChatlog];
        [chatlogs setValue:theChatLog forKey:channel];
        [tabView addItem:channel selected:initiatedByUser forOwner:hostname];
    }

    if (initiatedByUser) {
        currentChannel = channel;
        [scrollview setDocumentView:theChatLog];
        [tabView setSelectedChannelNamed:channel];

        NSArray *occupants = [[self activeBroker] occupantsInChannel:currentChannel];
        [self updateOccupants:occupants forChannel:currentChannel];
    }
}

- (void) receivedString:(NSString *)string
              inChannel:(NSString *)channel
               fromHost:(NSString *)host
{
    GLGChatLogView *log = [chatlogs objectForKey:channel];
    if (log == nil) {
        [tabView addItem:channel selected:NO forOwner:host];
        log = [self newChatlog];
        [chatlogs setValue:log forKey:channel];
     }

    [log setEditable:YES];
    [log setSelectedRange:NSMakeRange([[log textStorage] length], 0)];
    [log insertText:string];
    [log setEditable:NO];

    NSDictionary *dict = @{@"channel" : channel, @"server" : host};
    NSString *notificationName = [@"message_received_" stringByAppendingString:channel];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:dict];
}

- (void) willPartChannel:(NSString *) channel {
    [tabView removeTabNamed:channel];
}

- (void) didPartChannel:(NSString *) channel {
    [chatlogs removeObjectForKey:channel];
}

-(void) updateOccupants:(NSArray *) occupants forChannel:(NSString *) channel {
    if ([channel isEqualToString:currentChannel]) {
        [sidebar showChannelOccupants:occupants];
    }
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

#pragma mark - IBActions
- (void) closeActiveTabOrWindow {
    if ([tabView count] == 1) {
        [[self window] close];
    }
    else {
        [tabView removeTabNamed:currentChannel];
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

@end
