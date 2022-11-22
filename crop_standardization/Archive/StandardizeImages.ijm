run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");

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
	
	// workaround create mask
	selectImage(imageDuplication);
	getDimensions(width, height, channels, slices, frames);
	newImage("mask" + filename, "8-bit white", width, height, slices);
	
	// standard deviation of masked pixels
	
	image2 = "mask" + filename;
	Ext.CLIJ2_push(image2);
	Ext.CLIJ2_standardDeviationOfMaskedPixels(image1, image2);
	stdDev = getResult("Masked_standard_deviation", 0);
	run("Clear Results");
	
	selectImage(imageDuplication);
	run("32-bit");
	run("Subtract...", "value=" + mean + " stack");
	run("Divide...", "value=" + stdDev + " stack");
	
	saveAs("Tiff", "" + output + File.separator  + "norm-" + filename);
	close("norm-" + filename + ".tif");
	
	close("mask" + filename);
	close(imageDuplication);
	
	Ext.CLIJ2_release(image1);
	Ext.CLIJ2_release(image2);
	run("Collect Garbage");

}

output = "/home/christopher.schmied/Desktop/";
inputImage = "C2-Crop-1-20220201-21-7-002-0.tif";
fileName = "C2-Crop-1-20220201-21-7-002-0";
normImage(inputImage, fileName, output);