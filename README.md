# TAG-RSOM-Vessel-Analysis

This pipeline enables the quantification of colon vessels of mice imaged with TAG-RSOM. For a more detailed description read the work associated with this repository _Buehler et al. "In Vivo Assessment of Deep Vascular Patterns in Murine Colitis Using Optoacoustic Mesoscopic Imaging"_ published in _Advanced Science_ (DOI: 10.1002/advs.202404618).

## Requirements for running the code

This software uses the ImageJ distribution Fiji (https://imagej.net/software/fiji/downloads) and Jupyter (https://jupyter.org/install).

## How to:

1.  Organize reconstructed volumes.tif in a input folder. Data published in association with the mentioned publication can be found at https://doi.org/10.17863/CAM.110936 
2.  Run `main.ijm` in Fiji.
3.  Run `descriptors_calculation.ipynb` to fetch results and calculate descriptors.

