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

my $destination = "Z:\\my_projects\\paediatrics_fdg\\reconsFeb2022"; #sonne
my $source = "C:\\Users\\pet\\Desktop\\michelle\\paediatric_fdg\\february2022_anonymous";

my @patients = <"C:\\Users\\pet\\Desktop\\michelle\\paediatric_fdg\\february2022_anonymous\\*">; #Data path
my $temp = "C:\\Users\\pet\\Desktop\\michelle\\paediatric_fdg\\data"; #Temporary patient list

#Create a temporary dir with a list of patient names
# for my $patient (@patients){
	# my @name = $patient =~ m([^/\\]+)g;
	# mkdir("$temp\\$name[@name-1]");
# }


my $patientname = $ARGV[0]; #used input

##MOVE DICOMS TO SONNE
#print("$patientname")
mkdir("$destination\\$patientname\\$patientname_dicom");

dircopy("$source\\$patientname-Converted\\$patientname-LM-WB\\$patientname-LM-WB-PSFTOF_000_000_ctm.v-DICOM","$destination\\$patientname\\$patientname_dicom") or die ("Cannot move $patientname");

chdir("$source\\$patientname-Converted\\$patientname-LM-WB");

#MOVE SINOGRAMS TO SONNE
mkdir("$destination\\$patientname\\Sinograms");
my @sino = <*-sino*>; 
for my $sinofile (@sino){
	copy($sinofile, "$destination\\$patientname\\Sinograms") or die ("Cannot move $sinofile to $patientname");
}
my @umap = <*-umap*>; 
for my $umapfile (@umap){
	copy($umapfile, "$destination\\$patientname\\Sinograms") or die ("Cannot move $umapfile to $patientname");
}
print("!PATIENT $patientname COMPLETE!");
chdir("$source");

# ##CLEANUP
# rmtree("$source\\$patientname");
# rmtree("$source\\$patientname-Converted");