#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

my $usage = <<USAGE;

Version: 1.0 (2011-04-23, lishenghui1005\@gmail.com)...
         1.1 (2011-04-26), Complete main codes...
         2.0 (2011-08-09), Add LIST (-l)...
         3.0 (2011-08-17), Add UNIQUE for R scripts...
         3.1 (2011-08-18), Add COLOR (cluster) for R scripts...
         3.2 (2023-09-08), Add prefix for tmp file (include gc_depth.stat.nodes, gc_depth.stat.R ). # by yexianingyue

Usage:
   perl $0 [data.file] <option> <value>...
      -r <string>:     Reference (*.fa);
      -d <string>:     Soapcoverage depth file;
      -o <string>:     Output figure (*.pdf);
   
   Those options is in choosing...
      -w <int>: (500)  Windows size;
      -s <int>: (200)  Windows step size;
      -n <string>:     Output nodes;
      -f <string>:     Output figure format (pdf or png);
      -x <int>: (100)  Maxmum depth of figure;
      -l <string>:     Use contigs in LIST;
      -h or -help:     Help info.  

Example:
   perl $0 -r ref.fa -d ref.soap.depth -o ref.pdf
   perl $0 -r ref.fa -d ref.soap.depth -o ref.pdf -n ref.nodes -x 200
   perl $0 -r ref.fa -d ref.soap.depth -o ref.pdf -l ref.some.list -x 200

Note:
   1) The format of *.list -------- Ref_ID -------- CLUSTER --------
   2) This is a beta version program, I will glad to any suggestion by someone...

USAGE
die $usage if @ARGV == 0 or $ARGV[0] =~ /^-h/;

my $Rdir = "R";

my ($ref_f, $dep_f, $out_f, $win_i, $step_i, $node_f, $list_f, $max_len) = ("", "", "", 500, 200, "", "", 100);
my $format = "pdf";

my @colors = (
    "#e31a1c", "#33a02c", "#1f78b4", "#ffff99", "#fb8072", "#6a3d9a", "#ff7f00", "#fb9a99",
    "#b2df8a", "#a6cee3", "#fdbf6f", "#cab2d6", "#8dd3c7", "#ffffb3", "#bebada", "#80b1d3",
    "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5");

GetOptions(
	"r:s" => \$ref_f,
	"d:s" => \$dep_f,
	"o:s" => \$out_f,
	"w:i" => \$win_i,
	"s:i" => \$step_i,
	"n:s" => \$node_f,
	"l:s" => \$list_f,
	"x:i" => \$max_len,
	"f:s" => \$format
);

die "Reference file is need...\n" unless $ref_f ne "";
die "Soapcoverage depth file is need...\n" unless $dep_f ne "";
die "Output figure is need...\n" unless $out_f ne "";
print STDERR "Program $0 Start...\n";

print STDERR "Reading $ref_f...\n";
my %sequence = &read_fa($ref_f);
my @k = keys %sequence;
print STDERR "Size: ".($#k+1)."\n";

print STDERR "Reading $dep_f...\n";
my %depth = &read_dp($dep_f);
@k = keys %depth;
print STDERR "Size: ".($#k+1)."\n";

my (%nodes, %choose);
my $color = 0;
my ($color_code, $legend_code) = ("", "");

if ($list_f ne "") {
	$color = 1;

    my %color_map; # 获取所有分组的数量
	
	open IN, $list_f or die $!;
	while(<IN>){
		chomp;
		my @s = split /\s+/;
		if (@s > 1) { 
            $choose{$s[0]} = $s[1];
            $color_map{$s[1]} = 1;
		} else { 
            $choose{$s[0]} = 1;
		}
	}

    my @groups = keys %color_map;
    my $ncolors = @colors;
    my (@legend_name_list, @legend_color_list);
    my ($legend_name_str, $legend_color_str) = ("", "");
    for(my $index=0; $index < @groups; $index++ ){
        my $color_index = $index % $ncolors; # 怕分组太多，这边取余数
        $color_code .= "points(data.uq[data.uq[,3]=='$groups[$index]',1:2], pch=46,col='$colors[$color_index]')\n"; # 这边是添加颜色的代码
        push @legend_name_list, "$groups[$index]";
        push @legend_color_list, "$colors[$color_index]";
    }

    $legend_name_str = join("', '", @legend_name_list);
    $legend_color_str = join("' ,'", @legend_color_list);
    $legend_code = "legend('topright', legend=c('$legend_name_str'), col=c('$legend_color_str'), lty=1, lwd=2)";

	close IN;
}


open OT, ">${out_f}.gc_depth.stat.nodes" or die $!;

for my $k(keys %sequence) {
	my $seq = $sequence{$k};
	
	unless (exists $depth{$k}) {
		die "No Depth Sequence: $k...\n";
	} 
	my $dep = $depth{$k}; 
	my @dep = split /-+/, $dep;
	### printf STDERR "%d\t%d\n", length $seq, $#dep+1;
	die "UNEQUAL Depth Sequence: $k...\n" unless (length $seq) == @dep;
	
	my $index = 1;
	for (my $i = 0; $i < (length $seq) - $win_i; $i += $step_i) {
		my $str = substr($seq, $i, $win_i);
		my @dpa = @dep[$i .. $i+$win_i-1];
		
		my $x = "$k-$index"; $x =~ s/^>//;
		my $y = $k; $y =~ s/^>//;

		$str =~ s/(n|N|-)//g;
		$nodes{$x}{gc} = &gc_stat($str, length $str);
		$nodes{$x}{dp} = &dp_stat(\@dpa, length $str);
		next unless exists $nodes{$x}{gc} or exists $nodes{$x}{dp};
		
		if ($list_f eq "") {
			print OT "$x\t$nodes{$x}{gc}\t$nodes{$x}{dp}\t0\n";
		} else {
			print OT "$x\t$nodes{$x}{gc}\t$nodes{$x}{dp}\t$choose{$y}\n" if exists $choose{$y};
		}
		$index++;
	}
}
close OT;

my $script = <<SCR;

data <- read.table("${out_f}.gc_depth.stat.nodes",head=F)

# depth.cutoff <- $max_len ### Depth less than 100 or 200...
depth.cutoff <- quantile(data[,3], 0.99, type = 7) * 1.2
depth.break <- depth.cutoff / 100
data.gc <- data[,2:4]
data.gc <- data.gc[data.gc[,1] <= 100, ] ### GC less than 100...
data.gc <- data.gc[data.gc[,2] <= depth.cutoff, ]
data.gc <- data.gc[data.gc[,2] > 0, ]
data.gc[,2] <- data.gc[,2] / depth.break #########
data.gc <- as.matrix(data.gc)

######################################
 x <- nrow(data.gc)
 data.gcc <- matrix(0,nrow=x+2,ncol=3)
 data.gcc[1:x,] <- data.gc
 data.gcc[x+1,] <- c(0,0,0)
 data.gcc[x+2,] <- c(100,100,0)
 data.gc <- as.matrix(data.gcc)
######################################

data.numb <- matrix(0,nrow=100,ncol=100)
for(i in 1:nrow(data.gc)) {
	k = floor(data.gc[i,1]) + 1
	m = floor(data.gc[i,2]) + 1
	if(k > 100) k <- 100
	if(m > 100) m <- 100
	data.numb[k,m] = data.numb[k,m] + 1
}

data.uq <- unique(data.gc)

if($color==0) {
	data.col <- c(1:nrow(data.uq))
	data.col[] <- 0
	for(i in 1:nrow(data.uq)) {
		k = floor(data.uq[i,1]) + 1
		m = floor(data.uq[i,2]) + 1
		if(k > 100) k <- 100
		if(m > 100) m <- 100
		data.col[i] = data.numb[k,m]
	}
}

pdf("$out_f")

nf <- layout(matrix(c(0,2,0,0,1,3),2,3,byrow=T),c(0.5,3,1),c(1,3,0.5),TRUE)
par(mar=c(3,3,1,1))

data.gc[,2] <- data.gc[,2]*depth.break
data.uq[,2] <- data.uq[,2]*depth.break

if ($color==0) {
	plot(data.uq[,1:2],pch=46,col=hcl(h=1,c=data.col),xlim=c(0,100),ylim=c(0, depth.cutoff),axes=F)
} else {
	plot(data.uq[1,1:2],pch=46,col="red",xlim=c(0,100),ylim=c(0, depth.cutoff),axes=F)
    $color_code
}
axis(side=1,seq(0,100,10))
axis(side=2,seq(0, depth.cutoff, depth.cutoff/10))

xhist <- hist(data.gc[,1],breaks=100,plot=FALSE)
yhist <- hist(data.gc[,2],breaks=100,plot=FALSE)

par(mar=c(0,3,1,1))
barplot(xhist\$counts,space=0)
par(mar=c(3,0,1,1))
barplot(yhist\$counts,space=0,horiz=TRUE)
$legend_code
dev.off()
#############################################################
SCR

open OT, ">${out_f}.gc_depth.stat.R";
print OT $script;
close OT;

`$Rdir -f ${out_f}.gc_depth.stat.R`;

# if ($node_f ne '') { `mv ${out_f}.gc_depth.stat.nodes $node_f` unless $node_f eq "${out_f}.gc_depth.stat.nodes";
# } else { `rm -f ${out_f}.gc_depth.stat.nodes`;
# }

# `rm -f ${out_f}.gc_depth.stat.R`;

print STDERR "Program End...\n";
############################################################
sub read_fa {
	my %sequence;
	my ($seq, $head) = ('', '');

	my $ref = shift;
	if ($ref =~ /\.gz$/) { open IN, "gzip -dc $ref |" or die $!;
	} else { open IN, $ref or die $!;
	}

	while (<IN>) {
		chomp;
		if (/^(>\S+)/) {
			$sequence{$head} = $seq unless $seq eq '';
			($seq, $head) = ('', $1);
			next;
		}
		$seq .= $_;
	}
	close IN;
	$sequence{$head} = $seq unless $seq eq '';
	return %sequence;
}

sub read_dp {
	my %depth;
	my ($seq, $head) = ("", "");

	my $dep_f = shift;
	if ($dep_f =~ /\.gz$/) { open IN, "gzip -dc $dep_f |" or die $!;
	} else { open IN, $dep_f or die $!;
	}

	while (<IN>) {
		chomp;
		if (/^(>\S+)/) {
			my $h = $1;
			$seq =~ s/^-//g; ######
			$seq =~ s/-$//g; ######
			$seq =~ s/-+/-/g; ######
			$seq =~ s/-\s+-/-/g; ######
			$depth{$head} = $seq unless $seq eq "";
			($seq, $head) = ("", $h);
			next;
		}
		s/\s+/-/g;
		$seq .= "-$_";
	} 
	$seq =~ s/^-//g; ######
	$seq =~ s/-$//g; ######
	$seq =~ s/-+/-/g; ######
	$seq =~ s/-\s+-/-/g; ######
	$depth{$head} = $seq unless $seq eq '';
	close IN;
	return %depth;
}

sub gc_stat {
	my ($str, $len) = @_;
	$str =~ s/(g|c|G|C)//g;
	my $gclen = $len - (length $str);
	return int($gclen/$len*1000 + 0.5)/10;	
} 

sub dp_stat {
	my ($dp, $len) = @_;
	my $sum = 0;
	foreach (@$dp) { $sum += $_; }
	return int($sum/$len*10 + 0.5)/10;
}
############################################################

