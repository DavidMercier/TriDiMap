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
gui.config.rawData = 0; % Boolean to plot raw dataset (no interpolation, no smoothing...)
gui.config.TriDiView = 0; % Boolean to set plots (0 = 1 map / 1 = 3 maps)
gui.config.normalizationStep = 0;
% 0 if no normalization, 1 if normalization with minimal value, 2 with
% the maximum value and 3 with the mean value
gui.config.translationStep = 0; % 0 if no normalization and 1 if normalization step

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

% Map / Colorbar setting
gui.config.contourPlot = 1; % Boolean to plot contours
gui.config.Markers = 1; % Boolean to plot markers
gui.config.intervalScaleBar_H = 15; % Number of interval on the scale bar for hardness
gui.config.intervalScaleBar_YM = 10; % Number of interval on the scale bar for elastic modulus
% 0 if continuous scalebar, and 5 to 10 to set interval number
gui.config.scaleAxis = 1; % Boolean to set color scale
gui.config.H_cmin = 0; % in GPa
gui.config.H_cmax = 15; %in GPa
gui.config.YM_cmin = 150; % in GPa
gui.config.YM_cmax = 350; % in GPa
gui.config.FontSizeVal = 14;

if gui.config.rawData
    gui.config.normalizationStep = 0;
    gui.config.translationStep = 0;
    gui.config.noNan = 0;
    gui.config.interpBool = 0;
    gui.config.smoothBool = 0;
    gui.config.binarizedGrid = 0;
end

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
    
    %% Translation step
    if gui.config.translationStep && ~gui.config.normalizationStep
        % Normalization of elastic modulus
        gui.data.expValues_mat_average.YM = mean(mean(gui.data.expValues_mat.YM));
        gui.data.expValues_mat_norm.YM = gui.data.expValues_mat.YM - gui.data.expValues_mat_average.YM;
        % Normalization of hardness
        gui.data.expValues_mat_average.H = mean(mean(gui.data.expValues_mat.H));
        gui.data.expValues_mat_norm.H = gui.data.expValues_mat.H - gui.data.expValues_mat_average.H;
    elseif gui.config.translationStep && gui.config.normalizationStep
        display('Translation not possible because normalization is active.');
    end
    
    %% Normalization of dataset
    if gui.config.normalizationStep > 0 && ~gui.config.translationStep
        if gui.config.normalizationStep == 1
            gui.data.expValues_mat.YM = gui.data.expValues_mat.YM/min(min(gui.data.expValues_mat.YM));
            gui.data.expValues_mat.H = gui.data.expValues_mat.H/min(min(gui.data.expValues_mat.H));
        elseif gui.config.normalizationStep == 2
            gui.data.expValues_mat.YM = gui.data.expValues_mat.YM/max(max(gui.data.expValues_mat.YM));
            gui.data.expValues_mat.H = gui.data.expValues_mat.H/max(max(gui.data.expValues_mat.H));
        elseif gui.config.normalizationStep == 3
            gui.data.expValues_mat.YM = gui.data.expValues_mat.YM/mean(mean(gui.data.expValues_mat.YM));
            gui.data.expValues_mat.H = gui.data.expValues_mat.H/mean(mean(gui.data.expValues_mat.H));
        end
        
    elseif gui.config.normalizationStep && transStep
        display('Normalization not possible because translation is active.');
    end
    
    %% Interpolating, smoothing and binarizing steps of dataset
    if gui.config.translationStep
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
    
    gui.data.xData = 0:x_step:(size(gui.data.expValues_mat.YM,1)-1)*x_step;
    gui.data.yData = 0:y_step:(size(gui.data.expValues_mat.YM,2)-1)*y_step;
    
    [gui.data.xData_markers, gui.data.yData_markers] = ...
        meshgrid(gui.data.xData, gui.data.yData);
    
    [xData_interp, yData_interp] = ...
        meshgrid(0:x_step:(size(gui.data.YM.expValuesInterpSmoothed,1)-1)*x_step, ...
        0:y_step:(size(gui.data.YM.expValuesInterpSmoothed,2)-1)*y_step);
    
    if gui.config.rawData
        gui.data.xData_interp = gui.data.xData;
        gui.data.yData_interp = gui.data.yData;
    else
        if gui.config.interpBool
            gui.data.xData_interp = xData_interp./(2^(gui.config.interpFact));
            gui.data.yData_interp = yData_interp./(2^(gui.config.interpFact));
        else
            gui.data.xData_interp = gui.data.xData_markers;
            gui.data.yData_interp = gui.data.yData_markers;
        end
    end
    
    %% Run the 3D maps
    TriDiMap_mapping_plotting(gui.data.xData_interp, gui.data.yData_interp, ...
        gui.data.YM.expValuesInterpSmoothed, 1, gui.config.normalizationStep, ...
        gui.config.YM_cmin, gui.config.YM_cmax, ...
        gui.config.scaleAxis, gui.config.TriDiView, ...
        gui.config.FontSizeVal, gui.config.Markers, ...
        gui.data.xData_markers, gui.data.yData_markers, ...
        gui.data.expValues_mat.YM, gui.data.YM.expValuesInterp, ...
        gui.config.intervalScaleBar_YM, gui.config.rawData, ...
        gui.config.contourPlot);
    
    TriDiMap_mapping_plotting(gui.data.xData_interp, gui.data.yData_interp, ...
        gui.data.H.expValuesInterpSmoothed, 2, gui.config.normalizationStep, ...
        gui.config.H_cmin, gui.config.H_cmax, ...
        gui.config.scaleAxis, gui.config.TriDiView, ...
        gui.config.FontSizeVal, gui.config.Markers, ...
        gui.data.xData_markers, gui.data.yData_markers, ...
        gui.data.expValues_mat.H, gui.data.H.expValuesInterp, ...
        gui.config.intervalScaleBar_H, gui.config.rawData, ...
        gui.config.contourPlot);
    
    %% Fraction calculations
    if gui.config.binarizedGrid > 0
        TriDiMap_fractionData(gui.data.YM.expValuesInterpSmoothed, 1);
        TriDiMap_fractionData(gui.data.H.expValuesInterpSmoothed, 2);
    end
end

%% Saving results
if config.flag_data
    assignin('base', 'TriDiMap_results', gui);
    display('Results are saved in the Matlab workspace in TriDiMap_results variable.');
end

end
