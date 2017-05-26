#!/usr/bin/perl
use strict;
use warnings;

my $file_name = $ARGV[0];
my $chunk_size = $ARGV[1];
my $block_size = $chunk_size;
my $chunk_hex = sprintf("%08X", $chunk_size);
my @chunk_hex_digits = split('',$chunk_hex);
system("xxd -c1 -p $file_name $file_name.hex");
open(my $ifh, '<', "$file_name.hex");
my $line;
my @header_lines;
for(my $i=0;$i<4;$i++){
	$line = <$ifh>;
	chomp($line);
	push @header_lines, $line;
}
my $num_of_dims = hex '0x'.$header_lines[3];

my %dim_hex;
my @dim_dec;
my @dim_lines;
for(my $i=0;$i<$num_of_dims;$i++){
	for(my $j=0; $j<4; $j++){
		$line = <$ifh>;
		chomp($line);
		push @dim_lines, $line;
	}
	$dim_hex{$i} = [ $dim_lines[0], $dim_lines[1], $dim_lines[2], $dim_lines[3] ];
	$dim_dec[$i] = hex '0x'.join('',@{$dim_hex{$i}});
	if($i != 0){
		$block_size = $block_size*$dim_dec[$i];
	}
	@dim_lines =();
}

mkdir "$file_name.$chunk_size";
for(my $i = 1; $i<=($dim_dec[0]/$chunk_size); $i++){
	my $chunk_file = "$file_name.$chunk_size.".sprintf("%02d",$i);
	open(my $ofh, '>', "$chunk_file.hex") or die "could not open $chunk_file for writing: $!";
	print $ofh "00\n";
	print $ofh "00\n";
	print $ofh "08\n";
	print $ofh sprintf("%02X",$num_of_dims)."\n";
	for(my $j=0;$j<scalar(@chunk_hex_digits)/2;$j++){
		print $ofh $chunk_hex_digits[2*$j].$chunk_hex_digits[2*$j+1]."\n";
	}
	for(my $j=1;$j<scalar(keys(%dim_hex));$j++){
		for(my $k=0;$k<scalar(@{$dim_hex{$j}});$k++){
			print $ofh $dim_hex{$j}[$k]."\n";
		}
	}
	for(my $j=4*($num_of_dims+1)+$block_size*($i-1);$j<4*($num_of_dims+1)+$block_size*$i;$j++){
		$line = <$ifh>;
		print $ofh $line;	
	}
	print $ofh '0a';
	close $ofh;
	system("xxd -c1 -p -r $chunk_file.hex $file_name.$chunk_size/$chunk_file");
	system("rm $chunk_file.hex");
}

close $ifh;
system("rm $file_name.hex");
