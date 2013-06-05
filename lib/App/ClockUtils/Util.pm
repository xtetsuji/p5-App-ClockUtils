package App::ClockUtils::Util;

use strict;
use warnings;
use utf8;
use Carp 'croak';
use Exporter 'import';

our @EXPORT = (qw(is_multibytes command_detect guess_terminal_encoding str2sec));

sub is_multibytes {
    my $str = shift; # internal string
    my @chars = split //, $str;
    return grep { bytes::length($_) >= 2 } @chars;
}

sub command_detect {
    my $command = shift;
    $command =~ /[^a-zA-Z_-]/
        and croak 'illegal command name: ' . $command;
    # for Mac (Darwin) only.
    #my $res = system 'which', '-s', $command;
    my $res = system "type $command >/dev/null 2>&1";
    return 0 == $res;
}

sub guess_terminal_encoding {
    my $lang = $ENV{LANG};
    if (!$lang) {
        return "ascii";
    }
    elsif ( $lang =~ /utf-?8/ ) {
        return "utf-8";
    }
    elsif ( $lang =~ /\./ ) {
        my ($enc) = $lang =~ /\.(.*)$/;
        return $enc;
    }
    else {
        return "utf-8";
    }
}

sub str2sec {
    my $time_str = shift;
    my ($seconds, $cb_time);
    my %dir_op = (before => -1, after => 1);
    if ( $time_str =~ /^\s*(before|after):(\d+)(min|sec|hour)?\s*$/ ) {
        my ($dir, $x, $unit) = ($1, $2, $3);
        $unit ||= 'sec';
        #$unit =~ s/s$//; # 複数形
        my $unit_int = $unit eq 'sec'  ? 1
                     : $unit eq 'min'  ? 60
                     : $unit eq 'hour' ? 60*60
                     :                   1 # ここには来ないと思う
                     ;
        #warn "dir_op=$dir_op{$dir} x=$x unit_ini=$unit_int"
        $seconds = $dir_op{$dir} * $x * $unit_int;
        print "seconds is $seconds\n";
    }
    elsif ( $time_str =~ /^\s*(before|after):(\d+)(?:min|:)(\d+)(?:sec)?$/ ) {
        my ($dir, $min, $sec) = ($1, $2, $3);
        $seconds = $dir_op{$dir} * ( $min * 60 + $sec);
    }
    elsif ( $time_str =~ /^\s*(before|after):(\d+)(?:hour|:)(\d+)(?:min|:)(?:(\d+)(?:sec)?)?$/ ) {
        my ($dir, $hour, $min, $sec) = ($1, $2, $3, $4);
        $seconds = $dir_op{$dir} * ( $hour * 3600 + $min * 60 + $sec );
    }
    elsif ( $time_str eq 'now' || $time_str eq '.' || $time_str eq '-' ) {
        $seconds = 0;
    }
    else {
        my $before_after_sec = 0;
        my $time_str_pure = $time_str;
        if ( $time_str_pure =~ s/\s+((?:before|after):.*)$// ) {
            my $matched = $1;
            $before_after_sec = str2sec($matched);
            #warn "before_after_sec is $matched => $before_after_sec\n"
        }
        if ( $time_str_pure =~ /tomorrow/ ) {
            $time_str_pure =~ s{tomorrow}{ time2str('%Y/%m/%d', time()+86400 ) }e;
        }
        #warn "time_str_pure=$time_str_pure"
        $cb_time = Date::Parse::str2time($time_str_pure);
        if ( !$cb_time ) {
            die "ERORR: parse error time string.";
        }
        $seconds = ($cb_time - AnyEvent->time) + $before_after_sec;
    }
    return wantarray ? ($seconds, $cb_time) : $seconds;
}

1;

__END__

=pod

=head1 NAME

App::ClockUtils::Util - Utility subroutines for ClockUtils.

=head1 SYNOPSIS

 use App::ClockUtils qw(is_multibytes command_detect guess_terminal_encoding str2sec);
 my $str = shift;
 if ( is_multibytes($str) ) {
     print "argument includes multibyte characters\n";
 }
 
 my $command = 'ls';
 if ( command_detect($command) ) {
     print "command $command is found\n";
 }
 else {
     print "command $command is not found\n";
 }

=head1 SUBROUTINES

(stub)

=head1 REQUIRES

This command uses bash and it's builtin command "type" for detection.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
