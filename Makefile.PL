# -*- perl -*-

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'App::ClockUtils',
    VERSION_FROM   => 'lib/App/ClockUtils.pm',
    ABSTRACT_FROM  => 'lib/App/ClockUtils.pm',
    AUTHOR         => 'OGATA Tetsuji <tetsuji.ogata at cpan.org>',
    PREREQ_PM      => {
        'AnyEvent'              => 0,
        'AnyEvent::IRC::Client' => 0,
        'Carp'                  => 0,
        'Date::Format'          => 0,
        'Date::Parse'           => 0,
        'Encode'                => 0,
        'Exporter'              => 0,
        'Growl::Any'            => 0,
    },
    PMLIBDIRS      => ["lib"],
    META_MERGE     => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/xtetsuji/p5-App-ClockUtils/issues',
            repository => 'git://github.com/xtetsuji/p5-App-ClockUtils.git',
        },
    },
    LICENSE        => "perl",
    PL_FILES       => {},
    EXE_FILES      => ["bin/stopwatch.pl", "bin/notify.pl"],
    dist           => {
        SUFFIX => 'gz',
        COMPRESS => 'gzip -9f',
    },
);

