// This macro expects segmented images and a analysis-area-file (.roi). Files should be placed in one in "Segmentation" folder 


#@ File (style="directory", value="C:/Segmentation") source
#@ File (style="directory", value="C:/Analysis") output
#@ Boolean (label="Ignore existing measurements", value=false) ignres

requires("1.52o");
setBatchMode(true);
OUTPUT = output + File.separator;
SOURCE = source + File.separator;

// Suffixes
SEG_IMG_SUF = "_Segmented.tif";
ROI_SUF = ".roi"
// Results
BRANCH_RES_SUF = "_BranchInfo.csv";
SKEL_RES_SUF = "_Skeleton.csv";
AREA_RES_SUF = "_SegmentedArea.csv";
DM_RES_SUF = "_DistanceMap.csv";
BC_RES_SUF = "_BoxCount.csv";


main();


function main() {
	// Get file list
	imgs = getFileList(SOURCE);
	for (i = lengthOf(imgs)-1; i >= 0; i--) {
		if (endsWith(imgs[i], "_Segmented.tif") == false) {
			imgs = Array.deleteIndex(imgs, i);
		} else {
			imgs[i] = replace(imgs[i], "_Segmented.tif", "");
		}
	}
	
	// Process files
	for (i = 0; i < lengthOf(imgs); i++) {
   		print("Processing " + imgs[i]);
    	
    	// Calc res
		if (File.exists(OUTPUT+imgs[i]+SKEL_RES_SUF) == false || ignres) {
			analyse(imgs[i]);
		} 
	}
	close("Log");
}

function analyse(img) {
	open(SOURCE + img + SEG_IMG_SUF);
	open(SOURCE + img + ROI_SUF);
	
	// Measure segmented vessel area AND analysis area
	run("Set Measurements...", "area area_fraction redirect=None decimal=0");
	run("Measure");
	selectWindow("Results");
	saveAs("Results", OUTPUT + img + AREA_RES_SUF);
	close("Results");
	run("Select None");
	
	// Skeletonize
	selectImage(img + SEG_IMG_SUF);
	run("Skeletonize (2D/3D)");
	open(SOURCE + img + ROI_SUF);
	run("Clear Outside");
	run("Select None");
	rename("skeleton");
	
	// Save distance table
	open(SOURCE + img + SEG_IMG_SUF);
	open(SOURCE + img + ROI_SUF);
	run("Clear Outside");
	run("Select None");
	run("Geometry to Distance Map", "threshold=128");
	rename("distanceMap");
	imageCalculator("AND create 32-bit", "distanceMap", "skeleton");
	close("distanceMap");
	rename("distanceMap_skeleton");
	
	getHistogram(values, counts, 100);
	getHistogram(values, counts, 100, 0, 100);
	Table.create("Histogram_DistanceMap");
	Table.setColumn("Distance", values);
	Table.setColumn("Count", counts);
	saveAs("Results", OUTPUT + img + DM_RES_SUF);
	close(img + DM_RES_SUF);
	close("distanceMap_skeleton");
	close(img + SEG_IMG_SUF);
	
	// Analyse skeleton
	run("Analyze Skeleton (2D/3D)", "prune=none calculate show display");
	close(getTitle());close(getTitle());close(getTitle());
	
	selectWindow("Branch information");
	saveAs("Results", OUTPUT + img + BRANCH_RES_SUF);
	run("Close");
	
	selectWindow("Results");
	saveAs("Results", OUTPUT + img + SKEL_RES_SUF);
	run("Close");
	
	
	selectImage("skeleton");
	run("Fractal Box Count...", "box=2,3,4,6,8,12,16,32,64 black");
	saveAs("Results", OUTPUT + img + BC_RES_SUF);
	close("Plot");
	close("Results");
	
	close("skeleton");
}




