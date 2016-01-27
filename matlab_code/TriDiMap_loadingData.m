%% Copyright 2014 MERCIER David
function [config, data] = TriDiMap_loadingData(data_path, NX, NY)
%% Function to load Excel data from indentation tests

%% Open window to select file
title_importdata_Window = 'File Selector from';

[data.filename_data, data.pathname_data, filterindex_data] = ...
    uigetfile('*.xls;*.xlsx', ...
    char(title_importdata_Window), data_path);

if data_path ~= 0
    config.data_path = data_path;
end

%% Handle canceled file selection
if data.filename_data == 0
    data.filename_data = '';
end
if data.pathname_data == 0
    data.pathname_data = '';
else
    config.data_path = data.pathname_data;
end

if isequal(data.filename_data,'')
    disp('User selected Cancel');
    data.pathname_data = 'no_data';
    data.filename_data = 'no_data';
    ext = '.nul';
    config.flag.flag_data = 0;
else
    disp(['User selected', ...
        fullfile(data.pathname_data, data.filename_data)]);
    [pathstr, name, ext] = fileparts(data.filename_data);
    config.flag.flag_data = 1;
end

data2import = [data.pathname_data, data.filename_data];

%% Loading data
if config.flag.flag_data
    if strcmp (ext, '.xls') == 1 || strcmp (ext, '.xlsx') == 1
        [dataAll, txtAll] = xlsread(data2import, 'Results');
        % First column is text in 'Results' sheet !
        data.expValues.YM = dataAll(:,1);
        data.expValues.H = dataAll(:,2);
    end
    
    % Vector to matrix (last three columns are average values in 'Results' sheet
    data.expValues_mat.YM = reshape(data.expValues.YM(1:end-3,1),[NX,NY]);
    data.expValues_mat.H = reshape(data.expValues.H(1:end-3,1),[NX,NY]);
    
    % Flip even columns to respect nanoindentation pattern
    for evenIndex = 2:2:NY
        data.expValues_mat.YM(:,evenIndex) = ...
            flipud(data.expValues_mat.YM(:,evenIndex));
        data.expValues_mat.H(:,evenIndex) = ...
            flipud(data.expValues_mat.H(:,evenIndex));
    end
end

end