#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use App::ClockUtils;
use App::ClockUtils::Notify;
use Getopt::Long ();
use Pod::Usage qw(pod2usage);

my $p = Getopt::Long::Parser->new(
    config => [qw(posix_default no_ignore_case auto_help)]
);
$p->getoptions(
    \my %opt =>
    'version',
    'terminal|t', 'growl|g', 'voice|v', 'growl-sticky|s',
    'no-terminal|T', 'no-growl|G', 'no-voice|V', 'no-growl-sticky|S',
    'irc-schema=s', # This option is new.
    'title=s', 'countdown=s', 'callback=s',
);

if ( $opt{version} ) {
    print "Version is $App::ClockUtils::VERSION.\n";
    exit;
}

if ( $opt{help} || $opt{usage} ) {
    pod2usage(0);
}

if ( @ARGV != 2 ) {
    pod2usage(1);
}

### DEBUG
use Data::Dumper;
print "DEBUG: " . Dumper([\%opt, \@ARGV]) . "\n";

App::ClockUtils::Notify->new(\%opt, @ARGV)->run;

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

=item --terminal|-t

Output notify to terminal.

=item --growl|-g

Output notify to Growl.

=item --voice|-v

Output notify as voice. This option depneds Mac OS X "say" command currently.

=item --growl-sticky|-s

Let sticky outputted Growl notify.

This option is need --growl|-g option togetter (currently implement).

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

=item --no-growl-sticky|-S

Let non-sticky Growl notify.

This option is ignored on currently.

=item --irc-schema="irc://yourname:yourpass@ircserver:port/#channel

***This option is not implemented yet.***

=item --title="TITLE"

Specify notify title.

This option's default value is this program name.

=item countdown="countdown format"

Specify countdown format string.

This string is used by perl "sprintf" function.

You can include "%d" option in this string.

 --countdown="rest %d minutes. hurry up!"

=item --callback="callback shell command"

***This option is not implemented yet.***

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
