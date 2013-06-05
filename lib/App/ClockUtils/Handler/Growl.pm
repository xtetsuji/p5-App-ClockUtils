package App::ClockUtils::Handler::Growl;

use strict;
use warnings;
use utf8;

# Growl prority:
#  Cocoa::Growl
#  Growl::Any
#  growlnotify
use constant HAVE_COCOA_GROWL => eval {
    require Cocoa::Growl;
    # Growl::Any likes Mac::Growl than Cocoa::Growl,
    # But it seems Mac::Growl has bug at some environment.
    $ENV{GROWL_ANY_DEFAULT_BACKEND} = 'CocoaGrowl';
    1;
};
use constant HAVE_GROWL_ANY   => eval {
    require Growl::Any;
    1;
};
use constant HAVE_GROWLNOTIFY => eval {
    0 == system "type growlnotify >/dev/null 2>&1";
};
use App::ClockUtils;
use App::ClockUtils::Util qw(guess_terminal_encoding);
use Carp qw(carp croak);
use Encode;

our $VERSION = $App::ClockUtils::VERSION;

our $GROWL_ENCODING = 'utf-8';

sub new {
    my $class = shift;
    my %opts  = @_;
    my $self  = bless {}, $class;
    $self->{title} = delete $opts{title}
        or croak 'require title parameter.';
    $self->{icon}  = delete $opts{icon};
    print "detect engine\n";
    my $engine = $self->_detect_engine();
    print "engine is $engine.\n";
    return $self;
}

sub _detect_engine {
    my $self = shift;
    if ( HAVE_GROWL_ANY ) {
        $self->{growl_any} = Growl::Any->new(
            appname => ref $self,
            events  => ["notify"],
        );
        return $self->{engine} = "Growl::Any";
    }
    elsif ( HAVE_COCOA_GROWL ) {
        if ( !$self->{cocoa_growl_registered}++ ) {
            Cocoa::Growl::gorlw_register(
                app => ref $self,
                ($self->{icon} ? (icon => $self->{icon}) : ()),
                notifications => ["notify"],
            );
        }
        return $self->{engine} = "Cocoa::Growl";
    }
    elsif ( HAVE_GROWLNOTIFY ) {
        return $self->{engine} = "growlnotify";
    }
    else {
        return;
    }
}

sub engine {
    my $self = shift;
    return $self->{engine};
}

# $growl->notify()
# $growl->notify($message)
sub notify {
    my $self    = shift;
    my $message = shift;
    my $title   = $self->{title};
    my %opt     = @_; # title, [message, event, icon]
    $message  ||= $opt{message};
    if ( !$self->engine ) {
        carp __PACKAGE__ . ": Engine is not found.\n";
    }
    elsif ( $self->engine eq 'Growl::Any' ) {
        my $event = $opt{event} || 'notify';
        my $bytes_message = encode($GROWL_ENCODING => $message);
        my $bytes_title   = encode($GROWL_ENCODING, $title);
        $self->{growl_any}->notify($event, $bytes_title, $bytes_message, $opt{icon});
    }
    elsif ( $self->engine eq 'Cocoa::Growl') {
        my $event = $opt{event} || 'notify';
        Cocoa::Growl::growl_notify(
            name        => $event,
            title       => encode($GROWL_ENCODING, $title),
            description => encode($GROWL_ENCODING, $message),
        );
    }
    elsif ( $self->engine eq 'growlnotify' ) {
        my $bytes_message = encode($GROWL_ENCODING, $message);
        my $bytes_title   = encode($GROWL_ENCODING, $title);
        system 'growlnotify', ($opt{icon} ? ('--image', $opt{icon}) : ()),
            '-a', (ref $self), '-m', $bytes_message, '-t', $bytes_title;
    }
    else {
        die "unknown error.";
    }
}

1;

__END__

=pod

=head1 NAME

App::ClockUtils::Handler::Growl - Growl handler for ClockUtils.

=head1 SYNOPSIS

 my $growl = App::ClockUtils::Handler::Growl->new(
    # event => EVENT_NAME,
    title => TITLE,

    # optional
    message => MESSAGE,
    icon => ICON_PATH,
 );
 $growl->notify();
 # or
 $growl->notify($message);

=cut
