# TAG-RSOM-Vessel-Analysis

This pipeline enables the quantification of colon vessels in mice imaged with TAG-RSOM. For a more detailed description read the work associated with this repository (AUTHOR, TITLE, JOURNAL, YEAR, DOI)

## Requirements for running the code

This software uses the ImageJ distribution Fiji (https://imagej.net/software/fiji/downloads) and Jupyter (https://jupyter.org/install).

## Pipeline

1.  Organize your reconstructed volumes.tif in a source folder.
2.  Run `preprocessing_and_segmentation.ijm` in Fiji and save output in a folder "Processed".
3.  Run `analyze_segmentations.ijm` in Fiji.
4.  Run `descriptors_calculation.ipynb` to fetch Fiji results and calculate descriptors.

<img src="example.png" alt="Murine colon vessels." width="100%" />




