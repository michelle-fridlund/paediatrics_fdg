#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed 16 Feb 16:23 2022

@author: michellef

######################################
e7 tools fix
######################################
"""

import os
from shutil import copy, copytree
from pathlib import Path 
from tqdm import tqdm
import argparse

PARAMS_FILE = "C:\JSRecon12\LMChopper64\LMChopper_params.txt"

def change_params(pct):
    with open(PARAMS_FILE, "r") as f:
        params = f.read()
    
    print pct
    params= re.sub("Retain\ +:=\ +[0-9]+", "Retain    := %s" % pct, params)

    with open(PARAMS_FILE, "w") as f:
        f.write(params)