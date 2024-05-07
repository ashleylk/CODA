This document contains instructions for using CODA (Kiemen, 
et al Nature Methods, 2022, code version 'update 12-13-2023) 
to segment tissue structures in H&E, generate coordinates of 
cell nuclei, and deconvolve Visium spots.

First, follow the protocol and scripts to segment the major
tissue structures and deconvolve the H&E image, as described
in https://zenodo.org/records/11130691

Given the results of the classification use the following
to determine nuclear coordinates, register the high-resolution
H&E image to the Visium H&E, and determine the number and 
identity of cells located within each Visium spot.

1. call "HE_cell_count_visium(pth)" to generate mask images
containing logical indices for each cellular nucleas detected
in the H&E image.