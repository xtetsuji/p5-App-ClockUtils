package App::ClockUtils::Stopwatch;
# TODO: Extend of English and Jaapnese only support.

use strict;
use warnings;
use utf8;
use AnyEvent;
use App::ClockUtils;
use App::ClockUtils::Handler::Growl;
use App::ClockUtils::Handler::IRC;
use App::ClockUtils::Handler::Sound;
use App::ClockUtils::Handler::Terminal;
use App::ClockUtils::Handler::Voice;
use App::ClockUtils::Util qw(guess_terminal_encoding str2sec parse_irc_scheme);
use Carp qw(croak);
use Date::Parse qw(str2time);
use Encode;

our $VERSION = $App::ClockUtils::VERSION;

our $DEFAULT_TASK_NAME = 'stopwatch';
our $DEFAULT_MESSAGE   = 'stopwatch';
our $DEFAULT_NOTIFY_MINS = 1;
our $SOUND_FILE = '/System/Library/Sounds/Ping.aiff'; # とりあえず決め打ち

my $min_format  = '%2d'; # + 'min' = 5chars
my $init_format = '%5s';

sub new {
    my $class = shift;
    my $opts  = shift || {};
    my @argv  = @_;
    my $self  = bless {}, $class;
    $self->{terminal_encoding} = guess_terminal_encoding();
    $self->{task_name} = $argv[0] || $DEFAULT_TASK_NAME;
    $self->{mins}      = delete $opts->{mins} || $DEFAULT_NOTIFY_MINS;
    $self->{progress}  = delete $opts->{progress};
    $self->{terminal}  = delete $opts->{terminal};
    $self->{growl}     = delete $opts->{growl};
    $self->{voice}     = delete $opts->{voice};
    $self->{sound}     = delete $opts->{sound};
    $self->{quiet}     = delete $opts->{quiet};
    $self->{sticky}    = delete $opts->{sticky};

    $self->{no_append_localtime} = delete $opts->{'no-append-localtime'};

    # irc
    $self->{irc_charset} = delete $opts->{'irc-charset'};
    $self->{irc_scheme}  = delete $opts->{'irc-scheme'} || $ENV{STOPWATCH_IRC_SCHEME};
    # irc_scheme=<username>[:<password>]@<servername>/<channel_name>

    $self->{message}     = delete $opts->{message} || $argv[1];

    return $self;
}

sub run {
    my $self = shift;

    $self->{condvar} = AnyEvent->condvar;

    my $run_time = time();
    $self->{past_sec} = 0; # is prefer key name"past_seconds" ?
    $self->{past_minutes} = 1;
    $| = 1 if $self->{progress};

    if ( !$self->{quiet} ) {
        my $now = localtime;
        print qq(start "$self->{task_name}" at [$now] pid=$$\n);
    }

    if ( $self->{progress} ) {
        my $padnum = $run_time % 60 == 0 ? 0 : $run_time % 60 - 1;
        printf "[%s]$init_format " . ("_" x $padnum),
               $self->{task_name}, "init";
    }

    $self->switch('on');

    if ( $self->{irc_scheme} ) {
        $self->build_irc_client();
        $self->build_publicmsg_cb();
    }

    $self->build_signal_handler();

    return $self->{condvar}->recv();
}

sub irc_client {
    my $self = shift;
    return $self->{irc_client};
}

sub build_irc_client {
    my $self = shift;
    return 1 if $self->irc_client;
    my %irc_data = parse_irc_scheme( $self->{irc_scheme} )
        or return; # parse error
    $self->{irc_client} = App::ClockUtils::Handler::IRC->new(
        server => $irc_data{server},
        port   => $irc_data{port},

        ($irc_data{password} ? (password => $irc_data{password}) : ()),
        nick   => $irc_data{nick},
        real   => ref $self,
        join_channel => $irc_data{channel},
        ($self->{irc_charset} ? (irc_charset => $self->{irc_charset}) : ()),
    ); # Let's AnyEvent->condvar->recv()!
    return 1;
}

sub build_publicmsg_cb {
    my $self = shift;
    my $irc_client = $self->irc_client
        or croak 'irc_client instance is not found.';
    my $cb = sub {
        my $arg = shift;
        if ( ref $arg ne 'HASH' ) {
            croak 'callback is required as HASH reference.';
        }
        my ($irc, $channel, $comment, $nick) = @$arg{qw/irc channel comment nick/};
        my ($command) = $comment =~ /^stopwatch\s+(.*)$/
            or return;
        $command =~ s/\s+$//;
        $command = decode($self->{irc_charset}, $command);
        my $reply = '';
        if ( $command eq 'notify' ) {
            $reply = $self->progress_res();
        }
        if ( $command eq 'detail' ) {
            $reply = $self->progress_res(mode=>'detail');
        }
        if ( $command eq 'off' || $command eq 'suspend' ) {
            $self->switch('off');
            $reply = 'ストップウォッチを一時停止しました';
        }
        if ( $command eq  'on' || $command eq 'resume' ) {
            $reply = 'ストップウォッチを再開させました';
        }
        if ( $command eq 'end' || $command eq '終了' || $command eq '完了' ) {
            $command = 'end'; # 正規化
            $reply = "stopwatchを終了します\n" . $self->progress_res(mode=>'detail');
        }
        if ( $command eq 'status' ) {
            $reply = "stopwatchは現在 $self->{switch_current_status} の状態です";
        }
        if ( $command eq 'taskname' || $command eq 'task_name' ) {
            $reply = $self->{task_name};
        }
        if ( $command eq 'pid' ) {
            $reply = $$;
        }
        $irc_client->speak_channel($reply => $channel);
        if ( $command eq 'end' ) {
            $irc_client->send_srv( PART => $channel, 'bye' );
            $irc_client->disconnect();
            $self->{condvar}->send(1);
        }
    };
    $irc_client->publicmsg_cb($cb);
    return 1;
}

# sub switch_current_status {
#     my $self = shift;
#     if ( @_ == 1 ) {
#         return $self->{switch_current_status} = shift;
#     }
#     else {
#         return $self->{switch_current_status};
#     }
# }

sub switch {
    my $self = shift;
    my $op   = shift;
    if ( $op !~ /^(?:resume|suspend|on|off)$/ ) {
        croak 'switch() expects resume, suspend, on, off at 1st argument.';
    }
    if ( $op eq 'suspend' || $op eq 'off' ) {
        $self->{switch_current_status} = 'off';
        $self->{ae_stopwatch_timer}    = undef;
    }
    elsif ( $op eq 'resume' || $op eq 'on' ) {
        $self->{switch_current_status} = 'on';
        $self->{ae_stopwatch_timer} = AnyEvent->timer(
            after    => 0,
            interval => 1,
            cb       => sub {
                my $now = time();
                $self->{past_sec}++; # TODO: more good to use $run_time?
                if ( $self->{progress} ) {
                    my $period = $now % 60 == 0 ? sprintf "|\n[%s]${min_format}min ", $self->{task_name}, $self->{past_minutes}++
                               : $now % 10 == 0 ? "|"
                               :                  "."
                               ;
                    print $period;
                }
                if (     $self->is_some_notify()
                     && $self->{past_sec} % (60*$self->{mins}) == 0 ) {
                    ###
                    ### Actually it runs notify.
                    ###
                    $self->notify();
                    #warn "progress_res => " . $self->progress->res() . "\n";
                }
            },
        );
    }
}

sub build_signal_handler {
    my $self = shift;
    $self->{prev_sigint_caught_time} = 0;
    for my $sig (qw/usr1 int term/) {
        my $uc_signal_name = uc $sig;
        $self->{"ae_signal_$sig"} = AnyEvent->signal(
            signal => $uc_signal_name,
            cb => sub {
                my $now = time();
                # my $past_sec = $now - $run_time; # $past_sec is package lexical
                my $past_min = int ($self->{past_sec} / 60) + 1;
                my $is_just_min = $self->{past_sec} % 60 == 0;
                my $message = "\n$self->{task_name}\: $self->{past_sec}秒" . (defined $past_min ? "(約${past_min}分@{[ $is_just_min ? '' : '弱' ]})": "") . "経過しました\n";

                # STDOUT
                print encode($self->{terminal_encoding}, $message);

                # IRC
                # チャンネルは invite されたものも入れたほうがいい？
                if ( my $irc_client = $self->irc_client ) {
                    $irc_client->speak_channel->( $message => $self->{join_channel});
                }

                # SIGINT Ctrl-C を同じ秒数の間で2回押された時のみ終了する
                if (    $uc_signal_name eq 'INT'
                     && $self->{prev_sigint_caught_time} == $now ) {
                    $self->{condvar}->send(0);
                }
                if ( $uc_signal_name eq 'INT' ) {
                    $self->{prev_sigint_caught_time} = $now;
                }

                # SIGTERM
                if ( $uc_signal_name eq 'TERM' ) {
                    $self->{condvar}->send(0);
                }
            },
        );
    }
}

sub progress_res {
    my $self = shift;
    my %arg  = @_;
    my $mode = $arg{mode} || 'simple'; # simple or detail
    my $now  = time();

    my $past_min = int($self->{past_sec} / 60);
    my $is_just_min = $self->{past_sec} % 60 == 0;
    my $message = $mode eq 'simple' ? "${past_min}分経過しました" : "$self->{task_name}\: $self->{past_sec}秒" . (defined $past_min ? "(約${past_min}分@{[ $is_just_min ? '' : '弱' ]})": "") . "経過しました\n";
    return $message;
}

# $stopwatch->notify()
# $stopwatch->notify($phrase)
sub notify {
    my $self = shift;
    my $phrase = shift || $self->{message} || $DEFAULT_MESSAGE;
    my $phrase_and_localtime = $phrase . ($self->{no_append_localtime} ? '' : "\n[" . localtime . "]");
    # 時間かからない順

    ### terminal
    if ( $self->{terminal} ) {
        my $terminal_encoding = $self->{terminal_encoding};
        my $output = $self->{task_name} . ": $phrase\n";
        print encode($terminal_encoding, $output);
    }

    ### growl
    if ( $self->{growl} ) {
        my $growl = App::ClockUtils::Handler::Growl->new(
            event => 'notify',
            title => $self->{task_name},
        );
        $growl->notify($phrase);
    }

    ### irc
    if ( my $irc_client = $self->irc_client ) {
        ### TODO ???
        $irc_client->speak_channel( $phrase => $self->{join_channel} );
    }

    ### sound
    if ( $self->{sound} ) {
        # TODO: see Sound.pm.
        my $sound = App::ClockUtils::Handler::Sound->new();
        $sound->play();
    }

# currently voice notification is disabled.
#     ### voice
#     if ( $self->{voice} ) {
#         my $voice = App::ClockUtils::Handler::Voice->new();
#         $voice->speak($message);
#     }

}

sub is_some_notify {
    my $self = shift;
    return grep { $self->{$_} } qw(growl voice sound);
    # TODO: need check no-*** option?
}

1;

__END__

=pod

=head1 NAME

App::ClockUtils::Notify - Notify engine for ClockUtils.

=head1 SYNOPSIS

 # see stopwatch.pl
 # %opt is command line options.
 App::ClockUtils::Stopwatch->new(\%opt, @ARGV)->run;

=head1 DESCRIPTION

This module is core engine of "stopwatch.pl".

See "stopwatch.pl" for detail.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
