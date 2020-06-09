#!/usr/bin/perl

use AnyEvent;
use AnyEvent::I3;
use Data::Dumper;
use Getopt::Std;
use JSON::PP;
use Linux::Inotify2;

use v5.10;
use strict;
use warnings;

my $scriptname = $0;
my @scriptargs = @ARGV;
getopts('hc:', \my %opts);
$opts{'h'} and say("Usage: i3-renameworkspaces.pl [-h] [-c configfile]"), exit(1);

# config file handling
my $configname = $opts{'c'} || $ENV{'HOME'} . '/.i3workspaceconfig';
my $config = {};
if (open(my $fh, '<', $configname)) {
    local $/; $config = decode_json(<$fh>); close($fh);
}
my $inotify = new Linux::Inotify2 or die("Unable to create new inotify object: $!");
my $inotifyw = $inotify->watch($configname, IN_MOVED_TO | IN_CLOSE_WRITE | IN_DELETE, sub {
    say('Restarting on config file change');
    exec($^X, $scriptname, @scriptargs);
});
my $inotifyio = AnyEvent->io(fh => $inotify->fileno, poll => 'r', cb => sub { $inotify->poll });

# hostname
chomp(my $hostname = `hostname`);

# i3
my $i3 = i3();
$i3->connect->recv() or die('Error connecting to i3');

sub recurse {
    my ($parent, $wss, $windows) = @_;
    if ($$parent{'type'} eq 'workspace') {
        if ( $$config{'staticnames'}{$$parent{'num'}} ) {
            $$wss{$$parent{'num'}} = { name =>$$config{'staticnames'}{$$parent{'num'}}, oldname => $$parent{'name'}} ;
        }
        else {
            $$wss{$$parent{'num'}} = {  windows => ($windows = []), oldname=> $$parent{'name'}};
        }        
    }
    if ($$parent{'window_properties'}) {
        my $title = lc($$parent{'window_properties'}{'title'});
        my $role = lc($$parent{'window_properties'}{'window_role'});
        my $instance = lc($$parent{'window_properties'}{'instance'});
        my $class = lc($$parent{'window_properties'}{'class'});
        my $name = $$config{'titles'}{$title} ||
                   $$config{'roles'}{$role} ||
                   $$config{'instances'}{$instance} ||
                   $$config{'classes'}{$class} ||
                   lc($class);
        push(@$windows, $name) if !grep {$_ eq $name} @$windows;
    }
    foreach (@{$$parent{'nodes'}})          { recurse($_, $wss, $windows) };
    foreach (@{$$parent{'floating_nodes'}}) { recurse($_, $wss, $windows) };
}

sub updatelabels {
    my $newname ;
    $i3->get_tree->cb(sub {
        my $wss = {};
        recurse($_[0]->recv(), $wss);
        # say Dumper($_[0]->recv());
        # say Dumper($wss);
        while (my ($num, $ws) = each(%$wss)) {
            my $oldname = $$ws{'oldname'};
            my $staticname = $$ws{'name'};
            if ($$ws{'windows'}) {
                $newname = join(': ', $num, join(' ', @{$$ws{'windows'}}) || ());
            }
            else {
                $newname = join(': ', $num, $staticname);
            }
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

# event loop
AnyEvent::condvar->recv();
