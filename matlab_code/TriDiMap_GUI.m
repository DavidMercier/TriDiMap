%% Copyright 2014 MERCIER David
function TriDiMap_GUI(gui)
%% Function to create the GUI
% gui: Main GUI structure variable

%% Main Window Coordinates Configuration
scrsize = get(0, 'ScreenSize'); % Get screen size
WX = 0.05 * scrsize(3); % X Position (bottom)
WY = 0.10 * scrsize(4); % Y Position (left)
WW = 0.90 * scrsize(3); % Width
WH = 0.80 * scrsize(4); % Height

gui.MainWindows = figure('Name', ...
    (strcat(gui.config.name_toolbox, ...
    ' - Version_', gui.config.version_toolbox)),...
    'NumberTitle', 'off',...
    'Color', [0.9 0.9 0.9],...
    'toolBar', 'figure',...
    'PaperPosition', [0 7 50 15],...
    'Color', [0.906 0.906 0.906],...
    'Position', [WX WY WW WH]);

guidata(gcf, gui);

%% GUI building
gui.handles = TriDiMap_setGUI;
guidata(gcf, gui);

end