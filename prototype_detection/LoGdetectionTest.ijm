//setTool("zoom");
run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");
run("Point Tool...", "type=Hybrid color=Green size=Small label counter=0");

run("3D Manager Options", "volume surface compactness fit_ellipse integrated_density mean_grey_value std_dev_grey_value minimum_grey_value maximum_grey_value centroid_(pix) centroid_(unit) distance_to_surface centre_of_mass_(pix) centre_of_mass_(unit) bounding_box radial_distance closest exclude_objects_on_edges_xy exclude_objects_on_edges_z distance_between_centers=10 distance_max_contact=1.80 drawing=Point");


inputFolder = "/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/2022-04-15/DetectionTest/input/";
outputFolder = "/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/2022-04-15/DetectionTest/output/";

inputFile = "Substack.tif";

sigmaX = 3;
sigmaY = sigmaX;
simgaZ = 3;


radiusXY = 5;
radiusZ = 3;
noise = 0;

for ( minimumThreshold = -400; minimumThreshold <= -350; ) {
	
	resultNameStringLoG = "DS1-" + sigmaX + "x" + sigmaY + "x" + simgaZ;
	maximaFinderString = "MF-" + minimumThreshold + "-" + radiusXY + "x" + radiusZ + "-" + noise;
	resultString = resultNameStringLoG + "_" + maximaFinderString;

	open(inputFolder + File.separator + inputFile);
	imageIdentifier = getTitle();
	
	selectImage(imageIdentifier);
	run("Invert", "stack");
	run("LoG 3D", "sigmax=" + sigmaX + " sigmay=" + sigmaY + " sigmaz=" + simgaZ + " displaykernel=0 volume=1");
	logName = "log";
	selectWindow("LoG of " + inputFile);
	rename(logName);
	
	// maxima finder
	run("3D Maxima Finder", "minimmum=" + minimumThreshold + " radiusxy=" + radiusXY + " radiusz=" + radiusZ + " noise=" + noise);
	
	// threshold the result of the maxima finder
	image1 = "peaks";
	Ext.CLIJ2_push(image1);
	image2 = "threshold";
	threshold = minimumThreshold;
	Ext.CLIJ2_threshold(image1, image2, threshold);
	
	output2 = "output";
	
	// loop to dilate the detections
	for (i = 0; i < 5; i++) {
	
	output1 = "dilate" + i;
	
		if ( i == 0 ) {
			
			Ext.CLIJ2_dilateSphere(image2, output1);
			
		} else if (i > 0 ) {
			
			Ext.CLIJ2_dilateSphere(output2, output1);
			
		}
	
	output2 = "dilate" + i;
		
	}
	
	resultMask = "detectionMask";
	Ext.CLIJ2_multiplyImageAndScalar(output2, resultMask, 255);
	
	Ext.CLIJ2_pull(resultMask);
	
	run("Merge Channels...", "c2=" + inputFile + " c6=" + resultMask + " create keep");
	
	selectImage("Composite");
	
	saveAs("Tiff",outputFolder + File.separator + "CompositeLoG_" + resultString  + ".tif");
	close();
	
	saveAs("Results", outputFolder + File.separator + "Results_" + resultString  + ".csv");
	
	selectImage(resultMask);
	run("32-bit");
	
	run("Merge Channels...", "c2=" + logName + " c6=" + resultMask + " create keep");
	saveAs("Tiff",outputFolder + File.separator + "LoG_" + resultString  + ".tif");
	close();
	
	close(logName);
	close(inputFile);
	close(resultMask);
	
	close("peaks");
	close("Results");
	
	minimumThreshold = minimumThreshold + 10;
	Ext.CLIJ2_clear();
}