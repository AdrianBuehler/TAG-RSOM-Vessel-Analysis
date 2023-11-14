
#@ File (style="directory", value="C:source/folder/volumes_EndWith.tif and ROI_set.zip") Source
#@ String (value="_EndWith.tif") Files_2_Cut_End_With
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
  	if (endsWith(path, Files_2_Cut_End_With) && File.exists(Output + File.getName(path)) == false) {
		
		if (endsWith(path, "_Simple Segmentation.tif") == false) {
			print("Script only works with Ilastiks simpleseg");
			exit;
		}

		original = replace(path, "_Simple Segmentation", "");
		open(original);
		rename("original");
		name = getTitle();
		nameWithoutExtension = File.getNameWithoutExtension(original);
		
		open(path);
		run("8-bit");
		rename("seg");
		
		run("Invert");
		run("Subtract...", "value=253");
		run("Multiply...", "value=255");
		
//////////////////////////////////////////////////////////
		run("Duplicate...", "duplicate");
		rename("image1");


		// Skeleton
		selectImage("image1");
		run("Skeletonize (2D/3D)");
		open(replace(path, "_Simple Segmentation.tif", ".roi"));
		run("Clear Outside");
		run("Select None");
		selectImage("image1");
		

//////////////////////////////////////////////////////////
		rename("sceleton_tmp");
		run("Concatenate...", "open image1=original image2=seg image3=sceleton_tmp");
		rename("imageStack_1");
	
		
				
		
// ***************************************************************
		// Make Montage
		Stack.getDimensions(width, height, channels, slices, frames);
		run("Make Montage...", "columns=1 rows="+frames+" scale=1");
		rename("imageStack_Montage");
		run("Enhance Contrast", "saturated=0.35");
		run("Enhance Contrast", "saturated=0.35");
		run("Enhance Contrast", "saturated=0.35");
		run("Fire");
		
// ***************************************************************
		// Label
		folderP = split(Output, "\\");
		folder = folderP[folderP.length - 1];
		selectImage("imageStack_Montage");
		fontsize = 10;
		getDimensions(width, height, channels, slices, frames);
		setForegroundColor(255, 255, 255);
		setColor("Black");
		fillRect(0, 0, 140, fontsize);
		run("Select None");
		selectImage("imageStack_Montage");
		setFont("SansSerif", fontsize, " antialiased");
		setColor("white");
		drawString(folder + " " + nameWithoutExtension, 0, fontsize);
		
		run("Set Scale...", "distance=1 known=20 unit=mm");
		run("Scale Bar...", "width=1000 height=1000 thickness=2 font=10 background=Black location=[Lower Left] overlay");
		
		
// ***************************************************************
		// Save
		saveAs("PNG", Output + nameWithoutExtension);
		
		close("ROI Manager");
		close("*");
  	}
}










