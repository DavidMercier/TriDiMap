%% Copyright 2014 MERCIER David
function demo
%% Function to run the Matlab code for the 3D mapping of indentation data
clear all
clear classes % not included in clear all
close all
commandwindow
clc
delete(findobj(allchild(0), '-regexp', 'Tag', '^Msgbox_'))

%% Define gui structure variable
gui = struct();
gui.config = struct();
gui.config.data = struct();
gui.config.numerics = struct();

%% Paths Management
% Don't move before definition of 'gui' as a struct()
try
    gui.config.tridim_root = get_tridim_root; % ensure that environment is set
catch
    [startdir, dummy1, dummy2] = fileparts(mfilename('fullpath'));
    cd(startdir);
    commandwindow;
    path_management;
    gui.config.tridim_root = get_tridim_root; % ensure that environment is set
end

gui.config.data_path = '.\data_indentation';

%% Set default variables
gui.config.TriDiView = 0; % Boolean to set plots (0 = 1 map / 1 = 3 maps)
gui.config.normalizationStep = 0; % 0 if no normalization and 1 if normalization step

% Smoothing and Interpolation
gui.config.noNan = 1; % Boolean to remove NaN values (blank pixels)
gui.config.interpBool = 1; % Boolean to activate interpolation
gui.config.interpFact = 1; % Factor of interpolation
% 0 for no interpolation, 1 or 2 is the best
gui.config.smoothBool = 1; % Boolean to correct values after smoothing
gui.config.smoothFact = 1; % Number of points used to smooth rows and columns
% 0 = no smoothing and best is 1 or 2
gui.config.binarizedGrid = 0; % Variable to binarize values of the grid
% 0 = no binarization / 1 = smoothed binarization / 2 = binarization

% REMARKS %
% Don't set a too high number of points to smooth rows and columns...
% or the absolute maximum/minimum values are decreasing !

% Configuration of the indentation map
gui.config.N_XStep_default = 10; % Default number of steps along X axis
gui.config.N_YStep_default = 10; % Default number of steps along Y axis
gui.config.XStep_default = 2; % Default value of X step in microns
gui.config.YStep_default = 2; % Default value of Y step in microns
gui.config.angleRotation_default = 0; % Default rotation angle of the indentation map in degrees

% Colorbar setting
gui.config.Markers = 1; % Boolean to plot markers
gui.config.scaleAxis = 0; % Boolean to set color scale
gui.config.intervalScaleBar = 0; % Number of interval on the scale bar
% 0 if continuous scalebar, and 5 to 10 to set interval number
gui.config.H_cmin = 3; % in GPa
gui.config.H_cmax = 10; %in GPa
gui.config.YM_cmin = 150; % in GPa
gui.config.YM_cmax = 250; % in GPa
gui.config.FontSizeVal = 14;

%% Load data from Excel files
[config, gui.data] = TriDiMap_loadingData(gui.config);

if config.flag_data
    
    if gui.config.noNan
        gui.data.expValues_mat.H = ...
            TriDiMap_cleaningData(gui.data.expValues_mat.H);
        
        gui.data.expValues_mat.YM = ...
            TriDiMap_cleaningData(gui.data.expValues_mat.YM);
    end
    
    gui.config.data_path = config.data_path;
    gui.config.flag_data = config.flag_data;
    gui.config.N_XStep = config.N_XStep;
    gui.config.N_YStep = config.N_YStep;
    gui.config.XStep = config.XStep;
    gui.config.YStep = config.YStep;
    
    %% Normalization step
    normStep = gui.config.normalizationStep;
    if normStep
        % Normalization of elastic modulus
        gui.data.expValues_mat_average.YM = mean(mean(gui.data.expValues_mat.YM));
        gui.data.expValues_mat_norm.YM = gui.data.expValues_mat.YM - gui.data.expValues_mat_average.YM;
        % Normalization of hardness
        gui.data.expValues_mat_average.H = mean(mean(gui.data.expValues_mat.H));
        gui.data.expValues_mat_norm.H = gui.data.expValues_mat.H - gui.data.expValues_mat_average.H;
    end
    
    %% Interpolating, smoothing and binarizing steps of dataset
    if normStep
        [gui.data.YM.expValuesInterp, gui.data.YM.expValuesSmoothed, ...
            gui.data.YM.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            gui.data.expValues_mat_norm.YM, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid);
        
        [gui.data.H.expValuesInterp, gui.data.H.expValuesSmoothed, ...
            gui.data.H.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            gui.data.expValues_mat_norm.H, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid);
    else
        [gui.data.YM.expValuesInterp, gui.data.YM.expValuesSmoothed, ...
            gui.data.YM.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            gui.data.expValues_mat.YM, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid);
        
        [gui.data.H.expValuesInterp, gui.data.H.expValuesSmoothed, ...
            gui.data.H.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            gui.data.expValues_mat.H, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid);
    end
    
    %% Grid meshing
    x_step = gui.config.XStep;
    y_step = gui.config.YStep;
    
    [gui.data.xData_markers, gui.data.yData_markers] = ...
        meshgrid(0:x_step:(size(gui.data.expValues_mat.YM,1)-1)*x_step, ...
        0:y_step:(size(gui.data.expValues_mat.YM,2)-1)*y_step);
    
    [xData_interp, yData_interp] = ...
        meshgrid(0:x_step:(size(gui.data.YM.expValuesInterpSmoothed,1)-1)*x_step, ...
        0:y_step:(size(gui.data.YM.expValuesInterpSmoothed,2)-1)*y_step);
    
    if gui.config.interpBool
        gui.data.xData_interp = xData_interp./(2^(gui.config.interpFact));
        gui.data.yData_interp = yData_interp./(2^(gui.config.interpFact));
    else
        gui.data.xData_interp = gui.data.xData_markers;
        gui.data.yData_interp = gui.data.yData_markers;
    end
    
    %% Run the 3D maps
    TriDiMap_mapping_plotting(gui.data.xData_interp, gui.data.yData_interp, ...
        gui.data.YM.expValuesInterpSmoothed, 1, normStep, ...
        gui.config.YM_cmin, gui.config.YM_cmax, ...
        gui.config.scaleAxis, gui.config.TriDiView, ...
        gui.config.FontSizeVal, gui.config.Markers, ...
        gui.data.xData_markers, gui.data.yData_markers, ...
        gui.data.expValues_mat.YM, gui.data.YM.expValuesInterp,...
        gui.config.intervalScaleBar);
    
    TriDiMap_mapping_plotting(gui.data.xData_interp, gui.data.yData_interp, ...
        gui.data.H.expValuesInterpSmoothed, 2, normStep, ...
        gui.config.H_cmin, gui.config.H_cmax, ...
        gui.config.scaleAxis, gui.config.TriDiView, ...
        gui.config.FontSizeVal, gui.config.Markers, ...
        gui.data.xData_markers, gui.data.yData_markers, ...
        gui.data.expValues_mat.H, gui.data.H.expValuesInterp,...
        gui.config.intervalScaleBar);
end

if config.flag_data
    assignin('base', 'TriDiMap_results', gui);
    display('Results are saved in the Matlab workspace in TriDiMap_results variable.');
end

end
