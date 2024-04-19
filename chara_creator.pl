#!/usr/bin/perl

use warnings;

sub store_meta {
	my $json_filename = shift;
	my $img_filename = shift;
	my $json = `cat $json_filename | base64`;
	`exiftool -config ./chara.config -XMP-dc:Chara="$json" $img_filename`;
}

if ($#ARGV + 1 != 2) {
	print "Usage: perl ./chara_creator.pl <json file> <png file>\n";
	exit;
}
my $json_filename = $ARGV[0];
my $img_filename = $ARGV[1];
if ($json_filename !~ /\.json$/ || !-e $json_filename) {
	print "INVALID JSON FILE!\n";
	exit;
}
if ($img_filename !~ /\.png$/ || !-e $img_filename) {
	print "INVALID PNG FILE!\n";
	exit;
}

store_meta($json_filename, $img_filename);