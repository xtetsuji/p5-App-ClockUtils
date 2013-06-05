package App::ClockUtils::Notify;

use strict;
use warnings;
use utf8;
use AnyEvent;
use App::ClockUtils;
use App::ClockUtils::Handler::Growl;
use App::ClockUtils::Handler::IRC;
use App::ClockUtils::Handler::Terminal;
use App::ClockUtils::Handler::Voice;
use App::ClockUtils::Util qw(guess_terminal_encoding str2sec);
use Carp qw(croak);
use Date::Format qw(time2str);
use Date::Parse  qw(str2time);
use Encode;

our $VERSION = $App::ClockUtils::VERSION;

our $DEFAULT_MESSAGE = 'time is up';

sub new {
    my $class = shift;
    my $opt   = shift || {};
    my @argv  = @_;
    my $self  = bless {}, $class;
    my $terminal_encoding = guess_terminal_encoding();
    $self->{time_string}     = $argv[0];
    $self->{message}         = decode($terminal_encoding, $argv[1] || $DEFAULT_MESSAGE);
    # almost option's default is off.
    $self->{terminal}        = delete $opt->{terminal};
    $self->{growl}           = delete $opt->{growl};
    $self->{voice}           = delete $opt->{voice};
    $self->{growl_sticky}    = delete $opt->{'growl-sticky'};
    $self->{no_terminal}     = delete $opt->{'no-terminal'};
    $self->{no_growl}        = delete $opt->{'no-growl'};
    $self->{no_growl_sticky} = delete $opt->{'no-growl-sticky'};
    $self->{irc_schema}      = delete $opt->{'irc-schema'};
    # be must decode()?
    $self->{title}           = decode($terminal_encoding, delete $opt->{title} || $class);
    $self->{countdown}       = decode($terminal_encoding, delete $opt->{countdown} || '');
    $self->{callback}        = delete $opt->{callback};
    return $self;
}

sub run {
    my $self = shift;

    my ($seconds) = str2sec($self->{time_string});

    if ( $seconds < 0 ) {
        croak 'past time is not specified.';
    }

    if ( $seconds == 0 ) {
        $self->notify();
        return;
    }

    $self->{condvar}  = AnyEvent->condvar;
    if ( my $countdown = $self->{countdown} ) {
        $self->setup_countdown($seconds);
    }
    $self->setup_signal($seconds);
    # setup_main_timer:
    $self->{ae_timer} = AnyEvent->timer(
        after => $seconds,
        cb    => sub {
            $self->notify();
            $self->{condvar}->send();
        },
    );
    return $self->{condvar}->recv();
}

sub setup_countdown {
    my $self = shift;
    my $seconds = shift;
    my $first_time = time();
    my $last_time = $first_time + $seconds;
    my $countdown_first_after = $first_time % 60 == 0 ? 0 : 60 - $first_time % 60;
    # 時間を直接指定している場合はこれでいいが
    # after/before 構文の場合は起動時間自体を起点にすべき
    # (e.g. tea-countdown)
    $countdown_first_after = 0 if $self->{time_string} =~ /\b(?:before|after):/;
    my $countdown_msg = $self->{countdown} !~ /\%d/ ? 'after %d minutes' : $self->{countdown}; # format for sprintf.
    $countdown_msg =~ s/%(?!d)/%%/g; # TODO: もう少し厳密に置換すべき？
    #warn qq(countdwon_msg is "$countdown_msg"\n) if $DEBUG;
    $self->{ae_countdown} = AnyEvent->timer(
        after    => $countdown_first_after,
        interval => 60,
        cb       => sub {
            my $rest_min = int( ($last_time - time()) / 60 ) + 1;
            # before/afterの場合は after:3min を指定したとたんに
            # 「あと4分」が宣告されたりするので -1 しておく
            $rest_min-- if $self->{time_string} =~ /\b(?:before|after)/;
            if ( $rest_min <= 0 ) {
                # TODO: 循環参照がないかチェック
                $self->{ae_countdown} = undef;
                delete $self->{ae_countdown};
                return;
            }
            $self->notify( sprintf $countdown_msg, $rest_min );
        }
    );
}

sub setup_signal {
    my $self = shift;
    my $seconds = shift;
    my $first_time = time();
    my $last_time = $first_time + $seconds;
    $self->{ae_signal_usr1} = AnyEvent->signal(
        signal => 'USR1',
        cb     => sub {
            # time() は USR1 シグナルを発行した時間
            my $seconds2 = int($last_time - time());
            my $message2 = "notify after $seconds2 seconds.";
            if ( $seconds2 >= 600 ) {
                $message2 = "about " . int( $seconds2 / 60 ) . " minutes.";
            }
            print "$message2\n";
        },
    );
}

# $notify->noitfy()
# $notify->notify($message);
sub notify {
    my $self = shift;
    my $message = shift || $self->{message};

    ### terminal
    if ( $self->{terminal} ) {
        my $terminal_encoding = guess_terminal_encoding();
        print encode($terminal_encoding, $message . "\n");
    }

    ### growl
    if ( $self->{growl} ) {
        my $growl = App::ClockUtils::Handler::Growl->new(
            event => 'notify',
            title => 'notify.pl',
        );
        $growl->notify($message);
    }

    ### voice
    if ( $self->{voice} ) {
        my $voice = App::ClockUtils::Handler::Voice->new();
        $voice->speak($message);
    }
}

1;

__END__

=pod

=head1 NAME

App::ClockUtils::Notify - Notify engine for ClockUtils.

=head1 SYNOPSIS

 # see notify.pl
 # %opt is command line options.
 App::ClockUtils::Notify->new(\%opt, @ARGV)->run;

=head1 DESCRIPTION

This module is core engine of "notify.pl".

See "notify.pl" for detail.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
