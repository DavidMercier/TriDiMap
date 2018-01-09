%% Copyright 2014 MERCIER David
function java_icon_popin(gui_handle, logo, varargin)
%% To change icon of the GUI
% gui_handle: Handle of the GUI
% logo: Picture used as a logo for the GUI

% author: d.mercier@mpie.de

if nargin < 2
    logo = fullfile('doc', '_pictures', 'icon_tridimap.png');
end

if nargin < 1
    gui_handle = gcf;
end

wrn = warning;
wrn_txt = wrn.identifier;
warning('off', wrn_txt);
jframe = get(gui_handle,'JavaFrame');
jIcon = javax.swing.ImageIcon(logo);
jframe.setFigureIcon(jIcon);
warning(wrn);

end