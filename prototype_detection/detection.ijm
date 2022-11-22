//setTool("zoom");
run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");
run("Point Tool...", "type=Hybrid color=yellow size=Small label counter=0");
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black do=Nothing");

run("3D Manager Options", "volume surface compactness fit_ellipse integrated_density mean_grey_value std_dev_grey_value minimum_grey_value maximum_grey_value centroid_(pix) centroid_(unit) distance_to_surface centre_of_mass_(pix) centre_of_mass_(unit) bounding_box radial_distance closest exclude_objects_on_edges_xy exclude_objects_on_edges_z distance_between_centers=10 distance_max_contact=1.80 drawing=Point");


// inputFolder = "/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/Detection/testInput/downSampledCropped/";
inputFolder = "/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/Segmentation/output/";
outputFolder = "/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/Detection/output/";

inputRaw = "4B_map2_raw.tif";
inputSeg = "4B_map2_Seg.tif";

sigmaX = 3;
sigmaY = sigmaX;
simgaZ = 3;


radiusXY = 5;
radiusZ = 3;
noise = 1000;
minimumThreshold = 20000; 
	
resultNameStringLoG = "DS1-" + sigmaX + "x" + sigmaY + "x" + simgaZ;
maximaFinderString = "MF-" + minimumThreshold + "-" + radiusXY + "x" + radiusZ + "-" + noise;
resultString = resultNameStringLoG + "_" + maximaFinderString;

// open images
open(inputFolder + File.separator + inputRaw);
rawImage = getTitle();

// ---------------------------------------------------------
// detect maxima
selectImage(rawImage);
run("Invert", "stack");
run("LoG 3D", "sigmax=" + sigmaX + 
	" sigmay=" + sigmaY + 
	" sigmaz=" + simgaZ + 
	" displaykernel=0 volume=1");
wait(15000);
logName = "log" + rawImage;
selectWindow("LoG of " + rawImage);
rename(logName);
// ---------------------------------------------------------
selectImage(logName);
run("Conversions...", "scale");
Stack.getStatistics(voxelCount, mean, min, max, stdDev);
setMinAndMax(min, max);
run("16-bit");
// ---------------------------------------------------------
open(inputFolder + File.separator + inputSeg);
segImage = getTitle();

// get inner region of the map2 signal
selectImage(segImage);
run("Duplicate...", "duplicate");
map2SegName1 = "map2-Seg2-" + rawImage;
rename(map2SegName1);

selectImage(map2SegName1);
run("Manual Threshold...", "min=0 max=0");
run("Make Binary", "method=Default background=Dark");
run("Invert LUT");
run("Invert", "stack");

imageInnerMask = "mask_Seg1-" + rawImage;
Ext.CLIJ2_push(logName);
Ext.CLIJ2_push(map2SegName1);
Ext.CLIJ2_mask(logName, map2SegName1, imageInnerMask);
Ext.CLIJ2_pull(imageInnerMask);

Ext.CLIJ2_clear();
run("Collect Garbage");

// ---------------------------------------------------------
// maxima finder
selectImage(imageInnerMask);
run("3D Maxima Finder", "minimmum=" + minimumThreshold + " radiusxy=" + radiusXY + " radiusz=" + radiusZ + " noise=" + noise);

// threshold the result of the maxima finder
// to get a binary mask
peakImage = "peaks";
Ext.CLIJ2_push(peakImage);
thresholdedPeakImage = "threshold";
threshold = minimumThreshold;
Ext.CLIJ2_threshold(peakImage, thresholdedPeakImage, threshold);
close(imageInnerMask);
// ---------------------------------------------------------
// get outer region of the map2 signal
selectImage(segImage);
run("Duplicate...", "duplicate");
imageOuterMask = "mask-Seg2-" + rawImage;
rename(imageOuterMask);

selectImage(imageOuterMask);
run("Manual Threshold...", "min=128 max=128");
run("Make Binary", "method=Default background=Dark");
run("Invert LUT");

close(segImage);
// ---------------------------------------------------------
// mask detections with outer region
Ext.CLIJ2_push(imageOuterMask);

image3Mask = "masked_Peaks" + rawImage;

Ext.CLIJ2_mask(thresholdedPeakImage, imageOuterMask, image3Mask);
Ext.CLIJ2_pull(image3Mask);
saveAs("Tiff", outputFolder + File.separator + rawImage + "_map2_DetectMask.tif");
rename(image3Mask); 

close(imageOuterMask);
// ---------------------------------------------------------
selectImage(map2SegName1);
run("Exact Euclidean Distance Transform (3D)");
saveAs("Tiff", outputFolder + File.separator + rawImage + "_map2_EDM.tif");
edmName = "edmInnerReg_" + rawImage;
rename(edmName);

numberDetections = nResults;

for (detection = 0; detection < numberDetections; detection++)  {
	
	xDetect = getResult("X", detection);
	yDetect = getResult("Y", detection);
	zDetect = getResult("Z", detection);
	
	selectImage(edmName);
	setSlice(zDetect);
	detectDistance = getPixel(xDetect, yDetect);
	
	setResult("Distance", detection, detectDistance);

}

close(edmName);
close(map2SegName1);
// ---------------------------------------------------------
// loop to dilate the detections
output2 = "output";

for (i = 0; i < 4; i++) {
	
	output1 = "dilate" + i;
	
	if ( i == 0 ) {
			
		Ext.CLIJ2_dilateSphere(image3Mask, output1);
			
	} else if (i > 0 ) {
			
		Ext.CLIJ2_dilateSphere(output2, output1);
			
	}
	
	output2 = "dilate" + i;
		
}
	
resultMask = "detectionMask";
Ext.CLIJ2_multiplyImageAndScalar(output2, resultMask, 255);
	
Ext.CLIJ2_pull(resultMask);
close(image3Mask);
// ---------------------------------------------------------
// save raw image and detection result
selectImage(rawImage);
run("Invert", "stack");

run("Merge Channels...", "c2=" + rawImage + " c6=" + resultMask + " create keep");
	
selectImage("Composite");
	
saveAs("Tiff",outputFolder + File.separator + "Raw_" + resultString  + ".tif");
close();

// save  result table
saveAs("Results", outputFolder + File.separator + "Results_" + resultString  + ".csv");

// save log image 
selectImage(resultMask);
run("16-bit");

run("Merge Channels...", "c2=" + logName + " c6=" + resultMask + " create keep");
saveAs("Tiff",outputFolder + File.separator + "LoG_" + resultString  + ".tif");
close();
	
close(logName);
close(rawImage);
close(resultMask);

close("peaks");
close("Results");

minimumThreshold = minimumThreshold + 10;
Ext.CLIJ2_clear();