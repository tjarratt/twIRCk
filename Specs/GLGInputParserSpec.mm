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
        [parser setDelegate:delegate];
    });

    describe(@"parsing command messages", ^{
        describe(@"joining channels", ^{
            it(@"should parse /join messages without an octothorpe", ^{
                [parser parseUserInput:@"/join cheese_lovers"];

                delegate should have_received(@selector(didJoinChannel:rawCommand:));

//                    [msg type] should equal(@"join");
//                    [msg raw] should equal(@"JOIN #cheese_lovers");
//                    [msg message] should equal(@"/join #cheese_lovers");
//                    [msg payload] should equal(@"#cheese_lovers");
            });

            it(@"should parse /join messages with an octothorpe", ^{
                [parser parseUserInput:@"/join #cheese_haters"];

                delegate should have_received(@selector(didJoinChannel:rawCommand:));

//                    [msg type] should equal(@"join");
//                    [msg raw] should equal(@"JOIN #cheese_haters");
//                    [msg message] should equal(@"/join #cheese_haters");
//                    [msg payload] should equal(@"#cheese_haters");
            });
        });

        describe(@"parsing /part messages", ^{
            it(@"should parse /part messages", ^{
                [parser parseUserInput:@"/part losers"];

                delegate should have_received(@selector(didPartChannel:rawCommand:));

//                    [msg type] should equal(@"part");
//                    [msg raw] should equal(@"PART #losers http://twIRCk.com (sometimes you just gotta twIRCk it!)");
//                    [msg message] should equal(@"/part #losers http://twIRCk.com (sometimes you just gotta twIRCk it!)");
//                    [msg payload] should equal(@"#losers");
            });

            it(@"should respect custom /part messages", ^{
                [parser parseUserInput:@"/part haskell Tis a silly place, let us not go there"];

                parser should have_received(@selector(didPartChannel:rawCommand:));

//                    [msg type] should equal(@"part");
//                    [msg raw] should equal(@"PART #haskell Tis a silly place, let us not go there");
//                    [msg message] should equal(@"/part #haskell Tis a silly place, let us not go there");
//                    [msg payload] should equal(@"#haskell");
            });

            it(@"should use the current channel if none is specified", ^{
                [parser parseUserInput:@"/part"];

                delegate should have_received(@selector(didPartChannel:rawCommand:));

//                    [msg type] should equal(@"part");
//                    [msg raw] should equal(@"PART <__channel__> http://twIRCk.com (sometimes you just gotta twIRCk it!)");
//                    [msg message] should equal(@"/part <__channel__> http://twIRCk.com (sometimes you just gotta twIRCk it!)");
//                    [msg payload] should equal(@"<__channel__>");
            });
        });

        describe(@"parsing /msg private messages", ^{
            it(@"should parse private messages as /msg", ^{
                [parser parseUserInput:@"/msg god hey man I got some good ideas for the new NEW testament"];

//                delegate should have_received(@selector()

//                [msg type] should equal(@"msg");
//                [msg raw] should equal(@"PRIVMSG god :hey man I got some good ideas for the new NEW testament");
//                [msg message] should equal(@"<<__nick__>> hey man I got some good ideas for the new NEW testament");
//                [msg payload] should equal(@"god");
            });

            it(@"should parse private messages with /whisper", ^{
                [parser parseUserInput:@"/whisper devil WTS soul. LF primordial saronite"];

//                [msg type] should equal(@"msg");
//                [msg raw] should equal(@"PRIVMSG devil :WTS soul. LF primordial saronite");
//                [msg message] should equal(@"<<__nick__>> WTS soul. LF primordial saronite");
//                [msg payload] should equal(@"devil");
            });
        });

        it(@"should parse /who messages", ^{
            [parser parseUserInput:@"/who batman"];

//            [msg type] should equal(@"who");
//            [msg raw] should equal(@"WHO batman");
//            [msg message] should equal(@"/who batman");
        });

        // TODO needs to be able to support binary in strings
        xit(@"should parse /me messages", ^{
            [parser parseUserInput:@"/me twircks it!"];

//            [msg type] should equal(@"me");
//            [msg raw] should equal(@"PRIVMSG <__channel__> \u0001ACTION twirkcs it!\u0001");
//            [msg message] should equal(@"<__nick__> twicks it!");
        });

        it(@"should parse /nick messages", ^{
            [parser parseUserInput:@"/nick bruceWayne"];

//            [msg type] should equal(@"nick");
//            [msg raw] should equal(@"NICK bruceWayne");
//            [msg message] should equal(@"/nick bruceWayne");
//            [msg payload] should equal(@"bruceWayne");
        });

        it(@"should parse /pass messages", ^{
            [parser parseUserInput:@"/pass ILoveMyDeadGaySon"];

//            [msg type] should equal(@"pass");
//            [msg raw] should equal(@"PASS ILoveMyDeadGaySon");
//            [msg message] should equal(@"/pass ILoveMyDeadGaySon");
//            [msg payload] should equal(@"ILoveMyDeadGaySon");
        });

        it(@"should parse /topic messages", ^{
            [parser parseUserInput:@"/topic a new version of twIRCk.app is available! Please update now and report any bugs"];

//            [msg type] should equal(@"topic");
//            [msg raw] should equal(@"TOPIC <__channel__> a new version of twIRCk.app is available! Please update now and report any bugs");
//            [msg message] should equal(@"/topic a new version of twIRCk.app is available! Please update now and report any bugs");
        });

        it(@"should treat other /cmd messages as having no target", ^{
            [parser parseUserInput:@"/foo bar baz buz"];

//            [msg type] should equal(@"foo");
//            [msg raw] should equal(@"FOO bar baz buz");
//            [msg message] should equal(@"/foo bar baz buz");
        });
    });

    it(@"should treat all other messages as a message in the current channel", ^{
        [parser parseUserInput:@"Good morning Vietnam!"];
        
//        [msg type] should equal(@"msg");
//        [msg raw] should equal(@"PRIVMSG <__channel__> :Good morning Vietnam!");
//        [msg message] should equal(@"<<__nick__>> Good morning Vietnam!");
    });
});

SPEC_END
