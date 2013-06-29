#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use App::ClockUtils;
use App::ClockUtils::Stopwatch;
use Getopt::Long ();
use Pod::Usage qw(pod2usage);

use constant DEBUG => $ENV{DEBUG};

my $p = Getopt::Long::Parser->new(
    config => [qw(posix_default no_ignore_case auto_help)]
);
$p->getoptions(
    \my %opt =>
    'version',
    'help', 'usage',
    # ping! interval
    'mins=i',

    # ping!
    'progress|p', 'terminal|t', 'growl|g', 'voice|v', 'sound|s',
    'quiet|q',
    'growl-sticky', 'no-append-localtime|A',

    'no-terminal|T', 'no-growl|G', 'no-voice|V', 'no-sound|S',
    'no-growl-sticky',

    # IRC ping!
    'irc-charset=s', 'irc-schema=s',

    # message description
    'message|m=s' # include %d for sprintf
);

if ( $opt{version} ) {
    print "Version is $App::ClockUtils::VERSION.\n";
    exit;
}

if ( $opt{help} || $opt{usage} ) {
    pod2usage(0);
}

if ( @ARGV > 1 ) {
    pod2usage(1);
}

### DEBUG
if ( DEBUG ) {
    use Data::Dumper;
    print "DEBUG: " . Dumper([\%opt, \@ARGV]) . "\n";
}

App::ClockUtils::Stopwatch->new(\%opt, $ARGV[0])->run;

exit;

__END__

=pod

=head1 NAME

notify.pl - Comamnd line utility of alarm and timer.

=head1 SYNOPSIS

 notify.pl --version
 notify.pl --terminal 19:20 "time is up"

=head1 DESCRIPTIONS

This program is call at your specific time.

=head1 OPTIONS

=over

=item --help|--usage

Show help and exit.

=item --mins=NOTIFICATION_INTERVAL_MINUTES

Specify notification interval minutes.

Default value is 1 (minute). So default,
showing notification per minute.

=item --progress|-p

Output progress to terminal per second.

=item --terminal|-t

Output notify to terminal.

=item --growl|-g

Output notify to Growl.

=item --voice|-v

Output notify as voice. This option depneds Mac OS X "say" command currently.

=item --sound|-s

Output notify as sound. This option depends Mac OS X "afplay" command currently.

=item --growl-sticky

Let sticky outputted Growl notify.

This option is need --growl|-g option togetter (currently implement).

*** THIS OPTION IS NOT IMPLEMENTED YET. ***

=item --no-append-localtime|-A

*** THIS OPTION IS NOT IMPLEMENTED YET. ***

=item --no-terminal|-T

Avoid notify terminal.

This option is default behavior on currently implement.
Because this option is ignored on currently.

=item --no-growl|-G

Avoid notify Growl.

This option is default behavior on currently implement.
Because this option is ignored on currently.

=item --no-voice|-V

Avoid notify voice.

This option is default behavior on currently implement.
Because this option is ignored on currently.

=item --no-sound|-S

Avoid notify sound.

This option is default behavior on currently implement.
Because this option is ignored on currently.

=item --no-growl-sticky

Let non-sticky Growl notify.

This option is ignored on currently.

=item --irc-charset=CHARACTER_SET

Specify IRC server's character set.

=item --irc-schema="irc://yourname:yourpass@ircserver:port/#channel

Specify IRC connection schema. See sample for connection.

=item --message="MESSAGE TEXT"

Specify notify message.

This option's default value is $App::ClockUtils::Stopwatch::DEFAULT_MESSAGE.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
