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

(stub)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
