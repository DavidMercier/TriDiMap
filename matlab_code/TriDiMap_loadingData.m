%% Copyright 2014 MERCIER David
function [config, data] = TriDiMap_loadingData(config)
%% Function to load Excel data from indentation tests

%% Open window to select file
title_importdata_Window = 'File Selector from';
data_path = config.data.data_path;

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
        
        %% Columns in 'Results' sheet !
        [dataAll, txtAll] = xlsread(data2import, 'Results');
        ind_Xstep = find(strcmp(txtAll(1,:), 'X Test Position'));
        ind_Ystep = find(strcmp(txtAll(1,:), 'Y Test Position'));
        ind_YM = find(strncmp(txtAll(1,:), 'Avg Modulus', 10));
        ind_H = find(strncmp(txtAll(1,:), 'Avg Hardness', 10));
        
        % Rotation angle in degrees
        if ~isempty(ind_Xstep) && ~isempty(ind_Ystep)
            config.data.Xcoord = dataAll(:,ind_Xstep-1);
            config.data.N_XStep = sqrt(length(config.data.Xcoord)-3); % Wrong if the indentation map is not square !
            config.data.Ycoord = dataAll(:,ind_Ystep-1);
            config.data.N_YStep = sqrt(length(config.data.Ycoord)-3); % Wrong if the indentation map is not square !
            deltaX = abs(config.data.Xcoord(2) - config.data.Xcoord(1));
            deltaY = abs(config.data.Ycoord(config.data.N_YStep+1) - ...
                config.data.Ycoord(1));
            config.data.angleRotation = atand(deltaY/deltaX);
        else
            config.data.angleRotation = config.data.angleRotation_default;
        end
        config.data.angleRotation = mod(config.data.angleRotation, 90);
        
        % X step in microns
        if ~isempty(ind_Xstep)
            config.data.XStep = deltaX / cosd(config.data.angleRotation);
        else
            config.data.XStep = config.data.XStep_default;
        end
        
        % Y step in microns
        if ~isempty(ind_Ystep)
            config.data.YStep = deltaY / cosd(config.data.angleRotation);
        else
            config.data.YStep = config.data.YStep_default;
        end
        
        % Young's modulus values
        if ~isempty(ind_YM)
            data.expValues.YM = dataAll(:,ind_YM-1);
        else
            data.expValues.YM = NaN;
            config.flag.flag_data = 0;
        end
        % Hardness values
        if ~isempty(ind_H)
            data.expValues.H = dataAll(:,ind_H-1);
        else
            data.expValues.H = NaN;
            config.flag.flag_data = 0;
        end
    end
    
    if config.flag.flag_data
        NX = config.data.N_XStep;
        NY = config.data.N_YStep;
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

end