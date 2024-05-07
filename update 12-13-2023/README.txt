CODA is a computational pipeline for creation of 3D tissue and cellular 
labelled datasets from serial histological datasets.
First published in Kiemen et al (nature methods, 2022)
https://www.nature.com/articles/s41592-022-01650-9

This package enables:
 1. serial image registration
 2. deep learning segmenation of structures recognizable in biological images
 3. nuclear coordinate generation and validation
 4. 3D reconstruction of tissue and cellular matrices

For a detailed guide and companion sample dataset, please see the Kiemen lab website:
https://labs.pathology.jhu.edu/kiemen/coda-3d/

Provided below is a brief shorthand for application of CODA. 

1. To downsample ndpi or svs images to 10x, 5x, and 1x tifs:
	create_downsampled_tif_images() 
	or try Openslide in python

2. To calculate registration on the low resolution (1x) images
	Calculate the tissue area and background pixels:
		calculate_tissue_ws()

	Calculate the registration transforms:
		calculate_image_registration()

3. To build a 3D tissue volume using sematic segmentation:
	First, generate manual annotations in Aperio imagescope

	Second, apply the deep learning function to train a model and segment the high resolution (5x or 10x) images:
		train_image_segmentation()

	To apply the registration to segmented images:
		apply_image_registration()

	To build a 3D tissue matrix from registered, classified images:
		build_tissue_volume()

4. To build a 3D cell volume containing nuclear coordinates:
	Build a mosaic image containing regions of many whole-slide images for cell detection optimization:
		make_cell_detection_mosaic()

	Manually annotate the mosaic image to get the ‘ground-truth’ number of cell nuclei:
		manual_cell_count()

	Determine cell detection parameters using the manual annotations on the mosaic image:
		get_nuclear_detection_parameters()

	Deconvolve the high-resolution (5x or 10x) H&E images before applying the cell detection algorithm:
		deconvolve_histological_images()

	Detect cells on the hematoxylin channel of the high-resolution images:
		cell_detection()

	Apply the registration to the cell coordinates:
		register_cell_coordinates()

	Build a 3D cell coordinate matrix corresponding to the 3D tissue matrix:
		build_cell_volume()
