#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed 9 Jun 12:37 2021

@author: michellef

######################################
PREPARE Rb82 DATA
######################################
"""
from tqdm import tqdm
from pprint import pprint
import argparse
import dicom2nifti
import nibabel as nib
from pathlib import Path
import numpy as np
import glob
import os
import re
import pandas as pd
import time

start_time = time.time()  # script start time


# Return every second element
def second_el(a):
    return a[::2]


# Parse lowercase
def lower_(b):
    return b.lower()


# Create parser
def parse_bool(b):
    b = b.lower()
    if b == 'true':
        return True
    elif b == 'false':
        return False
    else:
        raise ValueError('Cannot parse string into boolean.')


# Interquartile range of an array
def get_iqr(vals):
    from scipy.stats import iqr
    my_iqr = iqr(vals, rng=(25, 95))
    print(f'IQR value is: {my_iqr}')
    return my_iqr


# Find all nifti files in a directory
def find_nii(path_):
    return [n for n in glob.glob("{}/*.nii.gz".format(path_), recursive=True)]


# Transform DICOMS into numpy
def nifti2numpy(nifti):
    try:
        d_type = nifti.header.get_data_dtype()  # Extract data type from nifti header
        return np.array(nifti.get_fdata(), dtype=np.dtype(d_type))
    except:
        return None


# Convert a DICOM directry into a single nifti file
def dicom_to_nifti(input_, output_):
    if not os.path.exists(output_):
        os.makedirs(output_)
    dicom2nifti.convert_directory(input_, output_)


# Find paths to all patient directories
def find_patients(data_path):
    children = {}
    for (dirpath, dirnames, filnames) in os.walk(data_path):
        dirname = str(Path(dirpath).relative_to(data_path))
        if '_25' in dirname or '_100' in dirname:
            in_ = os.path.join(data_path, dirname)
            out_ = Path(in_).parent.absolute()
            # dictionary where keys are dcm paths and values are save paths
            children[in_] = str(out_)
    return children


def convert_(data_path):
    children = find_patients(data_path)
    for k, v in children.items():
        dicom_to_nifti(k, v)


# Rename all nifti files
def get_nifti(args):
    images = []
    children = find_patients(args.data_path)
    for k, v in children.items():
        # get list of niftis in a directory v
        nii = find_nii(v)
        for n in nii:
            images.append(n)
            base = os.path.basename(n)
            try:
                name_ = (re.search('3_(.*?)-lm', base)).group(1)
            except:
                continue
            new = f'{v}/{name_}.nii.gz'
            if args.rename == True:
                os.rename(n, new)
    return images


def get_numpy(args):
    data = {}
    dfs = []
    images = get_nifti(args)

    # From here on we only need the paths to full-dose files
    im_100 = []
    for i in images:
        if '_25' not in str(i):
            im_100.append(i)

    im_100 = second_el(im_100)

    # Limit number of patients
    if args.maxp:
        im_100 = im_100[0:args.maxp]
        pprint(im_100)
    # Create a list of pd per patient with names and pixel data
    for c, i in enumerate(im_100):
        df_ = f'df{c}'
        df_ = pd.DataFrame(columns=['patient', 'intensity'])
        im = nib.load(i)
        numpy_ = nifti2numpy(im)
        # Check for nan and inf
        if np.all(np.isnan(numpy_)) or np.all(np.isinf(numpy_)):
            print(f'NaN element in {os.path.basename(i)}')
        name = (re.search('(.*?)\.nii.gz', os.path.basename(i))).group(1)[0:4]
        # Flatten the array
        numpy_flat = numpy_.ravel()
        # Dictionary
        data[name] = numpy_flat
        # Panda df
        df_ = df_.append(
            {'patient': name, 'intensity': numpy_flat}, ignore_index=True)
        dfs.append(df_)

    if args.d_type == 'dict':
        print('OK')
        return data
    elif args.d_type == 'panda':
        return dfs
    else:
        print('Choose a valid data type.')


# Produce numerical and visual stats
def get_stats(args):
    dfs = get_numpy(args)
    keys = list(dfs.keys())
    vals = [dfs[k] for k in keys]

    # We need to ensure that our numpy arrays are of same dimension
    row_lengths = []

    for row in vals:
        row_lengths.append(len(row))

    pprint(row_lengths)
    max_length = max(row_lengths)
    pprint(max_length)
    # Add a None element if a given array is shorter thanthe maximal length
    for row in tqdm(vals):  # progress bar
        while len(row) < max_length:
            vals = np.append(vals, None)

    balanced_array = np.array(vals)
    my_iqr = get_iqr(balanced_array)

    t = start_time - time.time()

    # Write output to file and time the script
    with open('/homes/michellef/IQR.txt', 'w') as f:
        f.write(my_iqr)
        f.write('/n')
        f.write(f'Processing time: {t}')
    f.close()

    if args.plot:
        # import matplotlib.pyplot as plt
        # import seaborn as sns

        score_data = pd.concat(dfs)
        score_data = score_data.explode('intensity')
        score_data['intensity'] = score_data['intensity'].astype('float')
        # Remove 0.0 elements - not sure if require
        # score_data['data'].drop(score_data[score_data['data'] == 0.0].index, inplace=True)

        # s = sns.boxplot(data=score_data, x = 'intensity', y = 'patient')
        # s.set(xlim=(-1000, 5000))

        # plt.hist(vals, bins = 10, label = keys)
        # plt.legend()
        # plt.savefig('/homes/michellef/TEST.png')


if __name__ == "__main__":
    # Initiate the parser
    parser = argparse.ArgumentParser()
    required_args = parser.add_argument_group('required arguments')
    # Add long and short argument
    required_args.add_argument(
        "--data_path", dest='data_path', help="DICOM directory path", required=True)

    # Convert DICOM files or get stats
    required_args.add_argument(
        "--mode", help="convert/stats", required=True)

    # Output data type for stats
    required_args.add_argument(
        "--d_type", dest='d_type', help="dict/panda", type=lower_, required=True)

    # Option to rename nifti files
    parser.add_argument('--rename', dest='rename', type=parse_bool, default=False,
                        help="rename files: True/False")

    # Option to plot stats
    parser.add_argument('--plot', dest='plot', type=parse_bool, default=False,
                        help="plot stats: True/False")

    # Limit number of patient to process
    parser.add_argument('--maxp', dest='maxp', type=int,
                        help='maximum number of patient to process')

    # Read arguments from the command line
    args = parser.parse_args()
    data_path = args.data_path
    mode = str(args.mode)

    if not os.path.exists(data_path):
        raise 'Data source directory does not exist'

    if mode == 'convert':
        convert_(data_path)
    elif mode == 'stats':
        get_stats(args)
    else:
        get_numpy(args)

    print('Done.')
