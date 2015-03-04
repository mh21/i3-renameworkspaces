#!/usr/bin/perl

use AnyEvent;
use AnyEvent::I3;
use Data::Dumper;
use Getopt::Std;
use JSON::PP;

use v5.10;
use strict;
use warnings;

getopts('hc:', \my %opts);

$opts{'h'} and say("Usage: i3-renameworkspaces.pl [-h] [-c configfile]"), exit(1);

my $short = {};
if (open(my $fh, '<', $opts{'c'} || $ENV{'HOME'} . '/.i3renameworkspacesconfig')) {
    local $/; $short = decode_json(<$fh>); close($fh);
}

my $i3 = i3();
$i3->connect->recv() or die('Error connecting to i3');

sub recurse {
    my ($parent, $wss, $windows) = @_;
    if ($$parent{'type'} eq 'workspace') {
        $$wss{$$parent{'num'}} = { name => $$parent{'name'}, windows => ($windows = [])};
    }
    if ($$parent{'window_properties'}) {
        my $instance = lc($$parent{'window_properties'}{'instance'});
        my $name = $$short{$instance} || $instance;
        push(@$windows, $name) if !grep {$_ eq $name} @$windows;
    }
    foreach (@{$$parent{'nodes'}})          { recurse($_, $wss, $windows) };
    foreach (@{$$parent{'floating_nodes'}}) { recurse($_, $wss, $windows) };
}

sub updatelabels {
    $i3->get_tree->cb(sub {
        my $wss = {};
        recurse($_[0]->recv(), $wss);
        #say Dumper($_[0]->recv());
        #say Dumper($wss);
        while (my ($num, $ws) = each(%$wss)) {
            my $oldname = $$ws{'name'};
            my $newname = join(': ', $num, join(' ', @{$$ws{'windows'}}) || ());
            if ($num >= 1 && $oldname ne $newname) {
                say("\"$oldname\" -> \"$newname\"");
                $i3->command("rename workspace \"$oldname\" to \"$newname\"");
            }
        }
    });
}

$i3->subscribe({
    window    => sub { say('window');    updatelabels(); },
    workspace => sub { say('workspace'); updatelabels(); },
    _error    => sub { say('error');     exit(1);        }
})->recv()->{'success'} or die('Error subscribing to events');

AnyEvent::condvar->recv();
