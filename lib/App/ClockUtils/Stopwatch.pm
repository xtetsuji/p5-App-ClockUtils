package App::ClockUtils::Stopwatch;

use strict;
use warnings;
use utf8;
use AnyEvent;
use App::ClockUtils;

our $VERSION = $App::ClockUtils::VERSION;

sub new {
    my $class = shift;
    my $opts  = shift || {};
    my $self  = bless { opts => $opts }, $class;

}

sub run {
    my $self = shift;
    return $self->{condvar}->recv();
}

1;

__END__

=pod

=head1 NAME

App::ClockUtils::Stopwatch - Stopwatch engine for ClockUtils.

=head1 SYNOPSIS

(stub)

=head1 DESCRIPTION

(stub)

=cut
