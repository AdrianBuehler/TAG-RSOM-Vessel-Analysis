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
		nameWithoutExtension = File.getNameWithoutExtension(path);
		run("Fractal Box Count...", "box=2,3,4,6,8,12,16,32,64 black");
		saveAs("Results", Source + nameWithoutExtension + "_box_count.csv");
		run("Close");
		close("*");
  	}
}



