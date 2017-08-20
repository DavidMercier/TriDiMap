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
gui.config.version_toolbox = '1.0';
% gui.config.url_help = 'http://nims.readthedocs.org/en/latest/';
% gui.config.pdf_help = 'https://media.readthedocs.org/pdf/nims/latest/nims.pdf';
gui.config.data.data_path = '.\data_indentation';

%% Variables initialization
gui.config.saveFlag = 0;
gui.config.flag_data = 0;
gui.config.cminOld = 0;
gui.config.cmaxOld = 10;

% Path of optical observations
gui.config.plotImage = 0; % Boolean to plot optical observations
% Set paths only if plotImage = 1
gui.config.imageRaw_path = '.\data_image\MatrixBefore_0.png';
gui.config.imageRawBW_path = '.\data_image\MatrixBefore_1.png';
gui.config.imageScaled_path = '.\data_image\MatrixBefore_1-1.png';

%% GUI generation
TriDiMap_GUI(gui);
    
end