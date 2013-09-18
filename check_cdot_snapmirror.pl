#!/usr/bin/perl

# check_cdot_snapmirror
# usage: ./check_cdot_snapmirror hostname username password
# Alexander Krogloth <git at krogloth.de>

use lib "/usr/lib/netapp-manageability-sdk-5.1/lib/perl/NetApp";
use NaServer;
use NaElement;
use strict;
use warnings;

my $s = NaServer->new ($ARGV[0], 1, 3);

$s->set_transport_type("HTTPS");
$s->set_style("LOGIN");
$s->set_admin_user($ARGV[1], $ARGV[2]);

my $output = $s->invoke("snapmirror-get-iter");

if ($output->results_errno != 0) {
	my $r = $output->results_reason();
	print "UNKNOWN - $r\n";
	exit 3;
}

my $snapmirror_failed = 0;
my $snapmirror_ok = 0;
my $failed_names;

my $snapmirrors = $output->child_get("attributes-list");
my @result = $snapmirrors->children_get();

foreach my $snap (@result){

	my $healthy = $snap->child_get_string("is-healthy");

	if($healthy eq "false"){

		my $name = $snap->child_get_string("destination-volume");

	        if($failed_names){
	                $failed_names .= ", " . $name;
	        } else {
	                $failed_names .= $name;
	        }

		$snapmirror_failed++;
	}
	$snapmirror_ok++;
}

if($snapmirror_failed > 0){
        print "CRITICAL: $snapmirror_failed snapmirror(s) failed - $snapmirror_ok snapmirror(s) ok\n$failed_names\n";
        exit 2;
} else {
	print "OK: $snapmirror_ok snapmirror(s) ok\n";
	exit 0;
}

