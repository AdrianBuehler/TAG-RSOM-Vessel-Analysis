//
// This script is used for skeletonasitation of colon vessels in TAG-RSOM of mice
//
// Input is 2D images
//
// Use 11-33MHz range
//
// Old name of this script was 3_AVG2Skelet_Moments_AnalPart_close.ijm
//


#@ File (style="directory", value="C:source/folder/_Probability.tif") Source
#@ String (value=".tif") Files_2_Cut_End_With
#@ File (style="directory", value="C:source/folder/skeletons.tif") Output

requires("1.33s"); 
Source += File.separator;
Output += File.separator;

setBatchMode(true); // suppress the displaying of images
count = 0;
countFiles(Source); // get number of files in dir and safe in count
n = 0;
processFiles(Source);
setBackgroundColor(0, 0, 0);


function countFiles(Source) {
	list = getFileList(Source);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")) {
			countFiles(""+Source+list[i]);
		} else {
			count++;
		}
	}
}

function processFiles(Source) {
	list = getFileList(Source);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")){
			processFiles(""+Source+list[i]);
		} else {
			showProgress(n++, count);
			path = Source+list[i];
			processFile(path);
		}
	}
}

function processFile(path) {
  	if (endsWith(path, Files_2_Cut_End_With)) {
		open(path);
		run("8-bit");
		name = getTitle();
		nameWithoutExtension = File.getNameWithoutExtension(path);
		if (endsWith(nameWithoutExtension, "_Simple Segmentation") == false) {
			print("Script only works with Ilastiks simpleseg");
			exit;
		}
		nameWithoutExtension = replace(nameWithoutExtension, "_Simple Segmentation", "");
		
		run("Invert");
		run("Subtract...", "value=253");
		run("Multiply...", "value=255");
		rename(name);
		run("Duplicate...", "duplicate range=1-1");
		rename("segmentedImage");
		selectImage(name);
		
		// Median Filter to remove impuls noise
		run("Median...", "radius=2");
		
		// Measure VesselArea AND area
		run("Set Measurements...", "area area_fraction redirect=None decimal=0");
		open(replace(path, "_Simple Segmentation.tif", ".roi"));
		run("Measure");
		selectWindow("Results");
		saveAs("Results", Output + nameWithoutExtension + "_vesselArea.csv");
		close("Results");
		run("Select None");
				

		// Skeleton
		selectImage(name);
		run("Skeletonize (2D/3D)");
		open(replace(path, "_Simple Segmentation.tif", ".roi"));
		run("Clear Outside");
		run("Select None");
		selectImage(name);
		saveAs("TIF", Output + nameWithoutExtension);
		rename("skeleton");
		
		// Save distance table
		selectImage("segmentedImage");
		run("Geometry to Distance Map", "threshold=128");
		rename("distanceMap");
		imageCalculator("AND create 32-bit", "distanceMap","skeleton");
		
		getHistogram(values, counts, 100);
		getHistogram(values, counts, 100, 0, 100);
		Table.create("Histo");
		Table.setColumn("Distance", values);
		Table.setColumn("Count", counts);

		saveAs("Results", Output + nameWithoutExtension + "_vesselThickness.csv");
		run("Close");
		close("*");
  	}
}




