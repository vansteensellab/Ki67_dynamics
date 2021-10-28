macro 'intensity-of-ki67' {

    /*
    * - Ki67 intensity
    * This macro will do a few things:
    * 
    *   given a .lif file, for every set of images:
    *     segment the nuclei and determine size / intensity
    *     determine mean signal for mki67ip and ki67 (other channels)
    * 
    * Tom, 2020
    * 
    */
    
    run("Bio-Formats Macro Extensions");
    
    // Input paramaters
    // Laptop
    dir1="/Users/tomvanschaik/surfdrive/data/microscopy/ts201207_Exxx_confocal_various_experiments/ts210316_Ki67_depletion/"
    dir2=dir1;
        
    // List the files
    list = getFileList(dir1);
        
    setBatchMode(true);
    
    for (k=0; k<list.length; k++) {
        showProgress(k+1, list.length);
        print("processing ... "+k+1+"/"+list.length+"\n         "+list[k]);
        path=dir1+list[k];
        
        if (! endsWith(path, ".lif")) {
            print("No lif file experiment");
            continue; 
        }

        //how many series in this lif file?
        Ext.setId(path);//-- Initializes the given path (filename).
        Ext.getSeriesCount(seriesCount); //-- Gets the number of image series in the active dataset.
         
        Objects3DOptions();
        run("3D Manager");
    
        for (j=0; j<=seriesCount; j++) {
        
            run("Bio-Formats", "open=path autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+j);
            
            // Get the title, prepare the output directory and change the names
            title = getTitle();

            experiment = replace(title, "\\.lif.*", "");
            experiment_dir = dir2 + "/" + experiment + "_analysis";
            if (!File.exists(experiment_dir)) {
                File.makeDirectory(experiment_dir);
            }

            title_new = replace(title, ".*lif - ", "");
            
            if (File.exists(experiment_dir + "/" + title_new + "_segmentation_cell_mask_maxP.tiff")) {
                print("Skipping (files exist): " + title_new);
                continue;
            } else {
                print("Processing: " + title_new);
            }
                        

            // Processing functions
			//Projection();
			SplitChannels();
            SegmentCell();
            MeasureChannels();
            SaveAllImages();
            CloseOpenCellWindows();
                        
            // Cleanup
            run("Close All");
            run("Collect Garbage");
            
            Ext.Manager3D_Reset();

            // list = getList("window.titles");
            // print(list.length);
            // for (i=0; i<list.length; i++){
            //     winame = list[i];
            //     selectWindow(winame);
            //     run("Close");
            // }
        
        }

    }
    showMessage(" -- finished --");    
    run("Close All");
    setBatchMode(false);

} // macro




function Objects3DOptions() {
    //
    run("3D OC Options", "volume surface integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value dots_size=5 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
}

function SplitChannels() {
    //
    rename(title_new);
    run("Split Channels");

    selectWindow("C3-" + title_new);
    rename("ki67");

    selectWindow("C2-" + title_new);
    rename("mki67ip");

    selectWindow("C1-" + title_new);
    rename("dapi");
}

function BrightestSlice() {
   
    brightest_mean = 0;
    brightest_slice = 1;
    for (l=1; l<nSlices; l++) {
        setSlice(l);
        getStatistics(area, mean);
        if (brightest_mean < mean) {
            brightest_mean = mean;
            brightest_slice = l;
        }
    }
    return brightest_slice;
}

function SegmentCell() {
    //
    selectWindow("dapi");
    run("Duplicate...", "duplicate");
    rename("cell_smooth");
    
	//run("Subtract Background...", "rolling=250 stack");
    run("Gaussian Blur 3D...", "x=2 y=2 z=2");
    run("Enhance Contrast...", "saturated=0.2 normalize process_all use");
    
    setOption("BlackBackground", false);
    setAutoThreshold("Otsu dark stack");
    run("Convert to Mask", "method=Otsu background=Dark list");
    run("Fill Holes", "stack");
    
    run("Distance Transform Watershed 3D", "distances=[Borgefors (3,4,5)] output=[16 bits] normalize dynamic=2 connectivity=6");
    rename("segmentation_cell");
    
    // Temporary add 1 slice to the top and bottem, to prevent cells from being removed by touching these edges
    run("Extend Image Borders", "left=0 right=0 top=0 bottom=0 front=1 back=1 fill=Black");
    run("3D Objects Counter", "threshold=1 slice=18 min.=1 max.=37748736 exclude_objects_on_edges objects");
    
    // Save the object counter results
    selectWindow("Objects map of segmentation_cell-ext");
    Ext.Manager3D_AddImage();
    Ext.Manager3D_Measure();
    Ext.Manager3D_SaveResult("M", experiment_dir + "/" + title_new + "_dapi_statistics.csv");
    Ext.Manager3D_CloseResult("M");
    
    selectWindow("dapi");
    run("Subtract Background...", "rolling=250 sliding disable stack");
    Ext.Manager3D_Quantif();
    Ext.Manager3D_SaveResult("Q", experiment_dir + "/" + title_new + "_dapi.csv");
    Ext.Manager3D_CloseResult("Q");
    
}

function MeasureChannels() {
    //
    selectWindow("mki67ip");
    run("Gaussian Blur 3D...", "x=1 y=1 z=1");
    run("Median...", "radius=3 stack");
    run("Subtract Background...", "rolling=250 sliding disable stack");
    Ext.Manager3D_Quantif();
    Ext.Manager3D_SaveResult("Q", experiment_dir + "/" + title_new + "_mki67ip.csv");
    Ext.Manager3D_CloseResult("Q");
    
    selectWindow("ki67");
    run("Gaussian Blur 3D...", "x=1 y=1 z=1");
    run("Median...", "radius=3 stack");
    run("Subtract Background...", "rolling=250 sliding disable stack");
    Ext.Manager3D_Quantif();
    Ext.Manager3D_SaveResult("Q", experiment_dir + "/" + title_new + "_ki67.csv");
    Ext.Manager3D_CloseResult("Q");
    
}

function CloseOpenCellWindows() {
    //
    selectWindow("segmentation_cell-ext");
    close();
}

function Projection() {
    //
    run("Z Project...", "projection=[Max Intensity]");
}

function SaveAllImages() {
    selectWindow("dapi");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_dapi.tiff");
    Projection();
    saveAs("Tiff", experiment_dir + "/" + title_new + "_dapi_maxP.tiff");
    close();
    
    selectWindow("mki67ip");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_lamina.tiff");
    Projection();
    saveAs("Tiff", experiment_dir + "/" + title_new + "_mki67ip_maxP.tiff");
    close();
    
    selectWindow("ki67");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_target.tiff");
    Projection();
    saveAs("Tiff", experiment_dir + "/" + title_new + "_ki67_maxP.tiff");
    close();
    
    selectWindow("segmentation_cell");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_segmentation_cell.tiff");
    Projection();
    saveAs("Tiff", experiment_dir + "/" + title_new + "_segmentation_cell_maxP.tiff");
    close();
    
    selectWindow("cell_smooth");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_segmentation_cell_mask.tiff");
    Projection();
    saveAs("Tiff", experiment_dir + "/" + title_new + "_segmentation_cell_mask_maxP.tiff");
    close();
    
}
