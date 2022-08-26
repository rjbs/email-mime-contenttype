# vim:ft=perl
use strict;
use warnings;

use Test::More 'no_plan';

use Email::MIME::ContentType;

my @cd_tests = (
  {
    expect  => 'inline',
    input   => { type => 'inline', attributes => {} },
  },

  {
    expect  => 'attachment',
    input   => { type => 'attachment', attributes => {} },
  },

  {
    expect  => 'attachment; filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"',
    input   => {
      type => 'attachment',
      attributes => {
        filename => 'genome.jpeg',
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*=UTF-8''genom%C3%A9.jpeg; filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "genom\x{E9}.jpeg",
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect => q(attachment; filename=loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input => {
      type => 'attachment',
      attributes => {
          filename => 'loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
          'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*0=loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo; filename*1=ong; filename=looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo...; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => 'looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename="l\\"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong"; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => 'l"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect => q(attachment; filename*0="l\\"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo"; filename*1="ong"; filename="l\"ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo..."; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input => {
      type => 'attachment',
      attributes => {
        filename => 'l"ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong',
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*=UTF-8''%C3%A9loooooooooooooooooooooooooooooooooooooooooooooooooong; filename=eloooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "\x{E9}loooooooooooooooooooooooooooooooooooooooooooooooooong",
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*0*=UTF-8''%C3%A9loooooooooooooooooooooooooooooooooooooooooooooooooo; filename*1*=ong; filename=elooooooooooooooooooooooooooooooooooooooooooooooooooong; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "\x{E9}looooooooooooooooooooooooooooooooooooooooooooooooooong",
        'modification-date' => 'Wed, 12 Feb 1997 16:29:51 -0500'
      }
    },
  },

  {
    expect  => q(attachment; filename*=UTF-8''%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9; filename=eeeeeeeee),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}"
      }
    },
  },

  {
    expect  => q(attachment; filename*0*=UTF-8''%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9%C3%A9; filename*1*=%C3%A9; filename=eeeeeeeeee),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}\x{E9}"
      }
    },
  },

  {
    expect  => q(attachment; filename="UTF-8''name"),
    input   => {
      type => 'attachment',
      attributes => {
        filename => "UTF-8''name"
      }
    },
  },
);

sub test {
  my ($input, $expect) = @_;
  local $_;
  my $info = $expect;
  $info =~ s/\r/\\r/g;
  $info =~ s/\n/\\n/g;
  my $got = build_content_disposition($input);
  is($got, $expect, "Can build C-D <$info>");
  my $parsed = parse_content_disposition($got);
  is_deeply($parsed, $input, "Can parse C-D <$info>");
}

for my $test (@cd_tests) {
  test($test->@{ qw(input expect) });
}
