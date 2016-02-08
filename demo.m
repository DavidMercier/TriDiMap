%% Copyright 2014 MERCIER David
function gui = demo
%% Function to run the Matlab code for the 3D mapping of indentation data

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

gui.config.data.data_path = '.\data_indentation';

%% Set default variables
gui.config.data.normalizationStep = 0; % 0 if no normalization and 1 if normalization step
gui.config.data.smooth_NC = 1; % Number of points used to smooth rows
gui.config.data.smooth_NR = 1; % Number of points used to smooth columns
gui.config.data.N_XStep_default = 10; % Default number of steps along X axis
gui.config.data.N_YStep_default = 10; % Default number of steps along Y axis
gui.config.data.XStep_default = 10; % Default value of X step in microns
gui.config.data.YStep_default = 10; % Default value of Y step in microns
gui.config.data.angleRotation_default = 0; % Default rotation angle of the indentation map in degrees
gui.config.H_cmin = 0;
gui.config.H_cmax = 20;
gui.config.YM_cmin = 0;
gui.config.YM_cmax = 300;
gui.config.scaleAxis = 0; % Boolean to set color scale
gui.config.interp = 1; % Boolean to set interpolation step

% REMARKS %
% Don't set a too high number of points to smooth rows and columns...
% or the absolute maximum/minimum values are decreasing !

%% Load data from Excel files
[config, gui.data] = ...
    TriDiMap_loadingData(gui.config);

gui.config.data_path = config.data_path;
gui.config.flag.flag_data = config.flag.flag_data;
gui.config.data.N_XStep = config.data.N_XStep;
gui.config.data.N_YStep = config.data.N_YStep;
gui.config.data.XStep = config.data.XStep;
gui.config.data.YStep = config.data.YStep;

if gui.config.flag.flag_data
    %% Normalization step
    normStep = gui.config.data.normalizationStep;
    if normStep
        % Normalization of elastic modulus
        gui.data.expValues_mat_average.YM = mean(mean(gui.data.expValues_mat.YM));
        gui.data.expValues_mat_norm.YM = gui.data.expValues_mat.YM - gui.data.expValues_mat_average.YM;
        % Normalization of hardness
        gui.data.expValues_mat_average.H = mean(mean(gui.data.expValues_mat.H));
        gui.data.expValues_mat_norm.H = gui.data.expValues_mat.H - gui.data.expValues_mat_average.H;
    end
    
    %% Run the 3D maps
    if normStep
        TriDiMap_mapping_plotting(gui.config.data.XStep, gui.config.data.YStep, ...
            gui.config.data.smooth_NR, gui.config.data.smooth_NC, ...
            gui.data.expValues_mat_norm.YM, 1, normStep, gui.config.interp, ...
            gui.config.YM_cmin, gui.config.YM_cmax, gui.config.scaleAxis);
        TriDiMap_mapping_plotting(gui.config.data.XStep, gui.config.data.YStep, ...
            gui.config.data.smooth_NR, gui.config.data.smooth_NC, ...
            gui.data.expValues_mat_norm.H, 2, normStep, gui.config.interp,  ...
            gui.config.H_cmin, gui.config.H_cmax, gui.config.scaleAxis);
    else
        TriDiMap_mapping_plotting(gui.config.data.XStep, gui.config.data.YStep, ...
            gui.config.data.smooth_NR, gui.config.data.smooth_NC, ...
            gui.data.expValues_mat.YM, 1, normStep, gui.config.interp, ...
            gui.config.YM_cmin, gui.config.YM_cmax, gui.config.scaleAxis);
        TriDiMap_mapping_plotting(gui.config.data.XStep, gui.config.data.YStep, ...
            gui.config.data.smooth_NR, gui.config.data.smooth_NC, ...
            gui.data.expValues_mat.H, 2, normStep, gui.config.interp,  ...
            gui.config.H_cmin, gui.config.H_cmax, gui.config.scaleAxis);
    end
end
end