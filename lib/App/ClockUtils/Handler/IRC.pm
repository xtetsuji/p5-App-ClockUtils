package App::ClockUtils::Handler::IRC;
# This module is used by stopwatch.pl

use strict;
use warnings;
use AnyEvent;
use AnyEvent::IRC::Client;
use App::ClockUtils;

use constant DEFAULT_RECONNECT_INTERVAL => 30;

our $VERSION = $App::ClockUtils::VERSION;

sub new {
    my $class = shift;
    my %opts  = @_;

    my $self  = bless { opts => \%opts }, $class;

    $self->{irc_charset} = delete $self->{opts}->{irc_charset} || 'utf-8';
    $self->_build_irc_client();
    $self->_build_reconnect_timer();

    $self->connect(); # 実際にconnectが発行されるのはcondvarがrecvするとき
}

sub _build_irc_client {
    my $self = shift;
    my $IRC_CHARSET = $self->{irc_charset};
    $self->{irc_client} = AnyEvnet::IRC::Client->new();
    $self->{irc_client}->reg_cb(
        connect => sub {
            my ($irc, $error) = @_;
            $self->join_channel($self->{opts}->{join_channel})
                if $self->{opts}->{join_channel};
        },
        publicmsg => sub {
            my ($irc, $channel, $msg) = @_;
            # e.g. $msg = { params => [$channel, $mode], command => 'PRIVMSG', prefix => 'ogata|ogata@irc.server.example.jp' }
            my $comment = decode($IRC_CHARSET, $msg->{params}->[1]);
            my ($nick)  = $msg->{prefix} =~ /^(.+?)/;

            # これはどこから持ってくるか？
            $self->{publicmsg_cb}->(
                irc     => $irc,
                channel => $channel,
                comment => $comment,
                nick    => $nick,
            ) if $self->{publicmsg_cb};
        },
    );
}

sub _build_reconnect_timer {
    my $self = shift;
    my $RECONNECT_INTERVAL = $self->{opts}->{irc_reconnect_interval} || DEFAULT_RECONNECT_INTERVAL;
    $self->{reconnect_timer} = AE::timer 0, $RECONNECT_INTERVAL, sub {
        $self->connect() if !$self->{irc_client}->registered();
    };
}

sub connect {
    my $self = shift;
    my ($server, $port) = ($self->{opts}->{server}, $self->{opts}->{port} || 6667);
    my $opt = {};
    for (qw(password nick real)) {
        $opt->{$_} = $self->{opts}->{$_} if $self->{opts}->{$_};
    }
    $self->{irc_client}->connect($server, $port, $opt);
}

sub join_channnel {
    my $self = shift;
    my $channel = shift;
    return $self->{irc_client}->send_srv( JOIN => $channel );
}

sub speak_channel {
    my $self = shift;
    my $phrase = shift;
    my $channel = shift;
    my $IRC_CHARSET = $self->{irc_charset};
    $self->{irc_client}->send_chan(
        $channel => PRIVMSG => $channel => encoding($IRC_CHARSET, $phrase)
    );
}

1;

__END__

=pod

=head1 NAME

App::ClockUtils::Handler::IRC - IRC Handler for ClockUtils.

=head1 SYNOPSIS

 use AnyEvent;
 use App::ClockUtils::Handler::IRC;
 my $cv = AnyEvnet->condvar;
 my $irc = App::ClockUtils::Handler::IRC->new(
    ### required parameters
    server => 'YOUR_IRC_SERVER',
    port   => 'YOUR_IRC_PORT, # default is 6667

    ### optional parameters
    password     => 'YOUR_IRC_PASSWORD',
    nick         => 'YOUR_NICK_NAME',
    real         => 'YOUR_REAL_NAME',
    join_channel => 'INITIAL_JOIN_CHANNEL_NAME', # e.g. '#mychannel'
    irc_charset  => 'YOUR_IRC_CHARSET', # default is 'utf-8'
    irc_reconnect_interval => 15, # default is 30 (seconds)
    allow_invite => BOOL, # default is true.
 );
 # ...some AnyEvent's event define...
 $cv->recv();

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
