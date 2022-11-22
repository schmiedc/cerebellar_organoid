run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");
setBatchMode(false);
// TODO: 
// optimize speed & memory management
//   as much as possible on GPU
//   reduce sending to and from GPU

// Note: using Clij looses Metadata!
// Note: keep classifier order consistent when generating a new classifier
// this determines the value of the mask in the segmentation

// TODO:
// Labkit optimization, improvement hints:
// Brightness and contrast must be normalized across images
// (Optional) background removal can improve results
// but important this needs to be consistent between model and input image!

/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Image input directory", style = "directory") input
#@ File (label = "Classifier input directory", style = "directory") inputClassifier
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix



//imageInputFolder = "/home/christopher.schmied/Desktop/HT_Docs/Projects/CerebralOrganoids_DA/Segmentation/input/"
// imageFile = "4B.nd2"
//imageFile = "7B002.nd2"

// classifierInputFolder = "/home/christopher.schmied/Desktop/HT_Docs/Projects/CerebralOrganoids_DA/Segmentation/classifier/"
// outputFolder = "/home/christopher.schmied/Desktop/HT_Docs/Projects/CerebralOrganoids_DA/Segmentation/output/"

// ------------------------------------------------------------------------------------
// User defined settings
// channel setting
dapi = 1;
map2 = 2;
pax6 = 3;
sox2 = 4;

// thresholding for crops
gaussSigma = 5;
cameraBackground = 205; // measured empirically
thresholdMethod = "Triangle";

// ------------------------------------------------------------------------------------
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, inputClassifier, output, list[i]);
	}
}



// ------------------------------------------------------------------------------------
function processFile(imageInputFolder, classifierInputFolder, outputFolder, imageFile) {
	
	ch2Classifier = "ch2classifier.classifier";
	ch3Classifier = "ch3classifier.classifier";
	ch2Andch3Classifier = "classifierC2AndCh3.classifier";

	run("Bio-Formats Importer", 
		"open=" + imageInputFolder + File.separator + imageFile + 
		" autoscale" + 
		" color_mode=Default" +
		" rois_import=[ROI manager]" +
		" view=Hyperstack" +
		" stack_order=XYCZT");
	
	stackName = getTitle();
	fileNameWO = File.getNameWithoutExtension(imageInputFolder + File.separator + imageFile );
	
	// get meta data
	getVoxelSize(width, height, depth, unit);
	voxelMicron = width * height * depth;
	
	dapiChannel = "C" + dapi + "-" + stackName;
	map2Channel = "C" + map2 + "-" + stackName;
	pax6Channel = "C" + pax6 + "-" + stackName;
	sox2Channel = "C" + sox2 + "-" + stackName;
	
	selectWindow(stackName);
	run("Split Channels");
	
	// TODO: check if always 4 channels
	selectWindow(sox2Channel );
	close();
	selectWindow(dapiChannel);
	close();
	
	// ---------------------------------------------------------
	// Segment organoids
	imageCalculator("Add create stack", map2Channel, pax6Channel);
	map2Andpax6 = "map2Andpax6-" + stackName;
	rename(map2Andpax6);
	
	run("Gaussian Blur...", "sigma=" + gaussSigma + " stack");
	run("Subtract...", "value=" + cameraBackground + " stack");
	// currently this overestimates the size of the organoid
	run("Auto Threshold", "method=" + thresholdMethod + " white stack use_stack_histogram");
	
	// ---------------------------------------------------------
	// crop organoids
	// TODO: make this work on multiple organoids in field of view
	run("Keep Largest Region");
	segResultClean = getTitle();
	close(map2Andpax6);
	
	// compute bounding box
	selectImage(segResultClean);
	run("Divide...", "value=255.000 stack");
	
	image17 = segResultClean;
	Ext.CLIJ2_push(image17);
	Ext.CLIJ2_getBoundingBox(image17, boundingBoxX, boundingBoxY, boundingBoxZ, boundingBoxWidth, boundingBoxHeight, boundingBoxDepth);
	Ext.CLIJ2_release(image17);
	close(segResultClean);
	
	// crop channel 2
	selectWindow(map2Channel);
	makeRectangle(boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight);
	run("Crop");
	
	// crop channel 3
	selectWindow(pax6Channel);
	makeRectangle(boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight);
	run("Crop");
	
	// ---------------------------------------------------------
	// entire organoid with labkit
	imageCalculator("Add create 32-bit stack", map2Channel, pax6Channel);
	map2Andpax6Crop = "map2Andpax6-Crop-" + stackName;
	rename(map2Andpax6Crop);
	
	selectImage(map2Andpax6Crop);
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierInputFolder + File.separator + ch2Andch3Classifier +
		" use_gpu=true");
		
	// need to set B/C to get correct 8-bit conversion
	setMinAndMax(0, 1);
	run("8-bit");
	saveAs("Tiff", outputFolder + File.separator + fileNameWO + "_map2Andpax6_Seg.tif");
	
	map2Andpax6SegName = "map2Andpax6-Seg-" + stackName;
	rename(map2Andpax6SegName);
	
	selectImage(map2Andpax6SegName);
	run("Manual Threshold...", "min=0 max=1");
	//setThreshold(0, 1);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");
	
	// ---------------------------------------------------------
	// segment map2 with labkit
	selectWindow(map2Channel);
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierInputFolder + File.separator + ch2Classifier +
		" use_gpu=true");
	
	// need to set B/C to get correct 8-bit conversion
	setMinAndMax(0, 2);
	run("8-bit");
	saveAs("Tiff", outputFolder + File.separator + fileNameWO + "_map2_Seg.tif");
	map2SegName = "map2-Seg-" + stackName;
	rename(map2SegName);
	
	selectImage(map2SegName);
	run("Duplicate...", "duplicate");
	map2SegName2 = "map2-Seg2-" + stackName;
	rename(map2SegName2);
	
	// threshold the strong signal
	selectImage(map2SegName);
	run("Manual Threshold...", "min=0 max=1");
	//setThreshold(0, 1);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");
	run("Divide...", "value=255.000 stack");
	
	// ---------------------------------------------------------
	// get outer region of the map2 signal masked
	selectImage(map2SegName2);
	run("Manual Threshold...", "min=128 max=128");
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");
	
	run("Invert LUT");

	image1Mask = map2Channel;
	Ext.CLIJ2_push(image1Mask);
	
	image2Mask = map2SegName2;
	Ext.CLIJ2_push(image2Mask);
	image3Mask = "mask_map2" + stackName;
	Ext.CLIJ2_mask(image1Mask , image2Mask, image3Mask);
	Ext.CLIJ2_pull(image3Mask);
	saveAs("Tiff", outputFolder + File.separator + fileNameWO + "_map2_Mask.tif");
	close();
	
	close(map2SegName2);
	close(image3Mask);
	Ext.CLIJ2_clear();
	run("Collect Garbage");
	// ---------------------------------------------------------
	// segment channel 3 with labkit
	selectWindow(pax6Channel);
	run("Segment Image With Labkit", 
		"segmenter_file=" + classifierInputFolder + File.separator + ch3Classifier +
		" use_gpu=true");
	
	// need to set B/C to get correct 8-bit conversion
	setMinAndMax(0, 2);
	run("8-bit");
	saveAs("Tiff", outputFolder + File.separator + fileNameWO + "_pax6_Seg.tif");
	pax6SegName = "pax6_Seg-" + stackName;
	rename(pax6SegName);
	
	// threshold the strong signal
	run("Manual Threshold...", "min=0 max=1");
	//setThreshold(0, 1);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");
	run("Divide...", "value=255.000 stack");
	
	// ---------------------------------------------------------
	// Measurement
	image1 = map2Channel;
	Ext.CLIJ2_push(image1);
	
	image2 = map2SegName;
	Ext.CLIJ2_push(image2);
	
	// only works for now if mask is 0/1
	// mean intensity of strong signal in channel 2
	Ext.CLIJ2_meanOfMaskedPixels(image1, image2);
	meanStrongCh2 = getResult("Masked_mean", 0);
	run("Clear Results");
	Ext.CLIJ2_release(image1);
	
	Ext.CLIJ2_countNonZeroPixels(image2);
	countStrongCh2 = getResult("CountNonZero", 0);
	run("Clear Results");
	
	image3 = pax6Channel;
	Ext.CLIJ2_push(image3);
	
	image4 = pax6SegName;
	Ext.CLIJ2_push(image4);
	
	// only works for now if mask is 0/1
	// mean intensity of strong signal in channel 3
	Ext.CLIJ2_meanOfMaskedPixels(image3, image4);
	meanStrongCh3 = getResult("Masked_mean", 0);
	run("Clear Results");
	
	Ext.CLIJ2_release(image3);
	
	// pixel cond of strong mask
	Ext.CLIJ2_countNonZeroPixels(image4);
	countStrongCh3 = getResult("CountNonZero", 0);
	run("Clear Results");
	
	// dice index
	Ext.CLIJ2_sorensenDiceCoefficient(image2, image4);
	diceStrong = getResult("Sorensen_Dice_coefficient", 0);
	run("Clear Results");
	
	image5 = "binary_intersection";
	Ext.CLIJ2_binaryIntersection(image2, image4, image5);
	
	Ext.CLIJ2_countNonZeroPixels(image5);
	countStrongOverlap = getResult("CountNonZero", 0);
	run("Clear Results");
	
	// clear images from gpu memory
	Ext.CLIJ2_release(image5);
	Ext.CLIJ2_release(image2);
	Ext.CLIJ2_release(image4);
	
	// measure total organoid volume
	image6 = map2Andpax6SegName;
	Ext.CLIJ2_push(image6);
	
	Ext.CLIJ2_countNonZeroPixels(image6);
	countTotalVolume = getResult("CountNonZero", 0);
	run("Clear Results");
	// relase images
	Ext.CLIJ2_release(image6);
	
	close("Results");
	// ---------------------------------------------------------
	// collect results
	Table.create("Measurements");
	Table.set("TotalpxVolume", 0, countTotalVolume);
	Table.set("TotalVolume", 0, countTotalVolume * voxelMicron);
	Table.set("MeanROICh2", 0, meanStrongCh2);
	Table.set("SizePxROICh2", 0, countStrongCh2);
	Table.set("SizeROICh2", 0, countStrongCh2 * voxelMicron);
	Table.set("MeanROICh3", 0, meanStrongCh3);
	Table.set("SizePxROICh3", 0, countStrongCh3);
	Table.set("SizeROICh3", 0, countStrongCh3 * voxelMicron);
	Table.set("SizePxOverlap", 0, countStrongOverlap);
	Table.set("SizeOverlap", 0, countStrongCh3 * voxelMicron);
	Table.set("Dice", 0, diceStrong);
	
	Table.save(outputFolder + File.separator + fileNameWO + "_Meas.csv");
	
	// ---------------------------------------------------------
	// Save result images
	selectImage(map2Andpax6Crop);
	run("Duplicate...", "duplicate");
	saveAs("Tiff", outputFolder + File.separator + fileNameWO +  "_map2-pax6_raw.tif");
	close();
	
	// visualize segmentation result
	selectImage(map2Andpax6Crop);
	run("Enhance Contrast...", "saturated=0.35 process_all use");
	run("8-bit");
	
	run("Merge Channels...", "c2=" + map2Andpax6Crop + " c6=" + map2Andpax6SegName + " create keep ignore");
	saveAs("Tiff", outputFolder + File.separator + fileNameWO + "_map2-pax6_Vis.tif");
	close();
	close(map2Andpax6Crop);
	close(map2Andpax6SegName);
	
	selectImage(map2Channel);
	run("Duplicate...", "duplicate");
	saveAs("Tiff", outputFolder  + File.separator + fileNameWO + "_map2_raw.tif");
	close();
	
	selectImage(map2Channel);
	run("Enhance Contrast...", "saturated=0.35 process_all use");
	run("8-bit");
	
	selectImage(map2SegName);
	run("Multiply...", "value=255.000 stack");
	
	run("Merge Channels...", "c2=" + map2Channel + " c6=" + map2SegName + " create keep ignore");
	saveAs("Tiff", outputFolder + File.separator + fileNameWO + "_map2_Vis.tif");
	close();
	close(map2Channel);
	close(map2SegName);
	
	selectImage(pax6Channel);
	run("Duplicate...", "duplicate");
	saveAs("Tiff", outputFolder + File.separator  + fileNameWO + "_pax6_raw.tif");
	close();
	
	selectImage(pax6Channel);
	run("Enhance Contrast...", "saturated=0.35 process_all use");
	run("8-bit");
	
	selectImage(pax6SegName);
	run("Multiply...", "value=255.000 stack");
	
	run("Merge Channels...", "c2=" + pax6Channel + " c6=" + pax6SegName + " create keep ignore");
	saveAs("Tiff", outputFolder + File.separator  + fileNameWO + "_pax6_Vis.tif");
	close();
	close(pax6Channel);
	close(pax6SegName);
	
	close("Measurements");
	
	run("Collect Garbage");
	Ext.CLIJ2_clear();
	
}
