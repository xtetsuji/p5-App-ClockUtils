use strict;
use warnings;
use lib 'lib';
use Test::More;

use_ok $_ for qw(
  App::ClockUtils
  App::ClockUtils::Handler::Growl
  App::ClockUtils::Handler::IRC
  App::ClockUtils::Handler::Sound
  App::ClockUtils::Handler::Terminal
  App::ClockUtils::Handler::Voice
  App::ClockUtils::Notify
  App::ClockUtils::Stopwatch
  App::ClockUtils::Util
);

done_testing;
