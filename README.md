# TAG-RSOM-Vessel-Analysis

This pipeline enables the quantification of colon vessels in mice imaged with TAG-RSOM and is associated with the study: (AUTHOR, TITLE, JOURNAL, YEAR, DOI)

## Requirements for running the code

This software uses the ImageJ distribution Fiji (https://imagej.net/software/fiji/downloads) and Jupyter (https://jupyter.org/install).

## Pipeline

1.  Organize your reconstructed volumes.tif in a source folder.
2.  Run `preprocessing_and_segmentation.ijm` in Fiji and save output in a folder "Processed".
3.  Run `analyse_segmentations.ijm` in Fiji and save output in a folder "Analysis".
4.  Run `descriptors_calculation.ipynb`



