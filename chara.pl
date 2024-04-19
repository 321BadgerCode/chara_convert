#!/usr/bin/perl

use open qw( :std :encoding(UTF-8) );
use warnings;

sub get_filename {
	my $filename = shift;
	my @parts = split(/\./, $filename);
	pop @parts;
	return join(".", @parts);
}

sub organize_json {
	my $json = shift;
	my $indent = 0;
	my $in_quotes = 0;
	my $new_json = "";
	my $prev_char = "";
	for (my $i = 0; $i < length($json); $i++) {
		my $char = substr($json, $i, 1);
		if ($i>=1) {
			$prev_char = substr($json, $i-1, 1);
		}
		if ($char eq "\"" && $prev_char ne "\\") {
			$in_quotes = !$in_quotes;
		}
		if ($in_quotes) {
			$new_json .= $char;
			next;
		}
		if ($char eq "{" || $char eq "[") {
			$new_json .= $char . "\n" . " " x ($indent + 4);
			$indent += 4;
		} elsif ($char eq "}" || $char eq "]") {
			$indent -= 4;
			$new_json .= "\n" . " " x $indent . $char;
		} elsif ($char eq ",") {
			$new_json .= $char . "\n" . " " x $indent;
		} else {
			$new_json .= $char;
		}
	}
	return $new_json;
}

sub get_json_data {
	my $json = shift;
	my $key = shift;
	my $value = "";
	if ($json =~ /"$key": "([^"\\]*(\\.[^"\\]*)*)"/) {
		$value = $1;
	}
	return $value;
}

sub get_yaml {
	my @data = @_;
	my $yaml = "";
	my $key = shift @data;
	my $value = shift @data;
	my $indent = shift @data;
	if ($value eq "") {
		return "";
	}
	$value =~ s/\\t/\t/g;
	$value =~ s/\\r\\n/\n/g;
	$value =~ s/\\n/\n/g;
	$value =~ s/\\\\/\\/g;
	$value =~ s/\\"/\"/g;
	$value =~ s/\\u([0-9a-fA-F]{4})/chr(hex($1))/ge;
	my $delimeter = $key eq "" ? "" : ":";
	$yaml .= " " x (($indent-1) * 2) . $key . "${delimeter}\n";
	for my $line (split(/\n/, $value)) {
		$yaml .= " " x ($indent * 2) . $line . "\n";
	}
	return $yaml;
}

sub get_yaml_adv {
	my @data = @_;
	my $yaml = "";
	my $indent = 1;
	my $indented = 0;
	for (my $i = 0; $i <= $#data; $i++) {
		for (my $j = 0; $j <= $#{$data[$i]}; $j++){
			if (ref($data[$i]->[$j]) eq "ARRAY") {
				if($indented == 0){$indent++;$indented=1;}
				my @arr = ($data[$i]->[$j][0], $data[$i]->[$j][1], $indent);
				$yaml .= get_yaml(@arr);
			} else {
				if($indented == 1){$indent--; $indented=0;}
				my $key = $data[$i]->[$j];
				$j++;
				my $value = $data[$i]->[$j];
				my @arr = ($key, $value, $indent);
				$yaml .= get_yaml(@arr);
			}
		}
	}
	return $yaml;
}

sub save_file {
	my $filename = shift;
	my $data = shift;
	open($fh, '>', $filename) or die "Could not open file '$filename' $!";
	print $fh $data;
	close $fh;
}

sub get_json_val {
	my $json_filename = shift;
	my $key = shift;
	return `cat $json_filename | grep -i "$key" | sed 's/.*: //' | sed 's/\"//g' | sed 's/,//g' | tr -d '\n'`;
}

sub get_new_name {
	my $name = shift;
	$name =~ s/main_//;
	$name =~ s/_[0-9a-fA-F]{8}//;
	$name =~ s/_spec_v2//;
	return $name;
}

if ($#ARGV + 1 != 1) {
	print "Usage: perl char.pl <filename.png>\n";
	exit;
}
elsif ($ARGV[0] eq "-h" || $ARGV[0] eq "--help") {
	print "Usage: perl chara.pl <filename.png>\n";
	exit;
}
elsif ($ARGV[0] eq "-v" || $ARGV[0] eq "--version") {
	print "char.pl 1.0.0\n";
	exit;
}
my $filename = $ARGV[0];
my $filename_no_ext = get_filename($filename);
if ($filename !~ /\.png$/ || !-e $filename) {
	print "INAVLID PNG FILE!\n";
	exit;
}

my $json_filename = "./config.json";
if (!-e $json_filename) {
	my $default = my $h = <<"EOF";
{
	"save_json": "false",
	"img_arg": "-all= \$filename.png",
	"del_og": "true"
}
EOF
	save_file($json_filename, $default);
	print "\"config.json\" file created!\n";
	exit;
}
my $is_save_json = get_json_val($json_filename, "save_json");
my $img_arg = get_json_val($json_filename, "img_arg");
$img_arg =~ s/\$filename/$filename_no_ext/g;
my $del_og = get_json_val($json_filename, "del_og");

my $json = `exiftool $filename | grep -i "chara"`;
if ($json eq "") {
	print "NO CHARA DATA FOUND!\n";
	print "Make sure the PNG file has the \"chara\" tag!\n";
	print "Use the following command to add metadata to the image:\n";
	print "\tperl ./chara_creator.pl <json file> $filename\n";
	exit;
}
$json = `echo "$json" | sed 's/.*: //' | base64 -d`;
$json = organize_json($json);
if ($is_save_json eq "true") {
	my $json_filename = $filename_no_ext . ".json";
	save_file($json_filename, $json);
}

my $name = get_json_data($json, "name");
my $greeting = get_json_data($json, "first_mes");
my $description = get_json_data($json, "description");
my $personality = get_json_data($json, "personality");
my $scenario = get_json_data($json, "scenario");
my $example = get_json_data($json, "mes_example");

my $yaml = get_yaml_adv(
	["name", $name],
	["greeting", $greeting],
	["context", $description,
		["personality", $personality],
		["scenario", $scenario],
		["", $example]
	]
);
my $yaml_filename = $filename_no_ext . ".yaml";
save_file($yaml_filename, $yaml);
`sed -i 's/greeting:/greeting: |-/' $yaml_filename`;
`sed -i 's/context:/context: |/' $yaml_filename`;

`exiftool $img_arg`;
my $new_filename = get_new_name($filename);
`mv $filename $new_filename`;
$new_filename = get_new_name("$filename_no_ext.yaml");
`mv $filename_no_ext.yaml $new_filename`;

if ($del_og eq "true") {
	my $arg = $filename_no_ext . ".png_original ";
	`rm $arg`;
}