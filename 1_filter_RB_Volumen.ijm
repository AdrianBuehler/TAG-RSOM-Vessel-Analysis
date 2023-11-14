
#@ File (style="directory", value="C:source/folder/_Probability.tif") source
#@ File (style="directory", value="C:source/folder/skeletons.tif") output

setBatchMode(true);
close("*");

filelist = getFileList(source);

for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".tif")) {
  		open(source + File.separator + filelist[i]);
		run("Gaussian Blur 3D...", "x=3 y=3 z=3");
		run("Subtract Background...", "rolling=5 stack");
		saveAs("TIF", output + File.separator + filelist[i]);
        close('*');
    }
}



