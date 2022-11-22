// get Clij2 macro extension going
run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");
setBatchMode(false);

saveSettings();
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");
// Note: using Clij looses Metadata!
// Note: keep classifier order consistent when generating a new classifier
// this determines the value of the mask in the segmentation
// TODO: some images don't close >> saved as .tif files

#@ File (label = "Image input directory", style = "directory") imageInputFolder
#@ File (label = "Output directory", style = "directory") output
#@ File (label = "Classifier input directory", style = "directory") classifierFolder
#@ String (label = "File suffix", value = ".tif") suffix

//imageInputFolder = "/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/AutomaticLabelling/";
//imageFile = "Crop-1-20220201-14-1-002-0.tif"; 
//output = "/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/test_output/"

// ------------------------------------------------------------------------------------
processFolder(imageInputFolder);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, classifierFolder, output, list[i]);
	}
}

// ------------------------------------------------------------------------------------
function processFile(imageInputFolder, classifierFolder, output, imageFile) {

	print(imageFile);
	classifierCh2Name = "/Ch2/C2-Crop-1-20220201-14-1-002-0.classifier";
	classifierCh3or4Name = "/Ch3or4/C4-Crop-1-20220201-14-1-002-0.classifier";
	classifierEntireOrganoidName = "/CombinedCh2Ch3or4/C2-C4-Crop1-20220201-14-1-002-0.classifier";
	
	// open crop
	run("Bio-Formats Importer", 
			"open=" + imageInputFolder + File.separator + imageFile + 
			" autoscale" + 
			" color_mode=Default" +
			" rois_import=[ROI manager]" +
			" view=Hyperstack" +
			" stack_order=XYCZT");
			
			
	stackName = getTitle();
	fileNameWO = File.getNameWithoutExtension(imageInputFolder + File.separator + imageFile );
	selectImage(stackName);
	rename(fileNameWO);
		
	// get meta data
	getVoxelSize(width, height, depth, unit);
	voxelMicron = width * height * depth;
	
	selectWindow(fileNameWO);
	run("Split Channels");
	
	// ---------------------------------------------------------
	stringArrray = split(fileNameWO, "-");
	
	if (stringArrray[1] == 1) {
		
		print("Set 1 detected");
		dapi = 1;
		map2 = 2;
		extra = 3;
		sox2 = 4;
	
		dapiChannel = "C" + dapi + "-" + fileNameWO;
		map2Channel = "C" + map2 + "-" + fileNameWO;
		extraChannel = "C" + extra + "-" + fileNameWO;
		sox2Channel = "C" + sox2 + "-" + fileNameWO;
	
		close(dapiChannel);
		close(extraChannel);
		
	} else if (stringArrray[1] == 2) {
		
		print("Set 2 detected");
		dapi = 1;
		map2 = 2;
		extra = 3;
		sox2 = 4;
		pax6 = 5;
	
		dapiChannel = "C" + dapi + "-" + fileNameWO;
		map2Channel = "C" + map2 + "-" + fileNameWO;
		extraChannel = "C" + extra + "-" + fileNameWO;
		sox2Channel = "C" + sox2 + "-" + fileNameWO;
		pax6Channel = "C" + pax6 + "-" + fileNameWO;
	
		close(dapiChannel);
		close(extraChannel);
		close(pax6Channel);
		
	} else if (stringArrray[1] == 3) {
		
		print("Set 3 detected");
		dapi = 1;
		map2 = 2;
		sox2 = 3;
		pax6 = 4;
	
		dapiChannel = "C" + dapi + "-" + fileNameWO;
		map2Channel = "C" + map2 + "-" + fileNameWO;
		sox2Channel = "C" + sox2 + "-" + fileNameWO;
		pax6Channel = "C" + pax6 + "-" + fileNameWO;
	
		close(dapiChannel);
		close(pax6Channel);
		
	} else {
		
		print("Error: sets not recognized");
		
	}

	
	// ===================================================================
	// Segmentation
	imageCalculator("Add create 32-bit stack", map2Channel, sox2Channel);
	map2AndSox2 = "map2AndSox2-Crop-" + fileNameWO;
	rename(map2AndSox2);
	
	// segment entire prganoid
	print("Segment entire organoid");
	selectImage(map2AndSox2);
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierFolder + File.separator + classifierEntireOrganoidName +
		" use_gpu=true");
		
	run("Manual Threshold...", "min=1 max=1");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
	
	map2AndSox2MaskName = "map2AndSox2-mask-" + fileNameWO;
	rename(map2AndSox2MaskName);
	
	print("Measure if segmentation was successful");
	run("Set Measurements...", "mean redirect=None decimal=3");
	selectImage(map2AndSox2MaskName);
	run("Z Project...", "projection=[Max Intensity]");
	selectImage("MAX_" + map2AndSox2MaskName);
	run("Measure");
	checkMask = getResultString("Mean", 0);
	run("Clear Results");
	close("MAX_" + map2AndSox2MaskName);
	
	if (checkMask > 0) {
		
		print("Found segmentation");
		run("Keep Largest Region");
		close(map2AndSox2MaskName);
	
		selectImage(map2AndSox2MaskName + "-largest");
		rename(map2AndSox2MaskName);
	
		run("Fill Holes", "stack");
		run("Divide...", "value=255.000 stack");
		
	} else {
		
		print("Warning: no segmentation");
		
	}
	
	close("segmentation of " + map2AndSox2);
	
	// segment map2 inner region
	print("Segment map2 channel");
	selectImage(map2Channel);
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierFolder + File.separator + classifierCh2Name +
		" use_gpu=true");
	
	run("Manual Threshold...", "min=1 max=1");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
	
	map2MaskName = "map2-mask-" + fileNameWO;
	rename(map2MaskName);
	
	print("Measure if segmentation was successful");
	run("Set Measurements...", "mean redirect=None decimal=3");
	selectImage(map2MaskName);
	run("Z Project...", "projection=[Max Intensity]");
	selectImage("MAX_" + map2MaskName);
	run("Measure");
	checkMask = getResultString("Mean", 0);
	run("Clear Results");
	close("MAX_" + map2MaskName);
	
	if (checkMask > 0) {
		
		print("Found segmentation");
		run("Keep Largest Region");
		close(map2MaskName);
	
		selectImage(map2MaskName + "-largest");
		rename(map2MaskName);
	
		run("Fill Holes", "stack");
		run("Divide...", "value=255.000 stack");
		
	} else {
		
		print("Warning: no segmentation");
		
	}
	
	close("segmentation of " + map2Channel);
	
	// segment sox2 inner region
	print("Segment sox2 channel");
	selectImage(sox2Channel);
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierFolder + File.separator + classifierCh3or4Name +
		" use_gpu=true");
	
	// create maks inner region sox2
	run("Manual Threshold...", "min=1 max=1");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Default background=Dark black");
	
	sox2MaskName = "sox2-mask-" + fileNameWO;
	rename(sox2MaskName);

	print("Measure if segmentation was successful");
	run("Set Measurements...", "mean redirect=None decimal=3");
	selectImage(sox2MaskName);
	run("Z Project...", "projection=[Max Intensity]");
	selectImage("MAX_" + sox2MaskName);
	// Todo: project then measure
	run("Measure");
	checkMask = getResultString("Mean", 0);
	run("Clear Results");
	close("MAX_" + sox2MaskName);
	
	if (checkMask > 0) {
		
		run("Keep Largest Region");
		close(sox2MaskName);
	
		selectImage(sox2MaskName + "-largest");
		rename(sox2MaskName);
	
		run("Fill Holes", "stack");
		run("Divide...", "value=255.000 stack");
		
	} else {
		
		print("Warning: no segmentation");
		
	}
	
	close("segmentation of " + sox2Channel);
	
	// ===================================================================
	// Measurements
	clij_map2AndSox2MaskName = map2AndSox2MaskName;
	Ext.CLIJ2_push(clij_map2AndSox2MaskName);
	
	Ext.CLIJ2_countNonZeroPixels(clij_map2AndSox2MaskName);
	areaTotalOrganoid = getResult("CountNonZero", 0);
	run("Clear Results");
	
	Ext.CLIJ2_release(clij_map2AndSox2MaskName);
	
	clij_map2Channel = map2Channel;
	Ext.CLIJ2_push(clij_map2Channel);
	
	clij_map2Mask = map2MaskName;
	Ext.CLIJ2_push(clij_map2Mask);
	
	// mean intensity of strong signal in channel 2
	Ext.CLIJ2_meanOfMaskedPixels(clij_map2Channel, clij_map2Mask);
	meanIntMap2 = getResult("Masked_mean", 0);
	run("Clear Results");
	Ext.CLIJ2_release(clij_map2Channel);
		
	Ext.CLIJ2_countNonZeroPixels(clij_map2Mask);
	areaMap2 = getResult("CountNonZero", 0);
	run("Clear Results");
	
	clij_sox2Channel = sox2Channel;
	Ext.CLIJ2_push(clij_sox2Channel);
	
	clij_sox2Mask = sox2MaskName;
	Ext.CLIJ2_push(clij_sox2Mask);
	
	// mean intensity of strong signal in channel 2
	Ext.CLIJ2_meanOfMaskedPixels(clij_sox2Channel, clij_sox2Mask);
	meanIntSox2 = getResult("Masked_mean", 0);
	run("Clear Results");
	Ext.CLIJ2_release(clij_sox2Channel);
		
	Ext.CLIJ2_countNonZeroPixels(clij_sox2Mask);
	areaSox2 = getResult("CountNonZero", 0);
	run("Clear Results");
	
	// dice index
	Ext.CLIJ2_sorensenDiceCoefficient(clij_map2Mask, clij_sox2Mask);
	diceMap2Sox2 = getResult("Sorensen_Dice_coefficient", 0);
	run("Clear Results");
		
	overlapImage = "binary_intersection-" + fileNameWO;
	Ext.CLIJ2_binaryIntersection(clij_map2Mask, clij_sox2Mask, overlapImage );
		
	Ext.CLIJ2_countNonZeroPixels(overlapImage);
	areaOverlap = getResult("CountNonZero", 0);
	run("Clear Results");
	
	// clean up results
	Ext.CLIJ2_release(clij_map2Mask);
	Ext.CLIJ2_release(clij_sox2Mask);
	Ext.CLIJ2_release(overlapImage);
	
	
	// ---------------------------------------------------------
	// collect results
	Table.create("Measurements");
	Table.set("TotalpxVolume", 0, areaTotalOrganoid);
	Table.set("TotalVolume", 0, areaTotalOrganoid * voxelMicron);
	Table.set("MeanIntMap2", 0, meanIntMap2);
	Table.set("SizePxMap2", 0, areaMap2);
	Table.set("SizeMicronMap2", 0, areaMap2 * voxelMicron);
	Table.set("MeanIntSox2", 0, meanIntSox2);
	Table.set("SizePxSox2", 0, areaSox2);
	Table.set("SizeMicronSox2", 0, areaSox2 * voxelMicron);
	Table.set("SizePxOverlap", 0, areaOverlap);
	Table.set("SizeOverlap", 0, areaOverlap * voxelMicron);
	Table.set("Dice", 0, diceMap2Sox2);
		
	Table.save(output + File.separator + fileNameWO + "_Meas.csv");
	
	// ===================================================================
	// visualize segmentation result total organoid
	selectImage(map2AndSox2);
	run("Enhance Contrast...", "saturated=0.35 process_all use");
	selectImage(map2AndSox2);
	run("8-bit");
	
	// TODO: implement a better strategy here
	selectImage(map2AndSox2);
	map2AndSox2_depth = bitDepth();
	
	if (map2AndSox2_depth == 32 ) {
		
		selectImage(map2AndSox2);
		run("8-bit");
		
	}
		
	run("Merge Channels...", "c2=" + map2AndSox2 + " c6=" + map2AndSox2MaskName + " create keep ignore");
	saveAs("Tiff", output + File.separator + fileNameWO + "_map2-sox2_Vis.tif");
	close(fileNameWO + "_map2-sox2_Vis.tif");
	
	close(map2AndSox2);
	close(map2AndSox2MaskName);
	
	// visualize segmentation result map2
	selectImage(map2Channel);
	run("Enhance Contrast...", "saturated=0.35 process_all use");
	selectImage(map2Channel);
	run("8-bit");
	
	// TODO: implement a better strategy here
	selectImage(map2Channel);
	map2Channel_depth = bitDepth();
	
	if (map2Channel_depth == 16 ) {
		
		selectImage(map2Channel);
		run("8-bit");
		
	}
		
	run("Merge Channels...", "c2=" + map2Channel + " c6=" + map2MaskName + " create keep ignore");
	saveAs("Tiff", output + File.separator + fileNameWO + "_map2_Vis.tif");
	close(fileNameWO + "_map2_Vis.tif");
	
	selectImage(map2MaskName);
	saveAs("Tiff", output + File.separator + fileNameWO + "_map2_Seg.tif");
	close(fileNameWO + "_map2_Seg.tif");
	
	close(map2Channel);
	
	// visualize segmentation result sox2
	selectImage(sox2Channel);
	run("Enhance Contrast...", "saturated=0.35 process_all use");
	selectImage(sox2Channel);
	run("8-bit");
	
	// TODO: implement a better strategy here
	selectImage(sox2Channel);
	sox2Channel_depth = bitDepth();
	
	if (sox2Channel_depth == 16 ) {
		
		selectImage(sox2Channel);
		run("8-bit");
		
	}
		
	run("Merge Channels...", "c2=" +  sox2Channel + " c6=" + sox2MaskName + " create keep ignore");
	saveAs("Tiff", output+ File.separator + fileNameWO + "_sox2_Vis.tif");
	close(fileNameWO + "_sox2_Vis.tif");
	
	selectImage(sox2MaskName);
	saveAs("Tiff", output + File.separator + fileNameWO + "_sox2_Seg.tif");
	close(fileNameWO + "_sox2_Seg.tif");
	
	close(sox2Channel);
	
	// clean up
	close("Measurements");
	close("Results");
	run("Collect Garbage");
	Ext.CLIJ2_clear();
	
}

restoreSettings;
