macro 'signal-from-nucleolus' {

    /*
    * - Signal from nucleolus
    * This macro will do a few things:
    * 
    *   given a .lif file, for every set of images:
    *     segment the nuclei - save object map
    *     segment the nucleoli
    *     determine distance maps from nucleoli
    *     save pgm files from analysis in R
    * 
    * Tom, 2020
    * 
    */
    
    run("Bio-Formats Macro Extensions");
    
    // Input paramaters
    // Laptop
    dir1="/Users/tomvanschaik/surfdrive/data/microscopy/ts210402_E1546_confocal_Ki67_antibodies/ts210402_HCT116_wt_pADamID_Ki67_antibodies/";
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
            //Projection();
            SplitChannels();
            SegmentCell();
            SegmentNucleoli();
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
    run("3D OC Options", "volume surface integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value dots_size=5 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
}

function SplitChannels() {
    //
    rename(title_new);
    run("Split Channels");

    selectWindow("C3-" + title_new);
    rename("nucleolus");

    selectWindow("C2-" + title_new);
    rename("m6ATracer");

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

function SegmentNucleoli() {
    //
    selectWindow("nucleolus");
    run("Duplicate...", "duplicate");
    rename("nucleolus_smooth");
    
	run("Gaussian Blur...", "sigma=2");
    run("Subtract Background...", "rolling=500 sliding disable");
    run("Enhance Contrast...", "saturated=0.1 normalize");
    
    setOption("BlackBackground", false);
    //setAutoThreshold("Otsu dark");
    //run("Convert to Mask", "method=Otsu background=Dark list");
    setThreshold(180, 255);
    run("Convert to Mask");
    run("Fill Holes");
    rename("nucleolus_segment");
}

function DistanceMasks() {
    //
    selectWindow("nucleolus_segment");
    run("Duplicate...", "duplicate");
    rename("nucleolus_internal");
    run("Distance Map");
    
    selectWindow("nucleolus_segment");
    run("Duplicate...", " ");
    rename("nucleolus_external");
    run("Invert");
    run("Distance Map");
}

function SmoothSignal() {
    selectWindow("nucleolus");
    run("Duplicate...", "duplicate");
    rename("nucleolus_smooth");
    run("Gaussian Blur...", "sigma=2");
    run("Subtract Background...", "rolling=500 sliding disable");
    
    selectWindow("m6ATracer");
    run("Duplicate...", "duplicate");
    rename("m6ATracer_smooth");
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
    saveAs("pgm", experiment_dir + "/" + title_new + "_dapi.pgm");
    close();
    
    selectWindow("nucleolus");
    saveAs("pgm", experiment_dir + "/" + title_new + "_nucleolus.pgm");
    close();
    
    selectWindow("m6ATracer");
    saveAs("pgm", experiment_dir + "/" + title_new + "_m6ATracer.pgm");
    close();
    
    selectWindow("cell_smooth");
    saveAs("pgm", experiment_dir + "/" + title_new + "_dapi_mask.pgm");
    close();
    
    selectWindow("dapi_segment");
    saveAs("pgm", experiment_dir + "/" + title_new + "_dapi_segment.pgm");
    close();
    
    selectWindow("nucleolus_segment");
    saveAs("pgm", experiment_dir + "/" + title_new + "_nucleolus_segment.pgm");
    close();
    
    selectWindow("nucleolus_internal");
    saveAs("pgm", experiment_dir + "/" + title_new + "_nucleolus_internal.pgm");
    close();
    
    selectWindow("nucleolus_external");
    saveAs("pgm", experiment_dir + "/" + title_new + "_nucleolus_external.pgm");
    close();
    
    selectWindow("nucleolus_smooth");
    saveAs("pgm", experiment_dir + "/" + title_new + "_nucleolus_smooth.pgm");
    close();
    
    selectWindow("m6ATracer_smooth");
    saveAs("pgm", experiment_dir + "/" + title_new + "_m6ATracer_smooth.pgm");
    close();
    
}