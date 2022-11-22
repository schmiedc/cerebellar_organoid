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

output = "/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/Standardization/testOutput/";
inputImage = "C2-Crop-1-20220201-21-7-002-0.tif";
fileName = "C2-Crop-1-20220201-21-7-002-0";

normImage(inputImage, fileName, output);