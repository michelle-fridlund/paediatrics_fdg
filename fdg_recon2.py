#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed 16 Feb 16:23 2022

@author: michellef

######################################
PREPARE WB FDG DATA
######################################
"""

import os
from shutil import copy, copytree
from pathlib import Path 
from tqdm import tqdm
import argparse


save_dir = '/homes/michellef/my_projects/paediatrics_fdg/paediatrics_fdg_data/february2022'


#Returns .ptd files in the parsed directory
def find_LM(pt):
    p = Path(pt)
    ptds = []
    if not p.is_dir():
        return None
    for f in p.iterdir():
        if 'ptd' in f.name:
            ptds.append(str(f))
    return ptds


def find_files(args):
    dir_path = args.data
    patients = os.listdir(dir_path)
    file_dict = {}

    for p in patients:
        new_path = os.path.join(dir_path,p)
        LM = find_LM(new_path)
        file_dict[p] = LM
    
    return file_dict


def sort_recon_files(args):
    file_dict = find_files(args)
    patients = {}
 
    for p, filename in file_dict.items():
        patient = {
            'LISTMODE': [],
            'CALIBRATION': [],
        }

        for item in filename:
            if 'LISTMODE' in item or '.LM.' in item:
                patient['LISTMODE'].append(item)
            elif 'CALIBRATION' in item:
                patient['CALIBRATION'].append(item)

        patients[p] = patient

    return patients


def makedirs(save_path):
    if not os.path.exists(save_path):
        os.makedirs(save_path)


def copy_file(k, value, new_value):
    save_path = os.path.join(save_dir, k)
    makedirs(save_path)

    copy(value, os.path.join(save_path, new_value))


def copy_files(args):
    data_path = args.data
    patients = sort_recon_files(args)

    for k, v in patients.items():
        for count, value in enumerate(v['LISTMODE']):

            new_value = f'LM_{count}.ptd'
            copy_file(k, value, new_value)

        for count2, value2 in enumerate(v['CALIBRATION']):

            new_value2 = f'CALIBRATION_{count2}.ptd'
            copy_file(k, value2, new_value2)


def copy_ct(args):
    dir_path = args.data
    patients = os.listdir(dir_path)
    
    for p in tqdm(patients):
        input_ = os.path.join(dir_path, p, 'CT')
        output_ = os.path.join(save_dir, p, 'CT')
        #copytree(input_, output_)
        if not os.path.exists(output_):
            print(p)

            
if __name__ == "__main__":
    # Initiate the parsers
    parser = argparse.ArgumentParser()
    required_args = parser.add_argument_group('required arguments')

    parser.add_argument('--data', dest='data', type=str,
                        help="directory containing patient files")


    args = parser.parse_args()
    #copy_files(args)
    copy_ct(args)