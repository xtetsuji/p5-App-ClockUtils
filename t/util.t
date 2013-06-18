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

done_testing();
