// inputFolder = "/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/1stExp/";
// inputFolder = "/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/CreateCrops/1stExp/";
#@ File (label = "Input directory", style = "directory") inputFolder
#@ File (label = "Output directory", style = "directory") outputFolder

// inputFile = "1_002.tif";
suffix = ".nd2";

// params
roiAddOn = 10; // add to ROI in px
subtractBackground = 500; // based on maximum projected and all channels added
sigma = 10;
thresholdMethod = "Huang";
sizeFilter = "50000-Infinity";
circFilter = "0.00-1.00";

// batch 
processFolder(inputFolder);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, outputFolder, list[i]);
	}
}


function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);

	run("Bio-Formats Importer", "open=" + input + File.separator + file + " autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	
	imageName = getTitle();
	
	// get set number
	dirString = File.getParent(input + File.separator + file);
	dirArray = split(dirString, File.separator);
	dirArrayLength = dirArray.length - 3;
	baseDir = dirArray[dirArrayLength];
	
	setArray = split(baseDir, File.separator);
	setString = setArray[0];
	setStringArray = split(setString, "rd");
	setNumberOld = setStringArray[0];
	
	dirArrayLengthDate = dirArray.length - 2;
	date = dirArray[dirArrayLengthDate];
	
	daysArrayLength = dirArray.length - 1;
	days = dirArray[daysArrayLength];
	daysArray = split(days, "_");
	daysString = daysArray[0];
	
	setNumber = setNumberOld + "-" + date + "-" + daysString;
	
	// get name number
	fileString = File.getNameWithoutExtension(input + File.separator + file);
	fileArray = split(fileString, "_");
	fileNumber = fileArray[0];
	
	// get name index
	fileIndexArray = split(fileArray[1] , ".");
	fileIndex = fileIndexArray[0];
	
	// generate z projection
	selectImage(imageName);
	run("Z Project...", "projection=[Max Intensity]");
	saveAs("Tiff", outputFolder + File.separator + "MAX-" + setNumber + "-" + fileNumber + "-" + fileIndex + ".tif");
	
	projectionName = "Proj-" + imageName;
	rename(projectionName);
	
	// add channels for segmentation
	run("Split Channels");
	imageCalculator("Add create", "C1-" + projectionName,"C2-" + projectionName);
	addResultOne = getTitle();
	
	imageCalculator("Add create", addResultOne,"C3-" + projectionName);
	addResultTwo = getTitle();
	
	imageCalculator("Add create", addResultTwo,"C4-" + projectionName);
	addResultThree = getTitle();
	
	close(addResultOne);
	close(addResultTwo);
	close("C1-" + projectionName);
	close("C2-" + projectionName);
	close("C3-" + projectionName);
	close("C4-" + projectionName);
	close("C5-" + projectionName);
	
	// create segmentations
	selectImage(addResultThree);
	run("Subtract...", "value=" + subtractBackground );
	run("Gaussian Blur...", "sigma=" + sigma);
	run("Auto Threshold", "method=" + thresholdMethod + " white");
	run("Analyze Particles...", "size=" + sizeFilter + " circularity=" + circFilter + " add");
	
	// create measurements
	run("Set Measurements...", "area shape redirect=None decimal=3");
	roiManager("Deselect");
	roiManager("Measure");
	saveAs("Results", outputFolder + File.separator + "Results-" + setNumber + "-" + fileNumber + "-" + fileIndex + ".csv");
	close("Results");
	
	count = roiManager("count");
	
	for ( roi = 0; roi < count; roi++ ) {
		
		// get bounding box
		run("Set Measurements...", "bounding redirect=None decimal=3");
		roiManager("Select", roi);
		roiManager("Measure");
		
		// get bounding box params
		// adjust for pixel size
		getPixelSize(unit, pixelWidth, pixelHeight);
		
	 	xRoi = round( getResult("BX", 0) / pixelWidth );
	 	yRoi = round( getResult("BY", 0) / pixelWidth );
	 	wRoi = round( getResult("Width", 0) / pixelWidth );
	 	hRoi = round( getResult("Height", 0) / pixelWidth );
	 	
	 	close("Results");
	 	
	 	// enlarge bounding box
	 	xRoi_adjusted = xRoi - roiAddOn;
	 	
	 	if (xRoi_adjusted < 0 ) {
	 		
	 		xRoi_adjusted = 0;
	 		
	 	}
	 	
		yRoi_adjusted = yRoi - roiAddOn;
		
		if (yRoi_adjusted < 0 ) {
	 		
	 		yRoi_adjusted = 0;
	 		
	 	}
		
		wRoi_adjusted = wRoi + ( roiAddOn * 2 );
		hRoi_adjusted = hRoi + ( roiAddOn * 2 );
		
		roiManager("Show None");
		
		// crop enlarged bounding box
		selectImage(imageName);
		makeRectangle(xRoi_adjusted, yRoi_adjusted, wRoi_adjusted, hRoi_adjusted);
		run("Duplicate...", "duplicate");
		saveAs("Tiff", outputFolder + File.separator + "Crop-" + setNumber + "-" + fileNumber + "-" + fileIndex + "-" + roi + ".tif");
		close();
		
	}
	
	// save ROI
	roiManager("Deselect");
	roiManager("Save", outputFolder + File.separator + "RoiSet-" + setNumber + "-" + fileNumber + "-" + fileIndex + ".zip");
	roiManager("reset");
	
	close(addResultThree);
	close(imageName);

}