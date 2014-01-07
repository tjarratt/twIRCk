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

@interface GLGChatView ()
@property (readwrite) NSWindow *superWindow;
@property (retain, readwrite) GLGTabView *tabView;
@property (retain, readwrite) GLGChannelSidebar *sidebar;
@property (retain, readwrite) NSScrollView *scrollview;
@property (retain, readwrite) GLGChatTextField *input;
@property (retain, readwrite) GLGChatLogView *chatlogView;
@property (readwrite) id<GLGChatViewDelegate> controller;
@end

@implementation GLGChatView

- (instancetype) initWithWindow:(NSWindow *) aWindow andDelegate:(id) delegate {
    NSView *content = [aWindow contentView];
    NSRect frame = [content frame];

    if (self = [super initWithFrame:frame]) {
        self.controller = delegate;
        [self setSuperWindow:aWindow];
        [aWindow setMinSize:NSMakeSize(300, 200)];

        GLGChatTextField *input = [[GLGChatTextField alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, inputHeight)];
        [input setTarget:self];
        [input setAction:@selector(didSubmitText)];
        [input setNextKeyView:self];
        [self addSubview:input];
        [self setInput:input];

        GLGTabView *tabView = [[GLGTabView alloc] initWithFrame:NSMakeRect(0, frame.size.height - tabHeight, frame.size.width, tabHeight)];
        [tabView setNextKeyView:input];
        [self addSubview:tabView];
        [self setTabView:tabView];

        NSRect chatRect = NSMakeRect(0, inputHeight, frame.size.width - occupantsSidebarWidth, frame.size.height - tabHeight - inputHeight);
        NSScrollView *scrollview = [[NSScrollView alloc] initWithFrame:chatRect];
        [scrollview setBorderType:NSNoBorder];
        [scrollview setHasVerticalScroller:YES];
        [scrollview setHasHorizontalScroller:NO];
        [scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollview setScrollsDynamically:YES];
        [scrollview setNextKeyView:input];
        [self addSubview:scrollview];
        [self setScrollview:scrollview];

        GLGChatLogView *chatlogView = [[GLGChatLogView alloc] initWithFrame:chatRect];
        [self setChatlogView:chatlogView];

        NSRect channelRect = NSMakeRect(frame.size.width - occupantsSidebarWidth, inputHeight, occupantsSidebarWidth, frame.size.height - tabHeight - inputHeight);
        GLGChannelSidebar *sidebar = [[GLGChannelSidebar alloc] initWithFrame:channelRect];
        [self addSubview:sidebar];
        [self setSidebar:sidebar];

        [aWindow makeFirstResponder:input];
        [aWindow makeKeyAndOrderFront:nil];
        [aWindow setDelegate:self];
    }

    return self;
}

#pragma mark - NSWindow delegate methods
- (void) windowDidResize:(NSNotification *) notification {
    NSWindow *theWindow = [notification object];
    NSRect frame = [[theWindow contentView] frame];
    [self setFrame:frame];

    NSRect tabFrame = NSMakeRect(0, frame.size.height - tabHeight, frame.size.width, tabHeight);
    [self.tabView setFrame:tabFrame];

    NSRect scrollFrame = NSMakeRect(0, inputHeight, frame.size.width - occupantsSidebarWidth, frame.size.height - tabHeight - inputHeight);
    [self.scrollview setFrame:scrollFrame];

    NSRect sidebarFrame = NSMakeRect(frame.size.width - occupantsSidebarWidth, inputHeight, occupantsSidebarWidth, frame.size.height - tabHeight - inputHeight);
    [self.sidebar setFrame:sidebarFrame];

    NSRect inputFrame = NSMakeRect(0, 0, frame.size.width, inputHeight);
    [self.input setFrame:inputFrame];

    [self.chatlogView setFrame:scrollFrame];
}

#pragma mark - handling chat logs
- (GLGChatLogView *) newChatlog {
    NSSize contentSize = [self.scrollview contentSize];
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
    [textview setNextKeyView:self.input];

    return textview;
}

#pragma mark - notifications
- (void) didConnectToHost:(NSString *) host {
    [self.connectView shouldClose];
    self.connectView = nil;
}

# pragma mark - IBActions
- (void) didSubmitText {
    NSString *string = [self.input stringValue];
    if ([string isEqualToString:@""]) { return; }

    [self.controller didSubmitText:string];
    [self.input clearTextField];
}

#pragma mark - NSResponder methods
- (void) keyUp:(NSEvent *) theEvent {
    unsigned short keycode = [theEvent keyCode];
    NSUInteger flags = [theEvent modifierFlags];

    if (!(flags & NSControlKeyMask) || keycode != 48) {
        return;
    }

    if (flags & NSShiftKeyMask) {
        [self.tabView tabBackward];
    }
    else {
        [self.tabView tabForward];
    }
}

#pragma mark - IBActions
- (void) closeActiveTabOrWindow {
    if ([self.tabView count] == 1) {
        [self.window close];
    }
    else {
        [self.controller closeCurrentChannel];
    }
}

- (IBAction) copy:(id) sender {
    NSArray *selectedRanges = [self.chatlogView selectedRanges];
    if ([selectedRanges count] == 0) {
        return;
    }

    NSMutableArray *selections = [[NSMutableArray alloc] init];
    [selectedRanges enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        NSRange range = [obj rangeValue];
        NSString *selection = [self.chatlogView.string substringWithRange:range];
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
    [self.controller didClickOnNick:nick];
}

@end
