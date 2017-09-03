%% Copyright 2014 MERCIER David
function [config, image] = TriDiMap_loadingImage
%% Function to load binarized microscopical image

g = guidata(gcf);
config = g.config;
h = g.handles;

%% Open window to select file
title_importimage_Window = 'Image Selector from';

if ~isempty(config.image.image_pathNew)
    image_path = config.image.image_pathNew;
else
    image_path = config.image.image_path;
end


[image.filename_image, image.pathname_image, filterindex_image] = ...
    uigetfile('*.png;*.jpg;*.jpeg;*.tiff', ...
    char(title_importimage_Window), image_path);

if image_path ~= 0
    g.config.image.image_path = image_path;
end

%% Handle canceled file selection
if image.filename_image == 0
    image.filename_image = '';
end
if image.pathname_image == 0
    image.pathname_image = '';
else
    config.image_path = image.pathname_image;
end

if isequal(image.filename_image,'')
    disp('User selected Cancel');
    image.pathname_image = '';
    image.filename_image = 'no_image';
    ext = '.nul';
    config.flag_image = 0;
    config.flagImageValid = 0;
else
    disp(['User selected: ', ...
        fullfile(image.pathname_image, image.filename_image)]);
    [pathstr, name, ext] = fileparts(image.filename_image);
    config.flag_image = 1;
end

image2import = [image.pathname_image, image.filename_image];
[pathstr,name,ext] = fileparts(image.filename_image);

config.name = name;
config.pathStr = image.pathname_image;
config.image.image_pathNew = image.pathname_image;
set(g.handles.openimage_str_GUI, 'String', image.pathname_image);

%% Check Image
image.image2use = imread([image.pathname_image, image.filename_image]);
config.flagImageValid = 1;

%% Loading image
if config.flag_image
    
g.image = image;
g.config = config;
g.handles = h;
guidata(gcf, g);
if config.flagImageValid
    TriDiMap_runBin;
end
end