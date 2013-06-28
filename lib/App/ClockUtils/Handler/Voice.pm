package App::ClockUtils::Handler::Voice;
### In this version, only supported on "Mac OS X"!
### Please give me good idea of how to support Windows, Linux and some OSes.

use strict;
use warnings;
use utf8;
use App::ClockUtils;
use App::ClockUtils::Util qw/is_multibytes/;

our $VERSION = $App::Clockutils::VERSION;

our $VOICE_JA = 'kyoko';
our $VOICE_EN = 'vicki';

sub new {
    my $class = shift;
    my %opt   = @_;
    return bless \%opt, $class;
}

sub speak {
    my $self = shift;
    return if $^O ne 'darwin';
    my $phrase = shift;
    my $speaker = $self->speaker($phrase);
    return 0 == system 'say', '-v', $speaker, Encode::encode('utf-8', $phrase);
}

sub speaker {
    my $self = shift;
    my $phrase = shift;
    if ( is_multibytes($phrase) ) {
        return $self->{voice_ja} || $VOICE_JA;
    }
    else {
        return $self->{voice_en} || $VOICE_EN;
    }
}

1;

=pod

=head1 NAME

App::ClockUtils::Handler::Voice - Voice handler for ClockUtils.

=head1 SYNOPSIS

 my $speaker = App::ClockUtils::Handler::Voice->new();
 $spekaer->speak("Hello!");
 
 print "Engish speaker is $App::ClockUtils::Handler::Voice::VOICE_EN\n";
 print "Japanese speaker is $App::ClockUtils::Handler::Voice::VOICE_JA\n";

=head1 LIMITATION

B<This version is "Mac OS X" (Darwin) only>.

In this module requires "say" Mac command and
speaker "vicki" (for English) and "kyoko" (for Japanese).
Currently, this configuration is overriden by assingn those global
variables to value.

In this version, support English and Japanese only,
or Mac OS X "say" command only.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
