// This macro expects volumes from TAG-RSOM imaging in tif.format with a voxel
// size of 20x20x4 µm^3 (XYZ). All volumes should be placed in one in a "source"
// folder 


#@ File (style="directory", value="C:/recon") source
#@ File (style="directory", value="C:/Segmentation") output
#@ Boolean (label="Ignore existing 3D filtered images", value=false) ignfilter
#@ Boolean (label="Redo manual cropping", value=false) ignapex
#@ Boolean (label="Ignore existing 2D projections", value=false) igncrop
#@ Boolean (label="Ignore existing segmentations", value=false) ignseg

requires("1.52o");
setBatchMode(true);
OUTPUT = output + File.separator;
SOURCE = source + File.separator;

// Suffixes
ORIGINAL_SUF = ".tif";
FILT3D_IMG_SUF = "_3DFiltered.tif";
ROI_SUF = ".roi"
PREPROC_IMG_SUF = "_Preprocessed.tif";
SEG_IMG_SUF = "_Segmented.tif";
APEX_RES_SUF = "_Apex.csv";

// Projection type
PROJ_TYPE = "Average Intensity"; // "Max Intensity"

//******************************************************************************
// MAGIC NUMBERS:
SEGMENT_SIZE = 50;
// voxelsize: 20x20x4; TAG diameter 3mm + safety margin = Magic Numbers
CIRCLE_TAG_X = 120;
CIRCLE_TAG_Y = 450;
// Magic Numbers for colon-tissue-interface
CIRCLE_TISSUE_X = 130;
CIRCLE_TISSUE_Y = 400;
CROP_WIDTH = 100;
CROP_HEIGHT = 50;
// Theta for FFT filter (degree)
THETA = 2;
//******************************************************************************


main();


function main() {
	// Get file list
	imgs = getFileList(SOURCE);
	for (i = lengthOf(imgs)-1; i >= 0; i--) {
		if (endsWith(imgs[i], ".tif") == false) {
			imgs = Array.deleteIndex(imgs, i);
		} else {
			imgs[i] = replace(imgs[i], ".tif", "");
		}
	}
	
	// Process files
	for (i = 0; i < lengthOf(imgs); i++) {
   		print("Processing " + imgs[i]);
   		// Filter volume
		if (File.exists(OUTPUT+imgs[i]+FILT3D_IMG_SUF) == false || ignfilter) {
			filter_3D_volume(imgs[i]);
		}
		
		// Get colon outline
		if (File.exists(OUTPUT+imgs[i]+APEX_RES_SUF) == false || ignapex) {
			get_apex_coordinates(imgs[i]);
		}
		
		// Crop volume and create 2D projection
		if (File.exists(OUTPUT+imgs[i]+ PREPROC_IMG_SUF) == false || 
			(igncrop || ignapex || ignfilter)) {
			crop_and_project_to2D(imgs[i]);
		}
		
		// Segment
		if (File.exists(OUTPUT+imgs[i]+ SEG_IMG_SUF) == false ||
			(ignseg || ignfilter || igncrop || ignapex)) {
			segment(imgs[i]);
		}
	}
	
	close("Log");
}

function filter_3D_volume(img){
	open(SOURCE + img + ORIGINAL_SUF);
	run("Gaussian Blur 3D...", "x=3 y=3 z=3");
	run("Subtract Background...", "rolling=5 stack");
	saveAs("TIF", OUTPUT + img + FILT3D_IMG_SUF);
   	close(img + FILT3D_IMG_SUF);
}

function get_apex_coordinates(img){
	open(OUTPUT + img + FILT3D_IMG_SUF);
  	run("Reslice [/]...", "output=1.000 start=Left");
  	rename("coronal_view");
	getDimensions(width, height, channels, slices, frames);
	n=slices/SEGMENT_SIZE; // Number of segments
  	close(img + FILT3D_IMG_SUF);
	
	// Side view for reference
	run("Duplicate...", "duplicate");
	rename("tmp");
	run("Reslice [/]...", "output=1.000 start=Right rotate");
	close("tmp");
	rename("tmp");
	run("Z Project...", "projection=[Max Intensity]");
	rename("sideViewMIPtemplate");
	close("tmp");
	
	// Other frames showing segment MIPs
	for (i = 0; i <= n-1; i++) {
		selectImage("coronal_view");
		run("Duplicate...",
			"duplicate range="+ SEGMENT_SIZE*i+1 + "-" + SEGMENT_SIZE*(i+1));
		rename("tmp");
		run("Z Project...", "projection=[Max Intensity]");
		close("tmp");
		rename("current_Segment");
		
		selectImage("sideViewMIPtemplate");
		run("Duplicate...", "duplicate");
		rename("sideViewMIP");
		makeRectangle(SEGMENT_SIZE*i+1, 0, 2, height);
		run("Fill", "slice");
		makeRectangle(SEGMENT_SIZE*(i+1), 0, 2, height);
		run("Fill", "slice");
		run("Combine...", "stack1=[current_Segment] stack2=[sideViewMIP]");
		rename("current_Segment_combined");
		if (i == 0) {
			rename("segmentstack");
		} else {
			run("Concatenate...",
				"image1=[segmentstack] image2=[current_Segment_combined]");
			rename("segmentstack");
		}
	}

	
	close("coronal_view");
	close("sideViewMIPtemplate");
	run("Fire");
	rename("MIPs of segments of size " + SEGMENT_SIZE + " of image " + img);
	setTool("multipoint");
	setBatchMode(false);
	setLocation(0, 0);
	waitForUser("Get apex coordinates for image: " + img,
		"Use the multi-point tool to set two marks on every frame starting "
		+ "with the first frame where the colon vessels are visible.\n"
		+ "The point marks the space between the TAG and the colon "
		+ "vessels. The second point seperates colon vessels from "
		+ "other tissue.\nDo not scip frames in the range of the "
		+ "useable volume!");
	setBatchMode(true);
	run("Measure");
	close("MIPs of segments of size " + SEGMENT_SIZE + " of image "	+ img);

//******************************************************************************
	
	// Check user input
	if (nResults() <= 1) {
		close("Results");
		exit("No apicies were selected.");
	} else if (nResults() % 2 != 0) {
		close("Results");
		exit("Number of points (colon-tissue and TAG-colon) don't match.");
	} else if (nResults() < 4) {
		close("Results");
		exit("More than one usable segment required."
			+ " (Alternative: reduce segment size)");
	}
	for (i = 0; i < nResults()-2; i++) {
		if (getResult("Slice", i) + 1 != getResult("Slice", i + 2)) {
			close("Results");
			exit("The numbers are not consecutive.");
		}
	}
	for (i = 0; i < nResults(); i=i+2) {
		if (getResult("Y", i) <= getResult("Y", i+1)) {
			close("Results");
			exit("Mark TAG-Colon-interface first");
		}
	}
	for (i = 0; i < nResults(); i++) {
		if (getResult("X", i) >= width) {
			close("Results");
			exit("Mark in the coronal plane (left).");
		}
	}
	
	
	
//******************************************************************************
	// Interpolate the coordinates

	// Convert table into array
	selectedssegments = newArray(0);
	x_TAG = newArray(0);
	y_TAG = newArray(0);
	x_tissue = newArray(0);
	y_tissue = newArray(0);
	for (i = 0; i < nResults(); i++) {
		if (i % 2 == 0) {
			selectedssegments[i/2] = getResult("Slice", i);
			x_TAG[i/2] = getResult("X", i);
			y_TAG[i/2] = getResult("Y", i);
		} else {
			x_tissue[(i-1)/2] = getResult("X", i);
			y_tissue[(i-1)/2] = getResult("Y", i);
		}
	}
	
	
	// Interpolation
	x_TAG = Array.resample(x_TAG, (nResults()/2)*SEGMENT_SIZE);
	y_TAG = Array.resample(y_TAG, (nResults()/2)*SEGMENT_SIZE);
	x_tissue = Array.resample(x_tissue, (nResults()/2)*SEGMENT_SIZE);
	y_tissue = Array.resample(y_tissue, (nResults()/2)*SEGMENT_SIZE);
		
	for (i = 0; i < SEGMENT_SIZE; i++) {
		x_TAG[i] = x_TAG[SEGMENT_SIZE];
		y_TAG[i] = y_TAG[SEGMENT_SIZE];
		x_tissue[i] = x_tissue[SEGMENT_SIZE];
		y_tissue[i] = y_tissue[SEGMENT_SIZE];
	}
	
	// Save coordinates
	start = newArray(1); start[0] = getResult("Slice", 1)-1;
	stop = newArray(1); stop[0] = getResult("Slice", nResults()-1)-1;
	ssize = newArray(1); ssize[0] = SEGMENT_SIZE;
	Table.create(img + APEX_RES_SUF);
	Table.setColumn("x", x_TAG);
	Table.setColumn("y", y_TAG);
	Table.setColumn("ux", x_tissue);
	Table.setColumn("uy", y_tissue);
	Table.setColumn("start", start);
	Table.setColumn("stop", stop);
	Table.setColumn("segsize", ssize);
	saveAs("Results", OUTPUT + img + APEX_RES_SUF);
	close(img + APEX_RES_SUF);
}


function crop_and_project_to2D(img) {
	open(OUTPUT + img + APEX_RES_SUF);
	open(OUTPUT + img + FILT3D_IMG_SUF);
	rename("fetch");
	run("Reslice [/]...", "output=1.000 start=Left");
	close("fetch");
	rename("fetch");
	run("Duplicate...", "duplicate range="
		+ getResult("start", 0)*getResult("segsize", 0) + "-"
		+ getResult("stop", 0)*getResult("segsize", 0));		
	close("fetch");
	rename("cropped_image");
	
	
	// Crop volume
	getDimensions(width, height, channels, slices, frames);
	// Apply to dummy to save presice outline (calculation internsive but works)
	newImage("dummy", "8-bit white", width, height, slices);
	for (i = 0; i < slices; i++) {
		setSlice(i+1);
		makeOval(getResult("x", i)-(CIRCLE_TAG_X/2), getResult("y", i),
			CIRCLE_TAG_X, CIRCLE_TAG_Y);
		run("Clear", "slice");
		makeRectangle(getResult("x", i)-(CROP_WIDTH/2), 0,
			CROP_WIDTH, getResult("y", i)+CROP_HEIGHT);
		run("Clear Outside", "slice");
		makeOval(getResult("ux", i)-(CIRCLE_TISSUE_X/2), getResult("uy", i),
			CIRCLE_TISSUE_X, CIRCLE_TISSUE_Y);
		run("Clear Outside", "slice");
	}
	selectWindow("dummy");
	run("Select None");

	// Get usable analysis area and save as .roi
	selectWindow("dummy");
	run("Reslice [/]...", "output=1.000 start=Top rotate");
	close("dummy");
	rename("fetch");
	run("Z Project...", "projection=["+PROJ_TYPE+"]");
	close("fetch");
	rename("dummy2D");
	run("8-bit");

	selectWindow("dummy2D");
	setOption("BlackBackground", true);
	setThreshold(1, 255);
	run("Convert to Mask");
	Stack.getDimensions(d2D_width, d2D_height, d2D_ch, d2D_s, d2D_f);
	run("Create Selection");
	roiManager("Add");
	roiManager("Select", 0);
	Roi.getBounds(xR, yR, widthR, heightR);
	roiManager("Deselect");
	roiManager("Delete");
	makeRectangle(0, yR, d2D_width, d2D_height);
	run("Duplicate...", "duplicate");
	close("dummy2D");
	rename("roi_template");
	for (i = 0; i < 10; i++) {run("Erode");}
	run("Create Selection");
	roiManager("Add");
	roiManager("Select", 0);
	roiManager("Save", OUTPUT + img + ROI_SUF);
	roiManager("Deselect");
	roiManager("Delete");
	close("roi_template");

	// Save 2D projection
	selectWindow("cropped_image");
	for (i = 0; i < slices; i++) {
		selectWindow("cropped_image");
		setSlice(i+1);
		makeOval(getResult("x", i)-(CIRCLE_TAG_X/2), getResult("y", i),
			CIRCLE_TAG_X, CIRCLE_TAG_Y);
		run("Clear", "slice");
		makeRectangle(getResult("x", i)-(CROP_WIDTH/2), 0,
			CROP_WIDTH, getResult("y", i)+CROP_HEIGHT);
		run("Clear Outside", "slice");
		makeOval(getResult("ux", i)-(CIRCLE_TISSUE_X/2), getResult("uy", i),
			CIRCLE_TISSUE_X, CIRCLE_TISSUE_Y);
		run("Clear Outside", "slice");
	}
	selectWindow("cropped_image");
	run("Select None");
	close(img + APEX_RES_SUF);
	close("ROI Manager");
	
	run("Reslice [/]...", "output=1.000 start=Top rotate");
	close("cropped_image");
	rename("fetch");
	run("Z Project...", "projection=["+PROJ_TYPE+"]");
	close("fetch");
	rename("fetch");
	run("8-bit");
	makeRectangle(0, yR, d2D_width, heightR);
	run("Duplicate...", "duplicate");
	close("fetch");	
	rename("fetch");	

/*
	// Filter in the FFT domain to eliminate horizontal line artefacts
	run("FFT");
	close("fetch");	
	rename("fetch_fft");
	getDimensions(w, h, ch, s, f);
	r = sqrt((w/2)*(w/2)+(w/2)*(w/2));
	makePolygon(w/2, w/2,
		w/2+r*cos((90+THETA)*-(PI/180)),w/2+r*sin((90+THETA)*-(PI/180)),
		1+w/2+r*cos((90-THETA)*-(PI/180)),w/2+r*sin((90-THETA)*-(PI/180)),
		w/2+1,w/2,
		1+w/2+r*cos((270+THETA)*-(PI/180)),w/2+r*sin((270+THETA)*-(PI/180)),
		w/2+r*cos((270-THETA)*-(PI/180)),w/2+r*sin((270-THETA)*-(PI/180)),
		w/2,w/2);
	run("Clear");
	run("Select None");
	run("Inverse FFT");
	close("fetch_fft");
	rename("fetch_ifft");
*/
	
	// remove BG
	run("Gaussian Blur...", "sigma=1");
	run("Subtract Background...", "rolling=10 sliding disable");
	
	// Save
	saveAs("TIF", OUTPUT + img + PREPROC_IMG_SUF);
	close(img + PREPROC_IMG_SUF);
}

function segment(img) {
	open(OUTPUT + img + PREPROC_IMG_SUF);

	// Frangi vesselness filter
	run("Frangi Vesselness", "input=" + img + PREPROC_IMG_SUF
		+ " dogauss=false spacingstring=[1, 1] scalestring=[2, 5]");
	close(img + PREPROC_IMG_SUF);
	rename("fetch");
	run("Duplicate...", "duplicate range=1-1");
	close("fetch");
	rename("filtered");
		
	// Segmented
	setOption("BlackBackground", true);
	setAutoThreshold("MinError dark");
	run("Convert to Mask");
	
	// Median Filter to remove impuls noise
	run("Median...", "radius=2");
	
	// Save
	saveAs("TIF", OUTPUT + img + SEG_IMG_SUF);
	close(img + SEG_IMG_SUF);
}




