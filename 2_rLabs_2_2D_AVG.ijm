//
// This script is used for cropping colon vessels in TAG-RSOM of mice
//

segment_size = 50; // Number of slices for MIPs to mark colon; lower number results in lower precision
crop_width = 100; // Modified!!!!!!

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
  		open(path);
  		
  		//	!	!	!	!	!	!	!
  		// NON FILTERED DATA
  		run("Reslice [/]...", "output=1.000 start=Left");
  		//  ;	;	;	;	;	;	;
  		
  		TheImage = getTitle();
  		
  		getDimensions(width, height, channels, slices, frames);
		nameWithoutExtension = File.getNameWithoutExtension(path);
		nameUnits = split(nameWithoutExtension, "_");
		name_results = nameUnits[0] + "_" + nameUnits[1] + "_" + nameUnits[2] + "_" + nameUnits[3] + "_segmentSize_" + segment_size + ".csv";
		
		
		// ****************************************************************************************************************
		// Get Coordinates in YZ-plane
		// ****************************************************************************************************************
		// Req: opened and selected source volume is TIF stack in YZ-plane
		
		// Check if an .csv with coordinates exist:
		if (File.exists(File.getDirectory(path) + name_results) == false) {
			// Side view for reference
			run("Duplicate...", "duplicate");
			rename("tmp");
			run("Reslice [/]...", "output=1.000 start=Right rotate");
			run("Z Project...", "projection=[Max Intensity]");
			rename("sideViewMIP");
			close("tmp");
			
			// First frame showing the MIP of first segments next to the side view
			selectImage(TheImage);
			n=slices/segment_size; // Number of segments
			run("Duplicate...", "duplicate range=1-" + segment_size);
			first_Segment = getTitle();
			run("Z Project...", "projection=[Max Intensity]");
			close(first_Segment);
			rename("maxStack");
			
			selectImage("sideViewMIP");
			run("Duplicate...", "duplicate");
			rename("sideViewMIP_forConcat");
			makeRectangle(0, 0, 2, height);
			run("Fill", "slice");
			makeRectangle(segment_size, 0, 2, height);
			run("Fill", "slice");
			run("Combine...", "stack1=[maxStack] stack2=[sideViewMIP_forConcat]");
			run("Fire");
			rename("maxStack");
			
			// Other frames showing segment MIPs
			for (i = 1; i <= n-1; i++) {
				selectImage(TheImage);
				run("Duplicate...", "duplicate range=" + segment_size*i+1 + "-" + segment_size*(i+1));
				rename("current_Segment");
				run("Z Project...", "projection=[Max Intensity]");
				rename("current_Segment_maxStack");
				close("current_Segment");
				
				
				selectImage("sideViewMIP");
				run("Duplicate...", "duplicate");
				rename("sideViewMIP_forConcat");
				makeRectangle(segment_size*i+1, 0, 2, height);
				run("Fill", "slice");
				makeRectangle(segment_size*(i+1), 0, 2, height);
				run("Fill", "slice");
				run("Combine...", "stack1=[current_Segment_maxStack] stack2=[sideViewMIP_forConcat]");
				rename("current_Segment_maxStack");
				run("Fire");
				run("Concatenate...", "image1=[maxStack] image2=[current_Segment_maxStack]");
				rename("maxStack");
			}
			close(TheImage);
			setTool("multipoint");
			setBatchMode(false);
			setLocation(0, 0);
			waitForUser("Get Coordinates for image: " + TheImage, "Use the multi-point tool to mark the cenit of the TAG right beneth the colon vessels FIRST and above SECOND.\nStart and end in the volume where vessels are distiguishable,\nbut no not scip slices in the range of the useable volume!");
			setBatchMode(true);
			run("Measure");
			close("maxStack");
		}
		
		
		
		
		// ****************************************************************************************************************
		// Interpolate the coordinates
		// ****************************************************************************************************************
		// Req: opened and selected Results containing coordinates
		
		
		if (File.exists(File.getDirectory(path) + name_results) == true) {
			open(File.getDirectory(path) + name_results);
			
			// ****** https://imagej.nih.gov/ij/macros/Import_Results_Table.txt *****************
			lineseparator = "\n";
 		    cellseparator = ",\t";
 		    lines=split(File.openAsString(File.getDirectory(path) + name_results), lineseparator);
		    labels=split(lines[0], cellseparator);
		    if (labels[0]==" ") k=1; // it is an ImageJ Results table, skip first column
  		   	else k=0; // it is not a Results table, load all columns
  		   	for (j=k; j<labels.length; j++) setResult(labels[j],0,0);
			// dispatches the data into the new RT
	 		run("Clear Results");
		    for (i=1; i<lines.length; i++) {
		       	items=split(lines[i], cellseparator);
		       	for (j=k; j<items.length; j++) setResult(labels[j],i-1,items[j]);
 		    }
		     updateResults();
		     // *********************************************************************************
		     close(name_results);
		}
		
		// Discard slices outside the used range
		marked_segments = newArray(0);
		x_Coordinates = newArray(0);
		y_Coordinates = newArray(0);
		x_upper_Coordinates = newArray(0);
		y_upper_Coordinates = newArray(0);
		
		// Check in number of upper and lower marks match:
		if (nResults() % 2 != 0) {
			if (nResults() == 1) {
				close('*');
				exit("Skiping hole volume is not implemented yet!");
			} else {
				close('*');
				exit("Number of upper and lower selected point do not match!");
			}
		}
		
		// fetch point from "Results"-table into arrays
		for (i = 0; i < nResults(); i++) {
			if (i % 2 == 0) {
				marked_segments[i/2] = getResult("Slice", i);
				x_Coordinates[i/2] = getResult("X", i);
				y_Coordinates[i/2] = getResult("Y", i);
			} else {
				x_upper_Coordinates[(i-1)/2] = getResult("X", i);
				y_upper_Coordinates[(i-1)/2] = getResult("Y", i);
			}
		}
		
		// Open an copy of the image with only relevant slices in the stack
  		open(path);
  		
  		//	!	!	!	!	!	!	!
  		// NON FILTERED DATA
  		run("Reslice [/]...", "output=1.000 start=Left");
  		//  ;	;	;	;	;	;	;
  		
  		TheImage = getTitle();
  		
  		run("Duplicate...", "duplicate range=" + (marked_segments[0]-1)*segment_size + "-" + marked_segments[marked_segments.length-1]*segment_size);
		close(TheImage);
		rename(TheImage);
  		
		// Check if the nessesary number of point per slice were selected
		isConsecutive = true;
		for (i = 0; i < marked_segments.length - 2; i++) {
			if (marked_segments[i] + 1 != marked_segments[i+1]) {
				isConsecutive = false;
				break;
			}
		}
		if (isConsecutive == false) {
			close('*');
			close("Results");
			run("Close All");
			exit("The numbers are not consecutive.");
		}
		
		// Interpolation of coordinates
		x_Coordinates = Array.resample(x_Coordinates, slices);
		y_Coordinates = Array.resample(y_Coordinates, slices);
		x_upper_Coordinates = Array.resample(x_upper_Coordinates, slices);
		y_upper_Coordinates = Array.resample(y_upper_Coordinates, slices);
		
		for (i = 0; i < segment_size; i++) {
			x_Coordinates[i] = x_Coordinates[segment_size];
			y_Coordinates[i] = y_Coordinates[segment_size];
			x_upper_Coordinates[i] = x_upper_Coordinates[segment_size];
			y_upper_Coordinates[i] = y_upper_Coordinates[segment_size];
		}
		
		
		// ****************************************************************************************************************
		// Crop volume
		// ****************************************************************************************************************

		selectWindow(TheImage);
		getDimensions(width, height, channels, slices, frames);
		newImage("template", "8-bit white", width, height, slices);
		for (i = 0; i < slices; i++) {
			selectWindow(TheImage);
			setSlice(i+1);
			makeOval(x_Coordinates[i]-60, y_Coordinates[i], 120, 450); // TAG has 30mm diameter -> lateral relution = 20 and lateral relution = 4 makeOval(170, 376, 30*4, 30*20 != 450, but 450 works better);
			run("Clear", "slice");
			makeRectangle(x_Coordinates[i]- (crop_width/2), 0, crop_width, y_Coordinates[i]+50);
			run("Clear Outside", "slice");
			makeOval(x_upper_Coordinates[i]-65, y_upper_Coordinates[i], 130, 400); // Cut above colon vessels
			run("Clear Outside", "slice");
			
			selectWindow("template");
			setSlice(i+1);
			makeOval(x_Coordinates[i]-60, y_Coordinates[i], 120, 450); // TAG has 30mm diameter -> lateral relution = 20 and lateral relution = 4 makeOval(170, 376, 30*4, 30*20 != 450, but 450 works better);
			run("Clear", "slice");
			makeRectangle(x_Coordinates[i]- (crop_width/2), 0, crop_width, y_Coordinates[i]+50);
			run("Clear Outside", "slice");
			makeOval(x_upper_Coordinates[i]-65, y_upper_Coordinates[i], 130, 400); // Cut above colon vessels
			run("Clear Outside", "slice");
		}		

		run("Select None");
		
			

		// ****************************************************************************************************************


		selectWindow(TheImage);
		run("Select None");
		
		// Max stack
		run("Reslice [/]...", "output=1.000 start=Top rotate");
		run("Z Project...", "projection=[Average Intensity]");
		run("8-bit");
		rename("image1");
		
		// Max stack
		selectWindow("template");
		run("Select None");
		run("Reslice [/]...", "output=1.000 start=Top rotate");
		run("Z Project...", "projection=[Average Intensity]");
		run("8-bit");
		rename("template2D");
		
		
		// Filtered
		selectWindow("template2D");
		run("Duplicate...", "duplicate");

		setOption("BlackBackground", true);
		setThreshold(1, 255);
		run("Convert to Mask");
		Stack.getDimensions(width, height, channels, slices, frames);
		run("Create Selection");
		roiManager("Add");
		roiManager("Select", 0);
		Roi.getBounds(xR, yR, widthR, heightR);
		roiManager("Deselect");
		roiManager("Delete");
		makeRectangle(0, yR, width, heightR);
		run("Duplicate...", "duplicate");
		run("Erode");run("Erode");run("Erode");run("Erode");run("Erode");run("Erode");run("Erode");run("Erode");run("Erode");run("Erode");
		run("Create Selection");
		roiManager("Add");
		roiManager("Select", 0);
		roiManager("Save", Output + nameWithoutExtension + ".roi");
		roiManager("Deselect");
		roiManager("Delete");
		run("Close");
		
		run("Select None");

		selectImage("image1");
		makeRectangle(0, yR, width, heightR);
		run("Duplicate...", "duplicate");

		saveAs("TIF", Output + nameWithoutExtension);
		
		
		
		if (File.exists(File.getDirectory(path) + name_results) == false) {
			selectWindow("Results");
			saveAs("Results", File.getDirectory(path) + name_results);
		}
		close("Results");
		close("*");
  	}
}







