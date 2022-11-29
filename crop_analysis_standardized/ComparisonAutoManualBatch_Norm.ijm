run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");

/*
 * Script to compare automatic segmentation with manual labels
 * Christopher Schmied
 * Prototype script
 * 
 * IMPORTANT: Only works with outputs of crops WITH standardization
 * 
 * INPUT:
 * 1. Auto Seg input
 * 	Output of automatic segmentation script (but collected from both timepoints and split):
 * 	smb://storage.fht.org/cerebellarorganoids/cerebellar_organoid_results/2022-11-17_5thRun/input/split/
 * 
 * 2. Binary masks (0,1) from manual labeling:
 * 	smb://storage.fht.org/cerebellarorganoids/cerebellar_organoid_dataset_labeling/ManualLabeling_masks/
 * 	
 * 3. Output directory:
 * 	smb://storage.fht.org/cerebellarorganoids/cerebellar_organoid_results/2022-11-17_5thRun/output/
 * 	
 * 4. File suffix:
 * 	The suffix of the automatic segmentations: i.e. .tif
 * 		
 * OUTPUT:
 * <file-name>_Meas.csv
 * Contains area and DICE measurements
 * To be analyzed by the R script: plotDice.R
 */
 
#@ File (label = "Auto Seg input", style = "directory") input
#@ File (label = "Manual label input", style = "directory") input2
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, input2, list[i], output);
	}
}

function processFile(inputDirAuto, inputDirManual, inputFile, outputDir) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + inputDirAuto + File.separator + inputFile);
	print("Saving to: " + outputDir);
	
	// ------------------------------------------------------------------
	open(inputDirAuto + File.separator + inputFile);
	title = getTitle();
	fileNameWO = File.getNameWithoutExtension(inputDirAuto + File.separator + inputFile);
	
	selectImage(title);
	getDimensions(width, height, channels, slices, frames);
	selectImage(title);
	
	if (slices == 1) {
		
		run("Properties...", "channels=" + slices + " slices=" + channels + " frames=1 pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000");

	}
	
	// Check if segmentation present or not
	// if segmentation present convert to 01 binary format
	selectImage(title);
	run("Z Project...", "projection=[Max Intensity]");
	selectImage("MAX_" + title);
	run("Measure");
	checkMask = getResultString("Mean", 0);
	print("Value for mask: " + checkMask);
	run("Clear Results");
	close("MAX_" + title);
	autoSegValue = "False";
		
	if (checkMask > 0) {
		
		print("Auto segmentation present");
		selectImage(title);
		autoSegValue = "True";
			
		} else {
			
		print("Auto segmentation empty");
		print("Warning: no segmentation");
		autoSegValue = "False";
			
	}
	
	// adjust for new filename
	print(fileNameWO);
	nameArray = split(fileNameWO, "(norm-)");
	print("Name stem: " + nameArray[1]);

	
	manualLabelName = "Label_" + nameArray[1];
	print("Manual label name: " + manualLabelName);
	
	// Todo: from auto segmentation check if there is file present
	labelExists = File.exists(inputDirManual + File.separator + manualLabelName + ".tif");
	manualLabelValue = "False";
	
	if (labelExists) {
		
		print("Manual label found");
		manualLabelValue = "True";
		open(inputDirManual + File.separator + manualLabelName + ".tif");
		rename(manualLabelName);
		
	} else {
		
		print("Manual label not found");
		manualLabelValue = "False";
		selectImage(title);
		getDimensions(width, height, channels, slices, frames);
		newImage(manualLabelName, "8-bit black", width, height, slices);
		
	}
	
	// Todo: compute Dice 
	image1 = title;
	Ext.CLIJ2_push(image1);
	image2 = manualLabelName;
	Ext.CLIJ2_push(image2);
	
	Ext.CLIJ2_sorensenDiceCoefficient(image1, image2);
	
	Ext.CLIJ2_release(image1);
	Ext.CLIJ2_release(image2);
	
	dice = getResult("Sorensen_Dice_coefficient", 0);
	print("Dice is: " + dice);
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
}