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
gui.config.MatlabRelease = v(1).Release;

%% Check License of Statistics Toolbox
license_msg = ['Sorry, no license found for the Matlab ', ...
    'Statistics Toolbox!'];
if  license('checkout', 'Statistics_Toolbox') == 0
    warning(license_msg);
    gui.config.licenceStat_Flag = 0;
else
    gui.config.licenceStat_Flag = 1;
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
gui.config.version_toolbox = '2.0';
% gui.config.url_help = 'http://nims.readthedocs.org/en/latest/';
% gui.config.pdf_help = 'https://media.readthedocs.org/pdf/nims/latest/nims.pdf';
gui.config.data.data_path = '.\data_indentation';
gui.config.data.data_pathNew = '.\data_indentation';
gui.config.image.image_path = '.\data_image';
gui.config.image.image_pathNew = '.\data_image';

%gui.config.image.imageRaw_path = '.\data_image';
%gui.config.image.imageScaled_path = '.\data_image';

%% Variables initialization
gui.config.saveFlag = 0;
gui.config.saveFlagBin = 0;
gui.config.flag_data = 0;
gui.config.flag_image = 0;
gui.config.cminOld = 0;
gui.config.cmaxOld = 10;
gui.config.FontSizeVal = 12;
gui.config.XStep_default = 2;
gui.config.YStep_default = 2;

%% GUI generation
TriDiMap_GUI(gui);
    
end