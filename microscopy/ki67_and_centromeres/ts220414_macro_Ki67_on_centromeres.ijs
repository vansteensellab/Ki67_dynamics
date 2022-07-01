macro 'signal-from-centromeres' {

    /*
    * - Signal from nucleolus
    * This macro will do a few things:
    * 
    *   given a .lif file, for every set of images:
    *     segment the nuclei - save object map
    *     segment the nucleoli
    *     determine distance maps from nucleoli
    *     save tiff files from analysis in R
    * 
    * Tom, 2020
    * 
    */
    
    run("Bio-Formats Macro Extensions");
    
    // Input paramaters
    // Laptop
    dir1="/Users/t.v.schaik/surfdrive/data/microscopy/ts220414_E1936_confocal/ts220414_RPE_ActD/";
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
            print("Processing: " + title_new);
                        

            // Processing functions
            Projection();
            SplitChannels();
            SegmentCell();
            SegmentCentromeres();
            DistanceMasks();
            SmoothSignal();
            SaveAllImages();
            CloseOpenCellWindows();
                        
            // Cleanup
            run("Close All");
            run("Collect Garbage");
            
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
    run("3D OC Options", "volume surface integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value dots_size=5 font_size=0 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
}

function Projection() {
    //
    run("Z Project...", "projection=[Max Intensity]");
}

function SplitChannels() {
    //
    rename(title_new);
    run("Split Channels");

    selectWindow("C3-" + title_new);
    rename("ki67");

    selectWindow("C2-" + title_new);
    rename("centromeres");

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
    
    run("3D Objects Counter", "threshold=1 slice=1 min.=50 max.=1048576 exclude_objects_on_edges objects statistics");
    selectWindow("Objects map of cell_smooth-dist-watershed");
    rename("dapi_segment");
        
    // Save the object counter results
    IJ.renameResults("Statistics for cell_smooth-dist-watershed", "Result");
    selectWindow("Result");
    saveAs("Results",  experiment_dir + "/" + title_new + "_cells_statistics.csv");
    run("Close");
    
}

function SegmentCentromeres() {
    //
    selectWindow("centromeres");
    run("Duplicate...", "duplicate");
    rename("centromeres_smooth");
    
    //run("Gaussian Blur...", "sigma=1");
    //run("Subtract Background...", "rolling=500 sliding disable");
    run("Enhance Contrast...", "saturated=0.1 normalize");
    
    setOption("BlackBackground", false);
    //setAutoThreshold("Otsu dark");
    //run("Convert to Mask", "method=Otsu background=Dark list");
    setThreshold(100, 255);
    run("Convert to Mask");
    run("Fill Holes");
    rename("centromeres_segment");
    
    run("3D Objects Counter", "threshold=1 slice=1 min.=1 max.=1048576 exclude_objects_on_edges objects statistics");
    selectWindow("Objects map of centromeres_segment");
    rename("centromeres_objects");
        
    // Save the object counter results
    IJ.renameResults("Statistics for centromeres_segment", "Result");
    selectWindow("Result");
    saveAs("Results",  experiment_dir + "/" + title_new + "_centromere_statistics.csv");
    run("Close");
}

function DistanceMasks() {
    //
    selectWindow("centromeres_segment");
    run("Duplicate...", " ");
    rename("centromeres_external");
    run("Invert");
    run("Distance Map");
}

function SmoothSignal() {
    selectWindow("centromeres");
    run("Duplicate...", "duplicate");
    rename("centromeres_smooth");
    run("Gaussian Blur...", "sigma=1");
    run("Subtract Background...", "rolling=500 sliding disable");
    
    selectWindow("ki67");
    run("Duplicate...", "duplicate");
    rename("ki67_smooth");
    run("Gaussian Blur...", "sigma=2");
    run("Subtract Background...", "rolling=500 sliding disable");
}

function CloseOpenCellWindows() {
    //
    selectWindow("cell_smooth-dist-watershed");
    close();
}

function SaveAllImages() {
    selectWindow("dapi");
    saveAs("tiff", experiment_dir + "/" + title_new + "_dapi.tiff");
    close();
    
    selectWindow("centromeres");
    saveAs("tiff", experiment_dir + "/" + title_new + "_centromeres.tiff");
    close();
    
    selectWindow("ki67");
    saveAs("tiff", experiment_dir + "/" + title_new + "_ki67.tiff");
    close();
    
    selectWindow("cell_smooth");
    saveAs("tiff", experiment_dir + "/" + title_new + "_dapi_mask.tiff");
    close();
    
    selectWindow("dapi_segment");
    saveAs("tiff", experiment_dir + "/" + title_new + "_dapi_segment.tiff");
    close();
    
    selectWindow("centromeres_segment");
    saveAs("tiff", experiment_dir + "/" + title_new + "_centromeres_segment.tiff");
    close();
    
    selectWindow("centromeres_external");
    saveAs("tiff", experiment_dir + "/" + title_new + "_centromeres_external.tiff");
    close();
    
    selectWindow("centromeres_smooth");
    saveAs("tiff", experiment_dir + "/" + title_new + "_centromeres_smooth.tiff");
    close();
    
    selectWindow("centromeres_objects");
    saveAs("tiff", experiment_dir + "/" + title_new + "_centromeres_objects.tiff");
    close();
    
    selectWindow("ki67_smooth");
    saveAs("tiff", experiment_dir + "/" + title_new + "_ki67_smooth.tiff");
    close();
    
}