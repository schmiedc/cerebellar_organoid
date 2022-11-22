// get Clij2 macro extension going
run("CLIJ2 Macro Extensions", "cl_device=[Quadro RTX 3000]");
setBatchMode(true);

saveSettings();
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");
// Note: using Clij looses Metadata!
// Note: keep classifier order consistent when generating a new classifier
// this determines the value of the mask in the segmentation
// TODO: some images don't close >> saved as .tif files

#@ File (label = "Image input directory", style = "directory") imageInputFolder
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

//imageInputFolder = "/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/AutomaticLabelling/";
//imageFile = "Crop-1-20220201-14-1-002-0.tif"; 
//output = "/run/user/1338/gvfs/smb-share:server=storage.fht.org,share=cerebellarorganoids/Crops/test_output/"

// ------------------------------------------------------------------------------------
processFolder(imageInputFolder);

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

// ------------------------------------------------------------------------------------
function processFile(imageInputFolder, output, imageFile) {


	classifierCh2Name = "/Ch2/C2-Crop-1-20220201-14-1-002-0.classifier";
	classifierCh3or4Name = "/Ch3or4/C4-Crop-1-20220201-14-1-002-0.classifier";
	classifierEntireOrganoidName = "/CombinedCh2Ch3or4/C2-C4-Crop1-20220201-14-1-002-0.classifier";
	
	// open crop
	run("Bio-Formats Importer", 
			"open=" + imageInputFolder + File.separator + imageFile + 
			" autoscale" + 
			" color_mode=Default" +
			" rois_import=[ROI manager]" +
			" view=Hyperstack" +
			" stack_order=XYCZT");
			
			
	stackName = getTitle();
	fileNameWO = File.getNameWithoutExtension(imageInputFolder + File.separator + imageFile );
	selectImage(stackName);
	rename(fileNameWO);
		
	// get meta data
	getVoxelSize(width, height, depth, unit);
	voxelMicron = width * height * depth;
	
	selectWindow(fileNameWO);
	run("Split Channels");
	
	// ---------------------------------------------------------
	stringArrray = split(fileNameWO, "-");
	print(stringArrray[1]);
	
	if (stringArrray[1] == 1) {
		
		print("Set 1 detected");
		dapi = 1;
		map2 = 2;
		extra = 3;
		sox2 = 4;
	
		dapiChannel = "C" + dapi + "-" + fileNameWO;
		map2Channel = "C" + map2 + "-" + fileNameWO;
		extraChannel = "C" + extra + "-" + fileNameWO;
		sox2Channel = "C" + sox2 + "-" + fileNameWO;
	
		close(dapiChannel);
		close(extraChannel);
		
	} else if (stringArrray[1] == 2) {
		
		print("Set 2 detected");
		dapi = 1;
		map2 = 2;
		extra = 3;
		sox2 = 4;
		pax6 = 5;
	
		dapiChannel = "C" + dapi + "-" + fileNameWO;
		map2Channel = "C" + map2 + "-" + fileNameWO;
		extraChannel = "C" + extra + "-" + fileNameWO;
		sox2Channel = "C" + sox2 + "-" + fileNameWO;
		pax6Channel = "C" + pax6 + "-" + fileNameWO;
	
		close(dapiChannel);
		close(extraChannel);
		close(pax6Channel);
		
	} else if (stringArrray[1] == 3) {
		
		print("Set 3 detected");
		dapi = 1;
		map2 = 2;
		sox2 = 3;
		pax6 = 4;
	
		dapiChannel = "C" + dapi + "-" + fileNameWO;
		map2Channel = "C" + map2 + "-" + fileNameWO;
		sox2Channel = "C" + sox2 + "-" + fileNameWO;
		pax6Channel = "C" + pax6 + "-" + fileNameWO;
	
		close(dapiChannel);
		close(pax6Channel);
		
	} else {
		
		print("Error: sets not recognized");
		
	}

	run("Set Measurements...", "mean standard modal min median redirect=None decimal=3");
	
	selectImage(map2Channel);
	run("Z Project...", "projection=[Average Intensity]");
	close(map2Channel);
	selectImage("AVG_" + map2Channel);
	run("Measure");
	saveAs("Results", "" + output + File.separator + fileNameWO + "_map2_imgStat.csv");
	close("Results");
	
	close("AVG_" + map2Channel);
	
	selectImage(sox2Channel);
	run("Z Project...", "projection=[Average Intensity]");
	close(sox2Channel);
	selectImage("AVG_" + sox2Channel);
	run("Measure");
	saveAs("Results", "" + output + File.separator + fileNameWO + "_sox2_imgStat.csv");
	close("Results");
	close("AVG_" + sox2Channel);
	
	run("Collect Garbage");
	
}

restoreSettings;
