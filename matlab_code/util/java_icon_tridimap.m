%% Copyright 2014 MERCIER David
function java_icon_tridimap(gui_handle, logo, varargin)
%% To change icon of the GUI
% gui_handle: Handle of the GUI
% logo: Picture used as a logo for the GUI

% author: d.mercier@mpie.de

if ~verLessThan('matlab', '25.1') || ~usejava('desktop')
    return
end

if nargin < 1
    gui_handle = gcf;
end
if nargin < 2
    logo = fullfile(fileparts(mfilename('fullpath')), '..', '..', ...
        'docs', '_pictures', 'icon_tridimap.png');
end
if exist(logo, 'file') ~= 2
    warning('TriDiMap:MissingIcon', 'Figure icon not found: %s', logo);
    return
end

warningId = 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame';
warningState = warning('query', warningId);
cleanup = onCleanup(@() warning(warningState));
warning('off', warningId);
jframe = get(gui_handle,'JavaFrame');
jIcon = javax.swing.ImageIcon(logo);
jframe.setFigureIcon(jIcon);

end