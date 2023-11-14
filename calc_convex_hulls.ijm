//
// This script is used for calculation convex huls of components for perimeter-to-area ratio
//
// Input is 2D skeletonized images
//


#@ File (style="directory", value="C:source/folder/_Probability.tif") Source
#@ String (value=".tif") Files_2_Cut_End_With

requires("1.33s"); 
Source += File.separator;

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
		name = getTitle();
		run("Analyze Skeleton (2D/3D)", "prune=none calculate show display");
		close("Branch information");
		close("Results");
		selectImage(replace(name, ".tif", "")+"-labeled-skeletons");
		run("8-bit");
		run("Properties...", "channels=1 slices=1 frames=1 pixel_width=20 pixel_height=20 voxel_depth=20");
		name = getTitle();
		nameWithoutExtension = File.getNameWithoutExtension(path);
		getDimensions(width, height, channels, slices, frames);
		for (i = 0; i < 255; i++) {
			selectImage(name);
			run("Duplicate...", "title=tmp");
			hit = false;
			for (x = 0; x < width; x++) {
				for (y = 0; y < height; y++) {
					if (getPixel(x, y) != i) {
						setPixel(x, y, 0);
					} else {
						hit = true;
					}
				}
			}
			if (hit) {
				run("Subtract...", "value="+(i-1));
				run("Multiply...", "value=255");
				run("Create Selection");
				run("Convex Hull");
				run("Set Measurements...", "area redirect=None decimal=4");
				run("Measure");
			}
			close("tmp");
		}
		saveAs("Results", Source + nameWithoutExtension + "_convex_hulls.csv");
		run("Close");
		close("*");
  	}
}



