macro 'intensity-of-ki67-2d' {

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
    dir1="/Users/tomvanschaik/surfdrive/data/microscopy/ts210402_E1546_confocal_Ki67_antibodies/ts210402_HCT116_Ki67AID_Ki67_depletion/"
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
            
            if (File.exists(experiment_dir + "/" + title_new + "_segmentation_cell_mask.tiff")) {
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

function SegmentCell() {
    //
    selectWindow("dapi");
    run("Duplicate...", "duplicate");
    rename("cell_smooth");
    
	run("Gaussian Blur...", "sigma=2");
    run("Enhance Contrast...", "saturated=0.2 normalize");
    
    setOption("BlackBackground", false);
    setAutoThreshold("Otsu dark");
    run("Convert to Mask", "method=Otsu background=Dark list");
    run("Fill Holes");
    
    run("Distance Transform Watershed", "distances=[Borgefors (3,4)] output=[16 bits] normalize dynamic=4 connectivity=8");
    
    run("3D Objects Counter", "threshold=1 slice=1 min.=50 max.=1048576 exclude_objects_on_edges objects");
    selectWindow("Objects map of cell_smooth-dist-watershed");
    rename("dapi_segment");
    
    // Save the object counter results
    selectWindow("dapi_segment");
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
	run("Gaussian Blur...", "sigma=2");
    run("Median...", "radius=3");
    run("Subtract Background...", "rolling=250 sliding disable");
    Ext.Manager3D_Quantif();
    Ext.Manager3D_SaveResult("Q", experiment_dir + "/" + title_new + "_mki67ip.csv");
    Ext.Manager3D_CloseResult("Q");
    
    selectWindow("ki67");
	run("Gaussian Blur...", "sigma=2");
    run("Median...", "radius=3");
    run("Subtract Background...", "rolling=250 sliding disable");
    Ext.Manager3D_Quantif();
    Ext.Manager3D_SaveResult("Q", experiment_dir + "/" + title_new + "_ki67.csv");
    Ext.Manager3D_CloseResult("Q");
    
}

function CloseOpenCellWindows() {
    //
    selectWindow("cell_smooth-dist-watershed");
    close();
}

function SaveAllImages() {
    selectWindow("dapi");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_dapi.tiff");
    saveAs("Tiff", experiment_dir + "/" + title_new + "_dapi.tiff");
    close();
    
    selectWindow("mki67ip");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_lamina.tiff");
    saveAs("Tiff", experiment_dir + "/" + title_new + "_mki67ip.tiff");
    close();
    
    selectWindow("ki67");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_target.tiff");
    saveAs("Tiff", experiment_dir + "/" + title_new + "_ki67.tiff");
    close();
    
    selectWindow("dapi_segment");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_segmentation_cell.tiff");
    saveAs("Tiff", experiment_dir + "/" + title_new + "_segmentation_cell.tiff");
    close();
    
    selectWindow("cell_smooth");
    //saveAs("Tiff", experiment_dir + "/" + title_new + "_segmentation_cell_mask.tiff");
    saveAs("Tiff", experiment_dir + "/" + title_new + "_segmentation_cell_mask.tiff");
    close();
    
}
