
#@ File (style="directory", value="C:source/folder/volumes_EndWith.tif and ROI_set.zip") Source
#@ String (value="_EndWith.tif") Files_End_With
requires("1.33s"); 
Source += "/";

close('*'); //close it

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
	if (endsWith(path, Files_End_With)) {
		name = File.getName(path);
		nameWithoutExtension = File.getNameWithoutExtension(path);
		open(path);
		
		run("Analyze Skeleton (2D/3D)", "prune=none calculate show display");
		
		selectWindow("Branch information");
		saveAs("Results", Source + nameWithoutExtension + "_BranchInfo.csv");
		run("Close");
		
		selectWindow("Results");
		saveAs("Results", Source + nameWithoutExtension + "_results.csv");
		run("Close");

		close('*'); //close it
	}
}




  


