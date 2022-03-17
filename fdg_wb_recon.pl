#!/usr/bin/env perl

use warnings;
use strict;

use Cwd;
use Cwd 'abs_path';

use Digest::SHA qw(sha1_hex);
use File::Copy;
use File::Copy qw(copy);
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path qw(rmtree);
use File::Basename;
use POSIX;


my @patients = <"C:\\Users\\pet\\Desktop\\michelle\\paediatric_fdg\\data\\*">; #Data path

for my $patient (@patients){
    my @name = $patient =~ m([^/\\]+)g;
	chdir("february2022_anonymous");
    system("perl LM_gen_script2.pl $name[@name-1]");
}

