#import "GLGChatViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(GLGChatViewControllerSpec)

describe(@"GLGChatViewController", ^{
    __block NSWindow *window;
    __block GLGChatViewController *controller;

    beforeEach(^{
        window = [[NSWindow alloc] init];
        controller = [[GLGChatViewController alloc] initWithWindow:window];
        spy_on(controller);
    });

    describe(@"observers for tab events", ^{
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

        it(@"should listen for tab switching", ^{
            [nc postNotificationName:@"did_switch_tabs" object:nil];
            controller should have_received(@selector(handleTabSelection:));
        });

        it(@"should listen for tab removal", ^{
            [nc postNotificationName:@"removed_last_tab" object:nil];
            controller should have_received(@selector(tabClosed:));
        });

        it(@"should listen for tab removal from the button", ^{
            [nc postNotificationName:@"chatview_closed_tab" object:nil];
            controller should have_received(@selector(tabCloseButtonClicked:));
        });
    });
});

SPEC_END
