#!/usr/bin/env perl

# Generates serveral VM folders from a given  
#
# Usage: perl LM_gen_script.pl directory_name
#   directory_name is a directory, that exists and contains the following files:
#       See below in the comments for probber calling
#
#
# Author: Christoffer V Jensen - CJEN0668
#
#
#
use warnings;
use strict;
#Modules
use File::copy; #Not used 
use Cwd;



# Checks if a filepath is a valid path to a  directory
# Args:
#   1st args : The file name of the folder
#                  Just to be 100% clear because i'm going to forget 
#                           ok: Fuentes_Martin_Juan_Jose_20190819_180332_orig-Copy
#                       NOT ok: .\Fuentes_Martin_Juan_Jose_20190819_180332_orig-Copy

# Overall idea of the script
# Apply JSRecon to directory
# Run LM-XX-Histogramming batch script
# Copy and modify each of the script into a newly created directory called -LM-WB
# Run LM-WB Makeumap
# Run IF2Dicom.bat

#Helper functions 
sub handleprogram {
    my $input_directory                 = $_[0]; #input Filepath containing directory necessary for JSRecon to run
    my $javascript_call_method          = "cscript";
    my $js_recon_path                   = "C:\\JSRecon12\\JSRecon12.js";
    my $params                          = "C:\\Users\\pet\\Desktop\\michelle\\paediatric_fdg\\params-FDG.txt"; #File Name of the params file
    my $js_recon_command                = "$javascript_call_method $js_recon_path $input_directory $params";
    my $js_recon_directory_extention    = "-Converted";
    my $product_directory               = "$input_directory$js_recon_directory_extention";  
    my $directory_WB                    = "$input_directory-LM-WB";

    #Checks user input
    #Note that this doesn't check if the input is correct
    #TODO: Make user input such that the user can input a directory of directories,
    #where this script will be applied to each of them. In the case where one of them fails simply skip,
    #rather than exit all together
    if (! -e $input_directory) {
        if (! -d $input_directory) {
            print "usage: directory_name\n";
            exit 1; #Perl doesn't have bools
        } 
    }
    #Run JSRecon
    my $js_recon_return_value = system($js_recon_command);

    #Check to see if the JSRecon ran successfully!
    if ($js_recon_return_value) {
        print "JSRecon failed !\n";
        exit 1;
    }

    my @LM_directories;
    my $dircounter = 0;
    opendir(Created_Directory, $product_directory) or die "Could not read diretory: $product_directory!\n";
    my @directories = readdir Created_Directory;

    #Grab all the list mode files
    foreach my $directory (@directories) {
        if ($directory =~ /LM-[0-9]{2}$/) {
            @LM_directories[$dircounter] = $directory;
            $dircounter++;
        }
    }

    chdir($product_directory) or die "Could not enter diretory $product_directory!\n"; #Move into the created directory
    mkdir($directory_WB);
    #Initiation for Generating Scripts to the header

    my $header_file_LM_WB_name = "$input_directory-LM-WB-sino.mhdr"; 
    my $header_file_LM_WB_full_path = "$directory_WB\\$header_file_LM_WB_name";
    open(my $header_file_LM_WB, ">", $header_file_LM_WB_full_path) or die "Could not Create File: $header_file_LM_WB_full_path\n";

    #Here we go through each of the folders: 
    foreach my $index (0 .. ($dircounter - 1)) {
        #Run the Histogram-bat file
        my $bat_histrogram_file_name;
        #Here we are making the selection of the bat correct bat file. Note that if the index is below 10, there's a padded 0.
        #If you find a scan with more than 100 scans Please send it to me so i can test if this work
        if ($index < 10) {
            $bat_histrogram_file_name = ".\\Run-00-$input_directory-LM-0$index-Histogramming.bat";
            chdir("$input_directory-LM-0$index");
        } else {
            chdir("$input_directory-LM-$index");
            $bat_histrogram_file_name = ".\\Run-00-$input_directory-LM-$index-Histogramming.bat";
        }
        system("$bat_histrogram_file_name");
        chdir("..");
		
        #Create the header_file
        #  The headerfile is on the format:
        #       <input_directory>-LM-WB-sino.mhdr
        my $header_file_path = "$LM_directories[$index]\\$LM_directories[$index]-sino.mhdr";
        open(my $header_file, "<", $header_file_path) or die "Could not open file: $header_file_path";
        # Header information needs to be written here
        # The header is a tad complicated, so the code is a bit difficult to read as a consiquence
        # If you wanna understand what is going on in the IF statement down below
        # I recommend opening one of the header files to see, just what 
    
        my $line_count = 0;
        if($index == 0) {
            for( ; $line_count < 15; $line_count++){
                my $line = <$header_file>;
                print $header_file_LM_WB "$line";     
            }
            #Line 15 needs modification
            my $line15 = <$header_file>;
            $line_count++;
            print $header_file_LM_WB "%number of horizontal bed offsets:=$dircounter\n";
        
            #Line 16 is free to copy
            my $line16  = <$header_file>;
            $line_count++;
    #
            print $header_file_LM_WB "$line16";
        
            #This is the special Number line where an important number
            my $line_emission_data_types =  <$header_file>;
            $line_count++;
            print $header_file_LM_WB "$line_emission_data_types";
        
            my ($not_used_at_all, $emission_data_types) = split /:=/, $line_emission_data_types;
            $emission_data_types = int($emission_data_types);
        
            my $line_to_read_from = $line_count + $emission_data_types + 4;
        
            for( ; $line_count < $line_to_read_from; $line_count++){
                my $line = <$header_file>;
                print $header_file_LM_WB "$line"; 
            }
            my $Total_data_Set_line = "\!total number of data sets:=$dircounter\n";
            print $header_file_LM_WB "$Total_data_Set_line";
            #So this Line is very very long
            my $data_set_line_part_1 = "%data set [1]:={30,";
         
            my $LM_00_suffix = "-LM-00";
            my $data_set_filepath_1 = "..\\$input_directory-LM-00\\$input_directory-LM-00-sino-0.s.hdr";
            my $data_set_filepath_2 = "..\\$input_directory$LM_00_suffix\\$input_directory$LM_00_suffix-sino-0.s";
            #
            my $data_set_line = "$data_set_line_part_1$data_set_filepath_1,$data_set_filepath_2}\n";
            print $header_file_LM_WB "$data_set_line";
        
        } else { #Header is written the remaining must be written here
            my $counter = $index*100 + 30;
            my $data_set_index = $index + 1;
            my $data_set_line_prefix = "%data set [$data_set_index]:={$counter";
        
            my $LM_suffix;
            #Padding Strikes again!
            if ($index < 10) { 
                $LM_suffix = "-LM-0$index";
            } else {
                $LM_suffix = "-LM-$index";
            }
            my $data_set_filepath_1 = "..\\$input_directory$LM_suffix\\$input_directory$LM_suffix-sino-0.s.hdr";
            my $data_set_filepath_2 = "..\\$input_directory$LM_suffix\\$input_directory$LM_suffix-sino-0.s";
        
            my $data_set_line = "$data_set_line_prefix,$data_set_filepath_1,$data_set_filepath_2}\n";
            print $header_file_LM_WB "$data_set_line";
        }
        close($header_file);
    }
    close($header_file_LM_WB);
    # Header done
    #
    # Mass Scripts

    my $line_count;
    
    #Copy Makeumap script
    $line_count = 0;
    my $makeumap_script_original_path = "$input_directory-LM-00\\Run-01-$input_directory-LM-00-Makeumap.bat";
    my $makeumap_script_copy_path = "$input_directory-LM-WB\\Run-01-$input_directory-LM-WB-Makeumap.bat";

    open(my $makeumap_script_original, "<", $makeumap_script_original_path) or die "could not open file $makeumap_script_original_path";
    open(my $makeumap_script_copy, ">", $makeumap_script_copy_path) or die "could not open file $makeumap_script_copy_path";

    while(my $line = <$makeumap_script_original>){
        if ($line_count == 11){
            #This Line is VERY long
            my $line_start = "set cmd= %cmd% --ou";
            my $file_1   = "..\\$input_directory-LM-WB\\$input_directory-LM-WB-umap.mhdr"; 
            my $file_2   = "..\\$input_directory-LM-WB\\$input_directory-LM-WB-umapBedRemoval.mhdr";
            print $makeumap_script_copy "$line_start $file_1,$file_2\n";
        } elsif ($line_count == 19){
            print $makeumap_script_copy "set cmd= %cmd% -l  73,..\\$input_directory-LM-WB\n"
        } else {
            print $makeumap_script_copy "$line";
        }
        $line_count++;
    }

    close($makeumap_script_original);
    close($makeumap_script_copy);
    
    #Copy PSFTOF script 
    # OBS: If blurring is used, then line count should be incremented from line 29 and onwards.
    $line_count = 0;
    my $PSFTOF_script_original_path = "$input_directory-LM-00\\Run-04-$input_directory-LM-00-PSFTOF.bat";
    my $PSFTOF_script_copy_path = "$input_directory-LM-WB\\Run-04-$input_directory-LM-WB-PSFTOF.bat";

    open(my $PSFTOF_script_original, "<", $PSFTOF_script_original_path) or die "";
    open(my $PSFTOF_script_copy, ">", $PSFTOF_script_copy_path) or die "";

    while(my $line = <$PSFTOF_script_original>){
        if ($line_count == 14){
            my $line_header= "set cmd= %cmd% -u";
            my $file_1 = "$input_directory-LM-WB-umap.mhdr";
            my $file_2 = "$input_directory-LM-WB-umapBedRemoval.mhdr";
            print $PSFTOF_script_copy "$line_header $file_1,$file_2\n";
        } elsif ($line_count == 21) {
            my $line_header = "set cmd= %cmd% --ol";
            print $PSFTOF_script_copy "$line_header\n";
        } elsif ($line_count == 29) {
            my $line_header = "set cmd= %cmd% -e";
			my $cwd = getcwd;
            $cwd =~ tr/\//\\/;
            my $file_1 = "$cwd\\$input_directory-LM-WB\\$input_directory-LM-WB-sino.mhdr";
            print $PSFTOF_script_copy "$line_header $file_1\n";
        } elsif ($line_count == 30) {
            my $line_header = "set cmd= %cmd% --oi";
            my $file_1 = "$input_directory-LM-WB-PSFTOF.mhdr";
            print $PSFTOF_script_copy "$line_header $file_1\n";
		} elsif ($line_count == 31) {
            #Do nothing
        } elsif ($line_count == 33) {
            #Do nothing
        } elsif ($line_count == 34) {
            #Do nothing
		} elsif ($line_count == 35) {
            #Do nothing
        } elsif ($line_count == 36) {
            my $line_header = "pushd";
            my $cwd = getcwd;
            $cwd =~ tr/\//\\/;
            my $file_1 = "$cwd\\$input_directory-LM-WB";
            print $PSFTOF_script_copy "$line_header \"$file_1\"\n";
		} elsif ($line_count == 37) {
            #Do nothing
        } elsif ($line_count == 39) {
            my $lines_to_be_printed = "";
            for(my $i=0; $i < $dircounter; $i++){
                $lines_to_be_printed = "$lines_to_be_printed%cmd% --mat ($i,0,0) --app\n";
            }
            print $PSFTOF_script_copy "$lines_to_be_printed\n";
        } else {
            print $PSFTOF_script_copy "$line";
        }
        $line_count++;
    }
    close($PSFTOF_script_original);
    close($PSFTOF_script_copy);

    #Copy IF2Dicom script
    $line_count = 0;
    my $IF2Dicom_script_original_path = "$input_directory-LM-00\\Run-05-$input_directory-LM-00-IF2Dicom.bat";
    my $IF2Dicom_script_copy_path     = "$input_directory-LM-WB\\Run-05-$input_directory-LM-WB-IF2Dicom.bat";

    open(my $IF2Dicom_script_original, "<", $IF2Dicom_script_original_path) or die "";
    open(my $IF2Dicom_script_copy, ">", $IF2Dicom_script_copy_path) or die "";

    while(my $line = <$IF2Dicom_script_original>){
        if ($line_count == 7){
            my $line_header = "pushd";
            my $cwd = getcwd;
            $cwd =~ tr/\//\\/;
            my $file_1 = "$cwd\\$input_directory-LM-WB";
            print $IF2Dicom_script_copy "$line_header \"$file_1\"\n";
        } elsif ($line_count == 9) {
            my $line_header = "for %%x in (*ctm.v.hdr) do cscript C:\\JSRecon12\\IF2Dicom.js %%x";
            my $cwd = getcwd;
            $cwd =~ tr/\//\\/;
            my $file_1 = "$cwd\\$input_directory-LM-WB\\Run-05-$input_directory-LM-WB-IF2Dicom.txt";
            print $IF2Dicom_script_copy "$line_header \"$file_1\"\n";
        } else {
            print $IF2Dicom_script_copy "$line";
        }
        $line_count++;
    }
    close($IF2Dicom_script_original);
    close($IF2Dicom_script_copy);

    #Copy IF2Dicom Text File
    $line_count = 0;
    my $IF2Dicom_text_original_path = "$input_directory-LM-00\\Run-05-$input_directory-LM-00-IF2Dicom.txt";
    my $IF2Dicom_text_copy_path = "$input_directory-LM-WB\\Run-05-$input_directory-LM-WB-IF2Dicom.txt";

    open(my $IF2Dicom_text_original, "<", $IF2Dicom_text_original_path) or die "";
    open(my $IF2Dicom_text_copy, ">", $IF2Dicom_text_copy_path) or die "";

    while(my $line = <$IF2Dicom_text_original>){
        if ($line =~ /xx_Patient_Name/) {
            my @nameline = split(':=', $line);
            $nameline[@nameline-1] = "$input_directory";
            print $IF2Dicom_text_copy join(':= ', @nameline)."\n";
        } else {
            print $IF2Dicom_text_copy "$line";
        }
    }
    close($IF2Dicom_text_original);
    close($IF2Dicom_text_copy);

    #Done copying Scripts
    #Running LM WB make umap
    system("$input_directory-LM-WB\\Run-01-$input_directory-LM-WB-Makeumap.bat");
    
    #Reconstructing Image
    system("$input_directory-LM-WB\\Run-04-$input_directory-LM-WB-PSFTOF.bat");
    #Running LM WB IF2Diom.bat
    system("$input_directory-LM-WB\\Run-05-$input_directory-LM-WB-IF2Dicom.bat");
    #Finallizing
    chdir("..");
}

if (scalar(@ARGV) == 1) {
    handleprogram($ARGV[0]);
} elsif (scalar(@ARGV) == 2) {
    #Handle program -r
    if ($ARGV[1] == "-r") {
        opendir my $dir, $ARGV[0] or die "Input must be a directroy";  
        chdir($ARGV[0]) or die "Input must be directory!\n";
        my $active_Process_counter = 0;
        my @subdirectories = readdir($dir);
        foreach ( @subdirectories ){
            handleprogram($_);
        }
        
    }
        
}




#exit 0;
