# -*- cperl -*-

requires perl => '5.008001';

# Common
requires 'AnyEvent';
requires 'AnyEvent::IRC::Client';
requires 'Carp';
requires 'Date::Format';
requires 'Date::Parse';
requires 'Encode';
requires 'Exporter';
requires 'Growl::Any';

on test => sub {
    requires 'Test::More', "0.98";
};
