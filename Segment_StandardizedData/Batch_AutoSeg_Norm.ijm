// get Clij2 macro extension going
run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");
setBatchMode(false);

saveSettings();
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");

/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ File (label = "Classifier directory", style = "directory") classifierFolder

// imageInputFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_ManualLabelling/14/";
// outputImageFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_ManualLabelling/14_output/";
// imageFile = "norm-C2-Crop-2-20220314-14-1-001-0.tif";

// classifierFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_AutomaticLabelling/Ch2/";

// TODO: load corresponding matching channels
// TODO: combine channels
// TODO: segment combined channel with different classifier
// TODO: create measurements - area all, area inner, area fraction, intensity inner, intensity outer

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i], classifierFolder);
	}
}

function processFile(imageInputFolder, outputImageFolder, imageFile, classifierFolder) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("InputFolder: " + imageInputFolder);
	print("Processing: " + imageFile);
	print("Saving to: " + outputImageFolder);
	
	// classifierCh2Name = "/Ch2/norm-C2-Crop-1-20220201-14-1-002-0.classifier";
	// classifierCh3or4Name = "/Ch3or4/norm-C4-Crop-1-20220201-14-1-002-0.classifier";
	classifierCh2Name = "/Ch2/norm-C2-Crop-2-20220314-21-8-000-0.classifier";
	classifierCh3or4Name = "/Ch3or4/norm-C4-Crop-2-20220314-21-8-000-0.classifier";
	
	// open crop
	run("Bio-Formats Importer", 
		"open=" + imageInputFolder + File.separator + imageFile + 
		" autoscale" + 
		" color_mode=Default" +
		" rois_import=[ROI manager]" +
		" view=Hyperstack" +
		" stack_order=XYCZT");
	
	// read out file names
	imageTitle = getTitle();
	fileNameWO = File.getNameWithoutExtension(imageInputFolder + File.separator + imageFile );
	
	// decide on classifier names
	stringArrray = split(fileNameWO, "-");
	
	if (stringArrray[1] == "C2") {
		
		print("Detected channel 2");
		classifierName = classifierCh2Name;
		
		
	} else if (stringArrray[1] == "C3") {
		
		print("Detected channel 3");
		classifierName = classifierCh3or4Name;
		
	} else if (stringArrray[1] == "C4") {
		
		print("Detected channel 4");
		classifierName = classifierCh3or4Name;
		
	}
	
	print("Classifier set to: " + classifierName); 
		
	// get meta data
	getVoxelSize(width, height, depth, unit);
	voxelMicron = width * height * depth;
	
	// segment map2 inner region
	print("Segment map2 channel");
	selectImage(imageTitle);
	
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierFolder + File.separator + classifierName +
		" use_gpu=true");
		
	segResult = getTitle();
	
	run("Manual Threshold...", "min=1 max=1");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
	
	maskedResult = getTitle();
	
	saveAs("Tiff", outputImageFolder + File.separator + "Mask_" + fileNameWO);
	close("Mask_" + fileNameWO + ".tif");
	close(segResult);
	close(imageTitle);
}
