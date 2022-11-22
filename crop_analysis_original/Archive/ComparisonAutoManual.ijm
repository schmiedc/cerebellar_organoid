run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");

inputDirAuto = "/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/segmentedCrops_manualSet/";
inputDirManual = "/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/ManualLabelling/Label/";

inputFile = "Crop-1-20220201-21-7-002-0_map2_Seg.tif";

outputDir = "/home/christopher.schmied/HT_Docs/Projects/CerebralOrganoids_DA/2022-08-01_FirstRun/";


// ------------------------------------------------------------------
open(inputDirAuto + File.separator + inputFile);

title = getTitle();
fileNameWO = File.getNameWithoutExtension(inputDirAuto + File.separator + inputFile);

// Check if segmentation present or not
// if segmentation present convert to 01 binary format
selectImage(title);
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_" + title);
run("Measure");
checkMask = getResultString("Mean", 0);
run("Clear Results");
close("MAX_" + title);
	
if (checkMask > 0) {
	
	selectImage(title);
	run("Divide...", "value=255.000 stack");
	autoSegValue = "True";
		
	} else {
		
	print("Warning: no segmentation");
	autoSegValue = "False";
		
}

print(fileNameWO);
nameArray = split(fileNameWO, "_");
print(nameArray[0]);

channel = "";

// Todo: create manual label name
if (nameArray[1] == "map2") {
	
	print("Channel Map2 selected");
	channel = "2";
	
} else if (nameArray[1] == "sox2") {
	
	print("Channel Map2 selected");
	
	checkSet = split(nameArray[0], "-");
	
	if (checkSet[0] == 1) {
		
		print("Detected set 1");
		channel = "4";
		
	} else if (checkSet[0] == 2) {
		
		print("Detected set 2");
		channel = "4";
		
	} else if (checkSet[0] == 2) {
	
		print("Detected set 3");
		channel = "3";
		
	}
	
}

manualLabelName = "Label_C" + channel + "-" + nameArray[0];
print(manualLabelName);

// Todo: from auto segmentation check if there is file present
labelExists = File.exists(inputDirManual + File.separator + manualLabelName + ".tif");

if (labelExists) {
	
	print("Manual label found");
	manualLabelValue = "True";
	open(inputDirManual + File.separator + manualLabelName + ".tif");
	rename(manualLabelName);
	
} else {
	
	print("Manual label not found");
	manualLabelValue = "False";
	newImage(manualLabelName, "8-bit black", 835, 686, 60);
	
}

// Todo: compute Dice 
image1 = title;
Ext.CLIJ2_push(image1);
image2 = manualLabelName;
Ext.CLIJ2_push(image2);

Ext.CLIJ2_sorensenDiceCoefficient(image1, image2);

dice = getResult("Sorensen_Dice_coefficient", 0);
run("Clear Results");

Table.create("Segmentation");
Table.set("ID", 0, fileNameWO);
Table.set("AutoSeg", 0, autoSegValue);
Table.set("ManualLabel", 0, manualLabelValue);
Table.set("Dice", 0, dice);

Table.save(outputDir + File.separator + fileNameWO + "_Meas.csv");
close("Segmentation");

close(title);
close(manualLabelName);