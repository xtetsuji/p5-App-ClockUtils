App-ClockUtils
======================================

#INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

or using cpanm:

    git clone https://github.com/xtetsuji/p5-App-ClockUtils.git
    cpanm p5-App-ClockUtils/

TODO: to create rpm and deb package.

#DEPENDENCIES

Dependencies are following CPAN modules:

- AnyEvent
- AnyEvent::IRC (AnyEvent::IRC::Client)
- Date::Format
- Date::Parse

and those Perl core modules:

- Carp
- Data::Dumper
- Encode
- Exporter
- ExtUtils::MakeMaker (for install)
- Getopt::Long
- Test::More (for test)
- Pod::Usage

#COPYRIGHT AND LICENCE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
