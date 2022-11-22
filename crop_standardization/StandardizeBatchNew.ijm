setBatchMode(true);

run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");

/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function for applying normalization to image volume
function normChannel(channelName) { 
	
	selectImage(channelName);
	run("Duplicate...", "duplicate");
	imageDuplication = getTitle();

	image1 = imageDuplication;
	Ext.CLIJ2_push(image1);
	
	// mean of all pixels
	Ext.CLIJ2_meanOfAllPixels(image1);
	mean = getResult("Mean", 0);
	run("Clear Results");
	close("Results");

	// standard deviation of all pixels
	Ext.CLIJ2_standardDeviationOfAllPixels(image1);
	stdDev = getResult("StandardDeviation", 0);
	run("Clear Results");
	close("Results");
	
	selectImage(imageDuplication);
	type = bitDepth();
	
	if (type != 32) {
	
		selectImage(imageDuplication);
		run("32-bit");
	
	}
	
	selectImage(imageDuplication);
	run("Subtract...", "value=" + mean + " stack");
	run("Divide...", "value=" + stdDev + " stack");
	
	// needs to be a rename
	normImage = getTitle();
	
	selectImage(normImage);
	rename("norm-" + channelName);

	close(imageDuplication);
	
	Ext.CLIJ2_release(image1);
	run("Collect Garbage");

}


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
	
	
	run("Bio-Formats Importer", "open=" + input + File.separator + file + " " +
	"autoscale " +
	"color_mode=Default " +
	"rois_import=[ROI manager] " +
	"view=Hyperstack " +
	"stack_order=XYCZT");
	
	imageTitle = getTitle();
	imageName = File.nameWithoutExtension;
	
	selectImage(imageTitle);
	rename(imageName);
	
	// get meta data
	getVoxelSize(width, height, depth, unit);
	
	run("Split Channels");
	
	// ---------------------------------------------------------
	stringArrray = split(imageName, "-");
	
	if (stringArrray[1] == 1) {
		
		print("Set 1 detected");
		dapi = 1;
		map2 = 2;
		extra = 3;
		sox2 = 4;
	
		dapiChannel = "C" + dapi + "-" + imageName;
		map2Channel = "C" + map2 + "-" + imageName;
		extraChannel = "C" + extra + "-" + imageName;
		sox2Channel = "C" + sox2 + "-" + imageName;
	
		close(dapiChannel);
		close(extraChannel);
		
	} else if (stringArrray[1] == 2) {
		
		print("Set 2 detected");
		dapi = 1;
		map2 = 2;
		extra = 3;
		sox2 = 4;
		pax6 = 5;
	
		dapiChannel = "C" + dapi + "-" + imageName;
		map2Channel = "C" + map2 + "-" + imageName;
		extraChannel = "C" + extra + "-" + imageName;
		sox2Channel = "C" + sox2 + "-" + imageName;
		pax6Channel = "C" + pax6 + "-" + imageName;
	
		close(dapiChannel);
		close(extraChannel);
		close(pax6Channel);
		
	} else if (stringArrray[1] == 3) {
		
		print("Set 3 detected");
		dapi = 1;
		map2 = 2;
		sox2 = 3;
		pax6 = 4;
	
		dapiChannel = "C" + dapi + "-" + imageName;
		map2Channel = "C" + map2 + "-" + imageName;
		sox2Channel = "C" + sox2 + "-" + imageName;
		pax6Channel = "C" + pax6 + "-" + imageName;
	
		close(dapiChannel);
		close(pax6Channel);
		
	} else {
		
		print("Error: sets not recognized");
		
	}
	
	// normalize channel 2
	normChannel(map2Channel);
	
	// normalize channel 4
	normChannel(sox2Channel);
	
	// add channels together
	imageCalculator("Add create 32-bit stack", 
		map2Channel,
		sox2Channel);
		
	close(map2Channel);
	close(sox2Channel);
		
	sumName = getTitle();
	selectImage(sumName);
	
	channel1Name = "C" + 1 + "-" + imageTitle;
	rename(channel1Name);
	
	// normalize added channel
	normChannel(channel1Name);
	
	close(channel1Name);
	
	run("Merge Channels...", "c1=norm-" + channel1Name + " c2=norm-" + map2Channel + " c3=norm-" + sox2Channel + " create");
	
	mergeImage = getTitle();
	selectImage(mergeImage);
	saveAs("Tiff", output + File.separator  + "norm-" + imageName);
	close("norm-" + imageName + ".tif");
	close("*");
	
}
