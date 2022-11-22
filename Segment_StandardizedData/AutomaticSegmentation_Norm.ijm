// get Clij2 macro extension going
run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");
setBatchMode(false);

saveSettings();
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");

// TODO: create interface
imageInputFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_ManualLabelling/14/";
outputImageFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_ManualLabelling/14_output/";
imageFile = "norm-C2-Crop-2-20220314-14-1-001-0.tif";

classifierFolder = "/run/media/christopher.schmied/QuickBackup/cerebellarOrganoids/Standardize_AutomaticLabelling/Ch2/";
classifierCh2Name = "norm-C2-Crop-1-20220201-14-1-002-0.classifier";
classifierCh3or4Name = "norm-C4-Crop-1-20220201-14-1-002-0.classifier";

// open crop
run("Bio-Formats Importer", 
	"open=" + imageInputFolder + File.separator + imageFile + 
	" autoscale" + 
	" color_mode=Default" +
	" rois_import=[ROI manager]" +
	" view=Hyperstack" +
	" stack_order=XYCZT");

// read out file names
map2Channel = getTitle();
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
selectImage(map2Channel);

run("Segment Image With Labkit", 
	"segmenter_file=" + classifierFolder + File.separator + classifierName +
	" use_gpu=true");

run("Manual Threshold...", "min=1 max=1");
setOption("BlackBackground", true);
run("Convert to Mask", "method=Default background=Dark black");

maskedResult = getTitle();

saveAs("Tiff", outputImageFolder + File.separator + "Mask_" + fileNameWO);