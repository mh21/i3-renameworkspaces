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

my $config = {};
if (open(my $fh, '<', $opts{'c'} || $ENV{'HOME'} . '/.i3workspaceconfig')) {
    local $/; $config = decode_json(<$fh>); close($fh);
}

chomp(my $hostname = `hostname`);

my $i3 = i3();
$i3->connect->recv() or die('Error connecting to i3');

sub recurse {
    my ($parent, $wss, $windows) = @_;
    if ($$parent{'type'} eq 'workspace') {
        $$wss{$$parent{'num'}} = { name => $$parent{'name'}, windows => ($windows = [])};
    }
    if ($$parent{'window_properties'}) {
        my $class = lc($$parent{'window_properties'}{'class'});
        my $instance = lc($$parent{'window_properties'}{'instance'});
        my $name = $$config{'classes'}{$class} ||
                   $$config{'instances'}{$instance} ||
                   $class;
        push(@$windows, $name) if !grep {$_ eq $name} @$windows;
    }
    foreach (@{$$parent{'nodes'}})          { recurse($_, $wss, $windows) };
    foreach (@{$$parent{'floating_nodes'}}) { recurse($_, $wss, $windows) };
}

sub updatelabels {
    $i3->get_tree->cb(sub {
        my $wss = {};
        recurse($_[0]->recv(), $wss);
        # say Dumper($_[0]->recv());
        # say Dumper($wss);
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

sub defaultlayout {
    my ($msg) = @_;
    my $layout = $$config{'layouts'}{$hostname};
    # TODO: this still doesn't work for the first initial workspace+terminal
    return unless $layout &&
        ($$msg{'change'} eq 'init' ||
         $$msg{'change'} eq 'focus' && scalar @{$$msg{'current'}{'nodes'}} == 0);
    my $con_id = $$msg{'current'}{'id'};
    $i3->command(qq|[con_id="$con_id"] layout $layout|);
}

$i3->subscribe({
    window    => sub { say('window');    updatelabels();                    },
    workspace => sub { say('workspace'); updatelabels(); defaultlayout(@_); },
    _error    => sub { say('error');     exit(1);                           }
})->recv()->{'success'} or die('Error subscribing to events');

AnyEvent::condvar->recv();
