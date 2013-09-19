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
        NSView *content = [window contentView];
        NSRect frame = [content frame];
        [self setFrame:frame];

        tabView = [[GLGTabView alloc] initWithFrame:NSMakeRect(0, frame.size.height - tabHeight, frame.size.width, tabHeight)];
        [self addSubview:tabView];

        NSRect chatRect = NSMakeRect(0, inputHeight, frame.size.width, frame.size.height - 80);
        scrollview = [[NSScrollView alloc] initWithFrame:chatRect];
        [scrollview setBorderType:NSNoBorder];
        [scrollview setHasVerticalScroller:YES];
        [scrollview setHasHorizontalScroller:NO];
        [scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollview setScrollsDynamically:YES];
        [self addSubview:scrollview];

        input = [[GLGChatTextField alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, inputHeight)];
        [input setTarget:self];
        [input setAction:@selector(didSubmitText)];
        [self addSubview:input];

        [window makeFirstResponder:input];
        [window makeKeyAndOrderFront:nil];
        [window setDelegate:self];

        currentChannel = nil;
        brokers = [[NSMutableArray alloc] init];
        chatlogs = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTabSelection:) name:@"did_switch_tabs" object:nil];
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

    NSRect scrollFrame = NSMakeRect(0, inputHeight, frame.size.width, frame.size.height - 80);
    [scrollview setFrame:scrollFrame];

    NSRect inputFrame = NSMakeRect(0, 0, frame.size.width, inputHeight);
    [input setFrame:inputFrame];

    [chatlogs enumerateKeysAndObjectsUsingBlock:^(id key, GLGChatTextField *obj, BOOL *stop) {
        [obj setFrame:scrollFrame];
    }];
}

#pragma mark - handling chat logs
- (NSTextView *) newChatlog {
    NSSize contentSize = [scrollview contentSize];
    NSTextView *textview = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
    [textview setMinSize:NSMakeSize(0, contentSize.height)];
    [textview setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [textview setVerticallyResizable:YES];
    [textview setHorizontallyResizable:NO];
    [textview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[textview textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
    [[textview textContainer] setWidthTracksTextView:YES];
    [textview setEditable:NO];

    return textview;
}

- (NSTextView *) currentChatlogTextView {
    return [chatlogs objectForKey:currentChannel];
}

#pragma mark - NSNotificationCenter actions
- (void) handleTabSelection:(NSNotification *) notification {
    NSString *newChannel = [notification object];
    NSTextView *chat = [chatlogs objectForKey:newChannel];

    assert( chat != nil );

    currentChannel = newChannel;
    [scrollview setDocumentView:chat];
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

    // need to send this text to the "active" broker
    NSString *messageToDisplay = [[self activeBroker] didSubmitText:string];

    [input clearTextField];
    assert( currentChannel != nil );

    NSString *activeHost = [[self activeBroker] hostname];
    [self receivedString:[messageToDisplay stringByAppendingString:@"\n"] inChannel:currentChannel fromHost:activeHost];
}

#pragma mark - IRC Broker Delegate methods
- (void) connectedToServer:(NSString *)hostname
          withInternalName:(NSString *)internalName
{
    [tabView addItem:hostname];
    NSTextView *newLog = [self newChatlog];
    [chatlogs setValue:newLog forKey:hostname];

    if ([tabView count] == 1) {
        currentChannel = hostname;
        [scrollview setDocumentView:newLog];
    }
}

- (void) joinChannel:(NSString *)channel onServer:(NSString *)hostname {
    [tabView addItem:channel];

    NSTextView *newLog = [self newChatlog];
    [chatlogs setValue:newLog forKey:channel];
    currentChannel = channel;
    [scrollview setDocumentView:newLog];
}

- (void) receivedString:(NSString *)string
              inChannel:(NSString *)channel
               fromHost:(NSString *)host
{
    NSTextView *log = [chatlogs objectForKey:channel];
    if (log == nil) {
        [tabView addItem:channel selected:NO];
        log = [self newChatlog];
        [chatlogs setValue:log forKey:channel];
     }

    [log setEditable:YES];
    [log setSelectedRange:NSMakeRange([[log textStorage] length], 0)];
    [log insertText:string];
    [log setEditable:NO];
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

@end
