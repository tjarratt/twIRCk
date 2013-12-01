#import "GLGInputParser.h"
#import "GLGFakeInputParserDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(GLGInputParserSpec)

describe(@"User input parsing", ^{
    __block GLGInputParser *parser;
    __block GLGFakeInputParserDelegate *delegate;

    beforeEach(^{
        parser = [[GLGInputParser alloc] init];
        delegate = [[GLGFakeInputParserDelegate alloc] init];
        spy_on(delegate);
        [parser setDelegate:delegate];
    });

    describe(@"parsing command messages", ^{
        describe(@"joining channels", ^{
            it(@"should parse /join messages without an octothorpe", ^{
                [parser parseUserInput:@"/join cheese_lovers"];

                delegate should have_received(@selector(didJoinChannel:rawCommand:displayMessage:))
                .with(@"#cheese_lovers")
                .with(@"JOIN #cheese_lovers")
                .with(@"/join #cheese_lovers");
            });

            it(@"should parse /join messages with an octothorpe", ^{
                [parser parseUserInput:@"/join #cheese_haters"];

                delegate should have_received(@selector(didJoinChannel:rawCommand:displayMessage:))
                .with(@"#cheese_haters")
                .with(@"JOIN #cheese_haters")
                .with(@"/join #cheese_haters");
            });
        });

        describe(@"parsing /part messages", ^{
            it(@"should parse /part messages", ^{
                [parser parseUserInput:@"/part losers"];

                delegate should have_received(@selector(didPartChannel:rawCommand:displayMessage:))
                .with(@"#losers")
                .with(@"PART #losers http://twIRCk.com (sometimes you just gotta twIRCk it!)")
                .with(@"/part #losers http://twIRCk.com (sometimes you just gotta twIRCk it!)");
            });

            it(@"should respect custom /part messages", ^{
                [parser parseUserInput:@"/part haskell Tis a silly place, let us not go there"];

                delegate should have_received(@selector(didPartChannel:rawCommand:displayMessage:))
                .with(@"#haskell")
                .with(@"PART #haskell Tis a silly place, let us not go there")
                .with(@"/part #haskell Tis a silly place, let us not go there");
            });

            it(@"should use the current channel if none is specified", ^{
                [parser parseUserInput:@"/part"];

                delegate should have_received(@selector(didPartCurrentChannelWithRawCommand:displayMessage:))
                .with(@"PART <__channel__> http://twIRCk.com (sometimes you just gotta twIRCk it!)")
                .with(@"/part <__channel__> http://twIRCk.com (sometimes you just gotta twIRCk it!)");
            });
        });

        describe(@"parsing /msg private messages", ^{
            it(@"should parse private messages as /msg", ^{
                [parser parseUserInput:@"/msg god hey man I got some good ideas for the new NEW testament"];

                delegate should have_received(@selector(didSendMessageToTarget:rawCommand:displayMessage:))
                .with(@"god")
                .with(@"PRIVMSG god :hey man I got some good ideas for the new NEW testament")
                .with(@"<<__nick__>> hey man I got some good ideas for the new NEW testament");
            });

            it(@"should parse private messages with /whisper", ^{
                [parser parseUserInput:@"/whisper devil WTS soul. LF primordial saronite"];

                delegate should have_received(@selector(didSendMessageToTarget:rawCommand:displayMessage:))
                .with(@"devil")
                .with(@"PRIVMSG devil :WTS soul. LF primordial saronite")
                .with(@"<<__nick__>> WTS soul. LF primordial saronite");
            });
        });

        it(@"should warn you when /who is lacking a target", ^{
            [parser parseUserInput:@"/who "];

            delegate should have_received(@selector(didSendMessageToCurrentTargetWithRawCommand:displayMessage:))
            .with(@"")
            .with(@"/who\nWHO: not enough parameters (usage: /who {channel})");
        });

        it(@"should parse /who messages", ^{
            [parser parseUserInput:@"/who batman"];

            delegate should have_received(@selector(didSendMessageToCurrentTargetWithRawCommand:displayMessage:))
            .with(@"WHO batman")
            .with(@"/who batman");
        });

        // TODO: needs to be able to support binary in strings
        xit(@"should parse /me messages", ^{
            [parser parseUserInput:@"/me twircks it!"];
            fail(@"not implemented yet");

            delegate should have_received(@selector(didSendMessageToCurrentTargetWithRawCommand:displayMessage:))
            .with(@"PRIVMSG <__channel__> \u0001 ACTION twircks it!\u0001")
            .with(@"");
        });

        it(@"should parse /nick messages", ^{
            [parser parseUserInput:@"/nick bruceWayne"];

            delegate should have_received(@selector(didChangeNick:rawCommand:displayMessage:))
            .with(@"bruceWayne")
            .with(@"NICK bruceWayne")
            .with(@"/nick bruceWayne");
        });

        it(@"should parse /pass messages", ^{
            [parser parseUserInput:@"/pass ILoveMyDeadGaySon"];

            delegate should have_received(@selector(didChangePassword:rawCommand:displayMessage:))
            .with(@"ILoveMyDeadGaySon")
            .with(@"PASS ILoveMyDeadGaySon")
            .with(@"/pass ********");
        });

        it(@"should parse /topic messages", ^{
            [parser parseUserInput:@"/topic a new version of twIRCk.app is available! Please update now and report any bugs"];

            delegate should have_received(@selector(didSendMessageToCurrentTargetWithRawCommand:displayMessage:))
            .with(@"TOPIC <__channel__> a new version of twIRCk.app is available! Please update now and report any bugs")
            .with(@"/topic a new version of twIRCk.app is available! Please update now and report any bugs");
        });

        it(@"should treat other /cmd messages as having no target", ^{
            [parser parseUserInput:@"/foo bar baz buz"];

            delegate should have_received(@selector(didSendUnknownMessageToCurrentTargetWithRawCommand:displayMessage:))
            .with(@"FOO bar baz buz")
            .with(@"/foo bar baz buz");
        });
    });

    it(@"should treat all other messages as a message in the current channel", ^{
        [parser parseUserInput:@"Good morning Vietnam!"];

        delegate should have_received(@selector(didSendMessageToCurrentTargetWithRawCommand:displayMessage:))
        .with(@"PRIVMSG <__channel__> :Good morning Vietnam!")
        .with(@"<<__nick__>> Good morning Vietnam!");
    });
});

SPEC_END
