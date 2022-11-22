setBatchMode(false);

// get Clij2 macro extension going
run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");

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
#@ File (label = "Measure directory", style = "directory") measInput

// imageInputFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_ManualLabelling/14/";
// outputImageFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_ManualLabelling/14_output/";
// imageFile = "norm-C2-Crop-2-20220314-14-1-001-0.tif";

// classifierFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_AutomaticLabelling/Ch2/";

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
			processFile(input, output, list[i], classifierFolder, measInput);
	}
}

function measureInt(measChannel, maskChannel) {
	
	measureImageGPU = measChannel;
	Ext.CLIJ2_push(measureImageGPU);
	
	maskImageGPU = maskChannel;
	Ext.CLIJ2_push(maskImageGPU );
	
	// mean intensity of strong signal in channel 2
	Ext.CLIJ2_meanOfMaskedPixels(measureImageGPU, maskImageGPU);
	meanIntResult = getResult("Masked_mean", 0);
	run("Clear Results");
	
	Ext.CLIJ2_release(measureImageGPU);
	Ext.CLIJ2_release(maskImageGPU);
	Ext.CLIJ2_clear();
	run("Collect Garbage");
	
	wait(2);
	
	return meanIntResult;
}

function processFile(imageInputFolder, outputImageFolder, imageFile, classifierFolder, measInput) {
	
	
	measEntireOrganoidMask = "NA";
	measMap2Mask = "NA";
	measSox2Mask = "NA";
	map2Sox2Overlap = "NA";
	diceMap2Sox2 = "NA";
	meanInnerMap2Map2 = "NA";
	meanInnerSox2Sox2 = "NA";
	meanOuterMap2Map2 = "NA";
	meanOuterSox2Sox2 = "NA";
	meanInnerSox2Map2 = "NA";
	meanOuterSox2Map2 = "NA";
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("InputFolder: " + imageInputFolder);
	print("Processing: " + imageFile);
	print("Saving to: " + outputImageFolder);
	
	// TODO: select classifier based on TP
	//classifierAllName = "/CombinedCh2Ch3or4/C1-norm-Crop-1-20220201-14-1-002-0.classifier";
	//classifierCh2Name = "/Ch2/norm-C2-Crop-1-20220201-14-1-002-0.classifier";
	//classifierCh3or4Name = "/Ch3or4/norm-C4-Crop-1-20220201-14-1-002-0.classifier";
	classifierAllName = "/CombinedCh2Ch3or4/C1-norm-Crop-2-20220314-21-8-000-0.classifier";
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
		
		
	imageTitle = getTitle();
	imageName = File.nameWithoutExtension;
	
	run("Split Channels");
	
	// get meta data
	getVoxelSize(width, height, depth, unit);
	voxelMicron = width * height * depth;
	
	
	// --- segment all organoid ----------------------------------------------------
	selectImage("C1-" + imageTitle);
	
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierFolder + File.separator + classifierAllName +
		" use_gpu=true");
		
	maskAllName = "Mask-C1-" + imageTitle;
	rename(maskAllName);
	
	selectImage(maskAllName);
	run("Manual Threshold...", "min=1 max=2");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
	
	// --- check if mask is empty ---------------------------------------------
	selectImage("MASK_" + maskAllName);
	run("Z Project...", "projection=[Max Intensity]");
	selectImage("MAX_MASK_" + maskAllName);
	run("Measure");
	checkMaskAll = getResultString("Mean", 0);
	run("Clear Results");
	close("MAX_MASK_" + maskAllName);
	
	if (checkMaskAll > 0) {
	
		selectImage("MASK_" + maskAllName);
		run("Keep Largest Region");
		resultAllOrganoid = getTitle();
		close("MASK_" + maskAllName);

		} else {
		
		print("Warning: no segmentation");
		resultAllOrganoid = "MASK_" + maskAllName;
		
	}
	
	close("C1-" + imageTitle);
	close(maskAllName);
	
	resultAllOrganoidGPU = resultAllOrganoid;
	Ext.CLIJ2_push(resultAllOrganoidGPU);
	
	// pixel count of entire organoid
	Ext.CLIJ2_countNonZeroPixels(resultAllOrganoidGPU);
	measEntireOrganoidMask = getResult("CountNonZero", 0);
	run("Clear Results");
	Ext.CLIJ2_release(resultAllOrganoidGPU);
	Ext.CLIJ2_clear();
	run("Collect Garbage");
	
	print("Segmented the entire organoid");
	Ext.CLIJ2_reportMemory();
	
	// --- segment map2 ------------------------------------------------------------
	selectImage("C2-" + imageTitle);
	
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierFolder + File.separator + classifierCh2Name +
		" use_gpu=true");
	
	maskMap2Name = "Mask-C2-" + imageTitle;
	rename(maskMap2Name);
	
	selectImage(maskMap2Name);
	run("Manual Threshold...", "min=1 max=1");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
	
	// --- check if mask is empty ---------------------------------------------
	selectImage("MASK_" + maskMap2Name);
	run("Z Project...", "projection=[Max Intensity]");
	selectImage("MAX_MASK_" + maskMap2Name);
	run("Measure");
	checkMaskMap2 = getResultString("Mean", 0);
	run("Clear Results");
	close("MAX_MASK_" + maskMap2Name);
	
	if (checkMaskMap2 > 0) {
	
		selectImage("MASK_" + maskMap2Name);
		run("Keep Largest Region");
		resultMap2 = getTitle();
		close("MASK_" + maskMap2Name);

		} else {
		
		print("Warning: no segmentation");
		resultMap2 = "MASK_" + maskMap2Name;
		
	}
	
	close("C2-" + imageTitle);
	close(maskMap2Name);
	
	resultMap2GPU = resultMap2;
	Ext.CLIJ2_push(resultMap2GPU);
	
	// pixel cond of strong mask
	Ext.CLIJ2_countNonZeroPixels(resultMap2GPU);
	measMap2Mask = getResult("CountNonZero", 0);
	run("Clear Results");
	
	// --- segment sox2 ------------------------------------------------------------
	selectImage("C3-" + imageTitle);
	
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierFolder + File.separator + classifierCh3or4Name +
		" use_gpu=true");
	
	maskSox2Name = "Mask-C3-" + imageTitle;
	rename(maskSox2Name);
	
	selectImage(maskSox2Name);
	run("Manual Threshold...", "min=1 max=1");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");

	// --- check if mask is empty ---------------------------------------------
	selectImage("MASK_" + maskSox2Name);
	run("Z Project...", "projection=[Max Intensity]");
	selectImage("MAX_MASK_" + maskSox2Name);
	run("Measure");
	checkMaskSox2 = getResultString("Mean", 0);
	run("Clear Results");
	close("MAX_MASK_" + maskSox2Name);
	
	if (checkMaskSox2 > 0) {
	
		selectImage("MASK_" + maskSox2Name);
		run("Keep Largest Region");
		resultSox2 = getTitle();
		close("MASK_" + maskSox2Name);

		} else {
		
		print("Warning: no segmentation");
		resultSox2 = "MASK_" + maskSox2Name;
		
	}
	
	close("C3-" + imageTitle);
	close(maskSox2Name);
	
	resultSox2GPU = resultSox2;
	Ext.CLIJ2_push(resultSox2GPU);
	
	// pixel count of strong mask
	Ext.CLIJ2_countNonZeroPixels(resultSox2GPU);
	measSox2Mask = getResult("CountNonZero", 0);
	run("Clear Results");
	
	// dice index
	Ext.CLIJ2_sorensenDiceCoefficient(resultMap2GPU, resultSox2GPU);
	diceMap2Sox2 = getResult("Sorensen_Dice_coefficient", 0);
	run("Clear Results");
	
	// intersection in px
	intersection = "binary_intersection";
	Ext.CLIJ2_binaryIntersection(resultMap2GPU, resultSox2GPU, intersection);
	
	Ext.CLIJ2_countNonZeroPixels(intersection);
	map2Sox2Overlap = getResult("CountNonZero", 0);
	run("Clear Results");
	
	Ext.CLIJ2_release(resultMap2GPU);
	Ext.CLIJ2_release(resultSox2GPU);
	Ext.CLIJ2_clear();
	run("Collect Garbage");
	
	// --- outer regions ------------------------------------------------------------
	// create map2 and sox2 outer regions
	imageCalculator("Subtract create stack", 
	resultAllOrganoid,
	resultMap2);
	
	outerResultMap2 = "Outer_" + resultMap2;
	rename(outerResultMap2);
	
	imageCalculator("Subtract create stack", 
	resultAllOrganoid,
	resultSox2);
	
	outerResultSox2 = "Outer_" + resultSox2;
	rename(outerResultSox2);
	
	// --- measure in original image ------------------------------------------------------------
	measureImageNameArray = split(imageName, "(norm-)");
	measureImageName = measureImageNameArray[1] + ".tif";
	
	run("Bio-Formats Importer", 
		"open=" + measInput + File.separator + measureImageName + 
		" autoscale" + 
		" color_mode=Default" +
		" rois_import=[ROI manager]" +
		" view=Hyperstack" +
		" stack_order=XYCZT");
	
	run("Split Channels");
	
	// ---------------------------------------------------------
	stringArrray = split(imageName, "-");
	
	if (stringArrray[2] == 1) {
		
		print("Set 1 detected");
		dapi = 1;
		map2 = 2;
		extra = 3;
		sox2 = 4;
	
		measDapiChannel = "C" + dapi + "-" + measureImageName;
		measMap2Channel = "C" + map2 + "-" + measureImageName;
		measExtraChannel = "C" + extra + "-" + measureImageName;
		measSox2Channel = "C" + sox2 + "-" + measureImageName;
	
		close(measDapiChannel);
		close(measExtraChannel);
		
	} else if (stringArrray[2] == 2) {
		
		print("Set 2 detected");
		dapi = 1;
		map2 = 2;
		extra = 3;
		sox2 = 4;
		pax6 = 5;
		
		measDapiChannel = "C" + dapi + "-" + measureImageName;
		measMap2Channel = "C" + map2 + "-" + measureImageName;
		measExtraChannel = "C" + extra + "-" + measureImageName;
		measSox2Channel = "C" + sox2 + "-" + measureImageName;
		measPax6Channel = "C" + pax6 + "-" + measureImageName;
	
		close(measDapiChannel);
		close(measExtraChannel);
		close(measPax6Channel);
		
	} else if (stringArrray[2] == 3) {
		
		print("Set 3 detected");
		dapi = 1;
		map2 = 2;
		sox2 = 3;
		pax6 = 4;
	
		measDapiChannel = "C" + dapi + "-" + measureImageName;
		measMap2Channel = "C" + map2 + "-" + measureImageName;
		measSox2Channel = "C" + sox2 + "-" + measureImageName;
		measPax6Channel = "C" + pax6 + "-" + measureImageName;
	
		close(measDapiChannel);
		close(measPax6Channel);
		
	} else {
		
		print("Error: sets not recognized");
		
	}
	
	
	// --- Measure Inner Map2 in Map2 ---------------------------------------------------------
	meanInnerMap2Map2 = measureInt(measMap2Channel, resultMap2);
	meanInnerSox2Sox2 = measureInt(measSox2Channel, resultSox2);
	
	meanOuterMap2Map2 = measureInt(measMap2Channel, outerResultMap2);
	meanOuterSox2Sox2 = measureInt(measSox2Channel, outerResultSox2);
	
	meanInnerSox2Map2 = measureInt(measMap2Channel, resultSox2);
	meanOuterSox2Map2 = measureInt(measMap2Channel, outerResultSox2);

	// --- collect results ---------------------------------------------------------
	// collect results
	Table.create("Measurements");
	Table.set("VoxelSize", 0, voxelMicron);
	Table.set("TotalpxVolume", 0, measEntireOrganoidMask);
	Table.set("SizePxMap2", 0, measMap2Mask);
	Table.set("SizePxSox2", 0, measSox2Mask);
	Table.set("OverlapPx", 0, map2Sox2Overlap);
	Table.set("Dice", 0, diceMap2Sox2);
	Table.set("meanInnerMap2Map2", 0, meanInnerMap2Map2);
	Table.set("meanInnerSox2Sox2", 0, meanInnerSox2Sox2);
	Table.set("meanInnerSox2Map2", 0, meanInnerSox2Map2);
	Table.set("meanOuterMap2Map2", 0, meanOuterMap2Map2);
	Table.set("meanOuterSox2Sox2", 0, meanOuterSox2Sox2);
	Table.set("meanOuterSox2Map2", 0, meanOuterSox2Map2);
	
	Table.save(output + File.separator + measureImageName + "_Meas.csv");

	// --- segmentation results ---------------------------------------------------------
	// TODO: save segmentation results
	// TODO: save measurements
	// saveAs("Tiff", outputImageFolder + File.separator + "Mask_" + fileNameWO);
	selectImage(resultMap2);
	run("8-bit");
	
	selectImage(resultSox2);
	run("8-bit");
	
	selectImage(resultAllOrganoid);
	run("8-bit");
	
	selectImage(measMap2Channel);
	run("8-bit");
	
	selectImage(measSox2Channel);
	run("8-bit");
	
	run("Merge Channels...", "c2=" + resultAllOrganoid + " c4=" + resultMap2 + " c5=" + resultSox2 + " c6=" + measMap2Channel + " c7=" + measSox2Channel + " keep create");
	
	selectImage("Composite");
	saveAs("Tiff", output + File.separator + imageName + ".tif");
	close(imageName + ".tif");
	
	// --- close images ---------------------------------------------------------
	close(measMap2Channel);
	close(measSox2Channel);
	close(resultAllOrganoid);
	close(resultMap2);
	close(resultSox2);
	close(outerResultMap2);
	close(outerResultSox2);
	
	// --- clean up tables ---------------------------------------------------------
	close("Measurements");
	close("Results");
	run("Collect Garbage");
	Ext.CLIJ2_clear();
	
	print("End processing of " + measureImageName);
	Ext.CLIJ2_reportMemory();
	
}
