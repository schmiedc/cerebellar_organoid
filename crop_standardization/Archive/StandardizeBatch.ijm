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
function normImage(inputImage, filename, output) { 
	
	selectImage(inputImage);
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
	run("32-bit");
	run("Subtract...", "value=" + mean + " stack");
	run("Divide...", "value=" + stdDev + " stack");
	
	saveAs("Tiff", "" +  output + File.separator  + "norm-" + filename);
	close("norm-" + filename + ".tif");
	
	close("mask" + filename);
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
	
	
	normImage(imageTitle, imageName, output);
	
	close(imageTitle);
	
}
