# -*- perl -*-

use strict;
use warnings;
use utf8;
use lib qw(lib);

use Test::More;

use App::ClockUtils::Util;

# export check
ok( defined &is_multibytes, 'is_multibytes is exported');
ok( defined &command_detect, 'command_detect is exported');
ok( defined &guess_terminal_encoding, 'guess_terminal_encoding is exported');
ok( defined &str2sec, 'str2sec is exported');
ok( defined &parse_irc_scheme, 'parse_irc_scheme is exported');

# tests of is_multibytes
ok(!is_multibytes('abc ABC 123'), 'ASCII compatible character is single bytes.');
ok(is_multibytes('☃'), 'SNOWMAN is multibyte UTF-8 character.');
ok(is_multibytes('まるちばいと'), 'Japanese Hiragana is UTF-8 multibyte');
ok(is_multibytes('マルチバイト'), 'Japanese Katakana is UTF-8 multibyte');
ok(is_multibytes('This is 複合バイト文字'), 'Japanese Kanji included it is UTF-8 multibyte');

# tests of guess_terminal_encoding

{
    local $ENV{LANG} = 'C';
    is(guess_terminal_encoding(), "ascii", "LANG=C to ascii.");
}
{
    local $ENV{LANG} = 'en_US.UTF-8';
    is(guess_terminal_encoding(), "utf-8", "LANG=en_US.UTF-8 to utf-8.");
}
{
    local $ENV{LANG} = 'xx_XX.euc-jp';
    is(guess_terminal_encoding(), 'euc-jp', "LANG=xx_XX.euc-jp to euc-jp.");
}
{
    local $ENV{LANG};
    is(guess_terminal_encoding(), "ascii", "Undefined LANG to ascii");
}

# tests of str2sec.
is(str2sec("after:5"),      5, "after:5 means 5min.");
is(str2sec("after:10sec"), 10, "after:10sec means 10sec.");
is(str2sec("after:2min"), 120, "after:2min means 120sec.");
is(str2sec("now"),          0, "now means 0sec.");
is(str2sec("-"),            0, "'-' means 0sec.");
is(str2sec("."),            0, "'.' means 0sec.");
my $tomorrow = str2sec("tomorrow");
ok( $tomorrow > 0 && $tomorrow < 86400, "tomorrow is between 0 and 86400.");

# tests of parse_irc_scheme
is_deeply(
    +{ parse_irc_scheme('irc://user1@server1:1234/#channel1') },
    +{
        nick => 'user1',
        server => 'server1',
        port => '1234',
        channel => '#channel1',
    },
    'parse_irc_scheme has no password.'
);
is_deeply(
    +{ parse_irc_scheme('irc://user2:p4ssw0rd@server2:6667/#channel2') },
    +{
        nick => 'user2',
        server => 'server2',
        port => '6667',
        password => 'p4ssw0rd',
        channel => '#channel2',
    },
    'parse_irc_scheme has password string.'
);
is_deeply(
    +{ parse_irc_scheme('irc://user3@server3/#channel3') },
    +{
        nick => 'user3',
        server => 'server3',
        port => '6667',
        channel => '#channel3',
    },
    'parse_irc_scheme has only required strings.'
);
is_deeply(
    +{ parse_irc_scheme('user4:pass4@server4/#channel4') },
    +{
        nick => 'user4',
        server => 'server4',
        password => 'pass4',
        port => '6667',
        channel => '#channel4',
    },
    'parse_irc_scheme has only required strings without irc schema.'
);

# tests of command_detect
ok(command_detect('perl'), 'perl command is exist.');
ok(!command_detect('__________dummycommand__________'), 'dummy command is not found');

done_testing();
