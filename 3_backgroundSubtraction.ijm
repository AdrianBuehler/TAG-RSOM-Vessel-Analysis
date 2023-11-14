#@ File (style="directory", value="C:source/folder/volumes_EndWith.tif and ROI_set.zip") Source
#@ String (value="_EndWith.tif") Files_End_With
#@ File (style="directory", value="C:source/folder/volumes_EndWith.tif and ROI_set.zip") Output
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
	if (endsWith(path, Files_End_With)) {
		open(path);

		nameWithoutExtension = File.getNameWithoutExtension(path);

		run("Gaussian Blur...", "sigma=1");

		run("Subtract Background...", "rolling=10 sliding disable");
		//run("Subtract Background...", "rolling=20");
				
		run("8-bit");
		
		saveAs("TIF", Output + nameWithoutExtension + ".tif");

		close('*'); //close it
	}
}

