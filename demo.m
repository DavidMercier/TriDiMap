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

%% Check Matlab version
v = ver;
try
    Release = v.Release;
    gui.config.MatlabRelease = Release;
catch
    gui.config.MatlabRelease = 'empty';
end

%% Check License of Statistics Toolbox
license_msg_1 = ['Sorry, no license found for the Matlab ', ...
    'Statistics Toolbox!'];
if  license('checkout', 'Statistics_Toolbox') == 0
    warning(license_msg_1);
    gui.config.licenceStat_Flag = 0;
else
    gui.config.licenceStat_Flag = 1;
end

license_msg_2 = ['Sorry, no license found for the Matlab ', ...
    'Optimization Toolbox™ !'];
if  license('checkout', 'Optimization_Toolbox') == 0
    warning(license_msg_2);
    gui.config.licenceOpt_Flag = 0;
else
    gui.config.licenceOpt_Flag = 1;
end

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

%% Set Toolbox version and help paths
gui.config.name_toolbox = 'TriDiMap';
gui.config.version_toolbox = '3.0';
% gui.config.url_help = 'http://tridimap.readthedocs.org/en/latest/';
% gui.config.pdf_help = 'https://media.readthedocs.org/pdf/tridimap/latest/tridimap.pdf';
gui.config.data.data_path = '.\data_indentation';
gui.config.data.data_pathNew = '.\data_indentation';
gui.config.image.image_path = '.\data_image';
gui.config.image.image_pathNew = '.\data_image';

%% Variables initialization
gui.config.data_path = 0;
gui.config.saveFlag = 0;
gui.config.saveFlagBin = 0;
gui.config.sizeCheck = 0;
gui.config.flag_data = 0;
gui.config.flag_image = 0;
gui.config.cminOld = 0;
gui.config.cmaxOld = 10;
gui.config.FontSizeVal = 12;
gui.config.XStep_default = 2;
gui.config.YStep_default = 2;
gui.config.flagZplot = 0;
gui.config.property = 2;

%% GUI generation
TriDiMap_GUI(gui);

%% Set logo of the GUI
java_icon_tridimap;
    
end