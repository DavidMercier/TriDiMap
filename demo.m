%% Copyright 2014 MERCIER David
function demo
%% Function to run the Matlab code for the 3D mapping of indentation data
%Black = [0,0,0] / White  = [255,255,255];

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
gui.config.data_path = 'N:\Projects\2015_NoChrome_JFVH\160523_NI_MO\2016-05-20 Batch #00001\NC493_matrix\';
%gui.config.data_path = 'N:\Projects\2015_NoChrome_JFVH\160527_NI_MO\NC493_matrix625indents\NC493_matrix625indents_50nm.xls';

gui.config.imageRaw_path = 'N:\Projects\2015_NoChrome_JFVH\160811_MO_Matlab\MatrixBefore_0.png';
gui.config.imageRawBW_path = 'N:\Projects\2015_NoChrome_JFVH\160811_MO_Matlab\MatrixBefore_1.png';
gui.config.imageScaled_path = 'N:\Projects\2015_NoChrome_JFVH\160811_MO_Matlab\MatrixBefore_1-1.png';

%% Set default variables
gui.config.rawData = 1; % Boolean to plot raw dataset (no interpolation, no smoothing...)
gui.config.plotImage = 1;
gui.config.TriDiView = 0; % Boolean to set plots (0 = 1 map / 1 = 3 maps)
gui.config.normalizationStep = 0;
% 0 if no normalization, 1 if normalization with minimal value, 2 with
% the maximum value and 3 with the mean value
gui.config.translationStep = 0; % 0 if no translation and 1 if translation step

% Smoothing and Interpolation
gui.config.noNan = 1; % Boolean to remove NaN values (blank pixels)
gui.config.interpBool = 0; % Boolean to activate interpolation
gui.config.interpFact = 2; % Factor of interpolation
% 0 for no interpolation, 1 or 2 is the best
gui.config.smoothBool = 0; % Boolean to correct values after smoothing
gui.config.smoothFact = 2; % Number of points used to smooth rows and columns
% 0 = no smoothing and best is 1 or 2
gui.config.binarizedGrid = 0; % Variable to binarize values of the grid
% 0 = no binarization / 1 = smoothed binarization / 2 = binarization

% REMARKS %
% Don't set a too high number of points to smooth rows and columns...
% or the absolute maximum/minimum values are decreasing !

% Configuration of the indentation map
gui.config.N_XStep_default = 25; % Default number of steps along X axis
gui.config.N_YStep_default = 25; % Default number of steps along Y axis
gui.config.XStep_default = 2; % Default value of X step in microns
gui.config.YStep_default = 2;% Default value of Y step in microns
gui.config.angleRotation_default = 0; % Default rotation angle of the indentation map in degrees

% Map / Colorbar setting
gui.config.contourPlot = 0; % Boolean to plot contours
gui.config.Markers = 0; % Boolean to plot markers
gui.config.intervalScaleBar_H = 9; % Number of interval on the scale bar for hardness
gui.config.intervalScaleBar_YM = 10; % Number of interval on the scale bar for elastic modulus
% 0 if continuous scalebar, and 5 to 10 to set interval number
gui.config.scaleAxis = 1; % Boolean to set color scale
gui.config.H_cmin = 3; % in GPa
gui.config.H_cmax = 12; %in GPa
gui.config.YM_cmin = 150; % in GPa
gui.config.YM_cmax = 250; % in GPa
gui.config.FontSizeVal = 14;
gui.config.Legend = {'Ni', 'SiC'};
gui.config.LegendMatch = {'Match', 'No match'};

%criterion = mean(mean(data)) ??
criterion_YM = 250;
%criterion_YM = mean(mean(gui.data.YM.expValuesInterpSmoothed));
criterion_H = 7.5;
%criterion_H = mean(mean(gui.data.YM.expValuesInterpSmoothed));
    
if gui.config.rawData
    %gui.config.smoothBool = 0;
    %gui.config.binarizedGrid = 0;
    gui.config.Markers = 0;
    %gui.config.intervalScaleBar_H = 2;
    %gui.config.intervalScaleBar_YM = 2;
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
            gui.config.binarizedGrid, criterion_YM);
        
        [gui.data.H.expValuesInterp, gui.data.H.expValuesSmoothed, ...
            gui.data.H.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            gui.data.expValues_mat_norm.H, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid, criterion_H);
    else
        [gui.data.YM.expValuesInterp, gui.data.YM.expValuesSmoothed, ...
            gui.data.YM.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            gui.data.expValues_mat.YM, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid, criterion_YM);
        
        [gui.data.H.expValuesInterp, gui.data.H.expValuesSmoothed, ...
            gui.data.H.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            gui.data.expValues_mat.H, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid, criterion_H);
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
    if gui.config.plotImage == 0
        
        TriDiMap_mapping_plotting(gui.data.xData_interp, gui.data.yData_interp, ...
            gui.data.YM.expValuesInterpSmoothed, 1, gui.config.normalizationStep, ...
            gui.config.YM_cmin, gui.config.YM_cmax, ...
            gui.config.scaleAxis, gui.config.TriDiView, ...
            gui.config.FontSizeVal, gui.config.Markers, ...
            gui.data.xData_markers, gui.data.yData_markers, ...
            gui.data.expValues_mat.YM, gui.data.YM.expValuesInterp, ...
            gui.config.intervalScaleBar_YM, gui.config.rawData, ...
            gui.config.contourPlot, gui.config.Legend);
        
        TriDiMap_mapping_plotting(gui.data.xData_interp, gui.data.yData_interp, ...
            gui.data.H.expValuesInterpSmoothed, 2, gui.config.normalizationStep, ...
            gui.config.H_cmin, gui.config.H_cmax, ...
            gui.config.scaleAxis, gui.config.TriDiView, ...
            gui.config.FontSizeVal, gui.config.Markers, ...
            gui.data.xData_markers, gui.data.yData_markers, ...
            gui.data.expValues_mat.H, gui.data.H.expValuesInterp, ...
            gui.config.intervalScaleBar_H, gui.config.rawData, ...
            gui.config.contourPlot, gui.config.Legend);
    end
    
    %% Fraction calculations
    
    if gui.config.binarizedGrid > 0
        TriDiMap_fractionData(gui.data.YM.expValuesInterpSmoothed, 1, criterion_YM);
        TriDiMap_fractionData(gui.data.H.expValuesInterpSmoothed, 2, criterion_H);
    end
end

%% Difference map
if config.flag_data
    if gui.config.plotImage == 1
        
        YM_binarized = zeros(gui.config.N_XStep_default, gui.config.N_YStep_default);
        H_binarized = zeros(gui.config.N_XStep_default, gui.config.N_YStep_default);
        for ii = 1:1:gui.config.N_XStep_default
            for jj = 1:1:gui.config.N_YStep_default
                if gui.data.YM.expValuesInterpSmoothed(ii,jj) > criterion_YM
                    YM_binarized(ii,jj) = 255;
                else
                    YM_binarized(ii,jj) = 0;
                end
                if gui.data.H.expValuesInterpSmoothed(ii,jj) > criterion_H
                    H_binarized(ii,jj) = 255;
                else
                    H_binarized(ii,jj) = 0;
                end
            end
        end
        
        TriDiMap_mapping_plotting(gui.data.xData_interp, gui.data.yData_interp, ...
            YM_binarized, 1, gui.config.normalizationStep, ...
            gui.config.YM_cmin, gui.config.YM_cmax, ...
            gui.config.scaleAxis, gui.config.TriDiView, ...
            gui.config.FontSizeVal, gui.config.Markers, ...
            gui.data.xData_markers, gui.data.yData_markers, ...
            gui.data.expValues_mat.YM, gui.data.YM.expValuesInterp, ...
            gui.config.intervalScaleBar_YM, gui.config.rawData, ...
            gui.config.contourPlot, gui.config.Legend);
        
        TriDiMap_mapping_plotting(gui.data.xData_interp, gui.data.yData_interp, ...
            H_binarized, 2, gui.config.normalizationStep, ...
            gui.config.H_cmin, gui.config.H_cmax, ...
            gui.config.scaleAxis, gui.config.TriDiView, ...
            gui.config.FontSizeVal, gui.config.Markers, ...
            gui.data.xData_markers, gui.data.yData_markers, ...
            gui.data.expValues_mat.H, gui.data.H.expValuesInterp, ...
            gui.config.intervalScaleBar_H, gui.config.rawData, ...
            gui.config.contourPlot, gui.config.Legend);
        
        %% Plot figure
        gui.data.picture_raw = flipud(imread(gui.config.imageRaw_path));
        gui.data.picture_rawBW = flipud(imread(gui.config.imageRawBW_path));
        gui.data.picture_scaled = flipud(imread(gui.config.imageScaled_path));
        
        xData_interp = 0:(gui.config.N_XStep_default-1)*gui.config.XStep_default/size(gui.data.picture_raw,1):(gui.config.N_XStep_default-1) * gui.config.XStep_default;
        yData_interp = xData_interp;
        
        scrsize = get(0, 'ScreenSize'); % Get screen size
        WX = 0.15 * scrsize(3); % X Position (bottom)
        WY = 0.10 * scrsize(4); % Y Position (left)
        WW = 0.70 * scrsize(3); % Width
        WH = 0.80 * scrsize(4); % Height
        
        f(3) = figure('position', [WX, WY, WW, WH]);
        hi(3) = image(gui.data.picture_raw);
        hold on;
        axisMap([], 'Raw microstructural map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        hold off;
        
        f(4) = figure('position', [WX, WY, WW, WH]);
        hi(4) = imagesc(gui.data.picture_raw, 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(flipud(gray), 'Raw microstructural map (grayscale)', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        hold off;
        
        % Use im2bw if ImageProcessing Toolbox
        f(5) = figure('position', [WX, WY, WW, WH]);
        hi(5) = imagesc(gui.data.picture_rawBW, 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Binary microstructural map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.Legend, gui.config.FontSizeVal);
        hold off;
        fracBW = sum(sum(gui.data.picture_rawBW))/(size(gui.data.picture_rawBW,1)*size(gui.data.picture_rawBW,2)*255);
        display('Fraction of particles (raw data):');
        disp(fracBW);
        display('Fraction of matrix (raw data):');
        disp(1-fracBW);
        
        f(6) = figure('position', [WX, WY, WW, WH]);
        hi(6) = imagesc(gui.data.picture_scaled, 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Microstructural map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.Legend, gui.config.FontSizeVal);
        hold off;
        fracBW = sum(sum(gui.data.picture_scaled))/(size(gui.data.picture_scaled,1)*size(gui.data.picture_scaled,2)*255);
        display('Fraction of particles (pixelized data):');
        disp(fracBW);
        display('Fraction of matrix (pixelized data):');
        disp(1-fracBW);
        
        %% Calculation of maps difference
        %gui.results.diffYM = (rot90(YM_binarized) == flipud(gui.data.picture_scaled));
        gui.results.diffYM = (rot90(int8(YM_binarized))) - (flipud(int8(gui.data.picture_scaled)));
        gui.results.diffYM(gui.results.diffYM~=0)=1;
        
        %gui.results.diffH = (rot90(H_binarized) == flipud(gui.data.picture_scaled));
        gui.results.diffH = (rot90(int8(H_binarized))) - (flipud(int8(gui.data.picture_scaled)));
        gui.results.diffH(gui.results.diffH~=0)=1;
        
        diff_YM_error = sum(sum(gui.results.diffYM))/(gui.config.N_XStep_default * gui.config.N_YStep_default);
        diff_H_error = sum(sum(gui.results.diffH))/(gui.config.N_XStep_default * gui.config.N_YStep_default);
        % Display % of error - If 0, then perfect match and if 1 perfect mismatch.
        display(diff_YM_error); display(diff_H_error);
        
        f(7) = figure('position', [WX, WY, WW, WH]);
        hi(7) = imagesc(flipud(gui.results.diffYM), 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Phase-Elastic modulus difference map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);
        hold off;
        
        f(8) = figure('position', [WX, WY, WW, WH]);
        hi(8) = imagesc(flipud(gui.results.diffH), 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Phase-Hardness difference map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);
        hold off;
        
        
    end
end

%% Saving results
if config.flag_data
    assignin('base', 'TriDiMap_results', gui);
    display('Results are saved in the Matlab workspace in TriDiMap_results variable.');
end

end