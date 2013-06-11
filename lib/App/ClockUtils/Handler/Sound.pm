package App::ClockUtils::Handler::Sound;
# TODO: Support non-darwin environment.

use strict;
use warnings;
use App::ClockUtils;
use Carp qw(carp);

our $VERSION = $App::ClockUtils::VERSION;
our $DEFAULT_SOUND_FILE = '/System/Library/Sounds/Ping.aiff'; # Darwin only...

sub new {
    my $class = shift;
    my %arg   = @_;
    my $self = bless {}, $class;
    $self->{file} = delete $arg{file} || $DEFAULT_SOUND_FILE;
    return $self;
}

sub play {
    my $self = shift;
    if ( $^O ne 'darwin' ) {
        carp 'currently ' . __PACKAGE__ . ' supports Mac OS X environment only';
        return;
    }

    # TODO: If is the file not *.aiff file?
    return 0 == system 'afplay', $self->{file};
}

1;

=pod

=encoding utf-8

=head1 NAME

App::ClockUtils::Handler::Sound - Sound handler of ClockUtils.

=head1 SYNOPSIS

 my $sound = App::Clockutils::Handler::Sound->new(
    file => '/path/to/ding.aiff', # optional
 );
 $sound->play();

=head1 LIMITATION

This version supports "Mac OS X" darwin environment only.

TODO: To support Windows and Linux.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
