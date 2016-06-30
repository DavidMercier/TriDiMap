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
[pathstr,name,ext] = fileparts(data.filename_data);

%% Loading data
if config.flag.flag_data
    if strcmp (ext, '.xls') == 1 || strcmp (ext, '.xlsx') == 1
        
        %% Results in Excel file
        try
            [dataAll, txtAll] = xlsread(data2import, 'Results');
            dataType = 1; % Excel file from MTS
        catch
            try
                [dataAll, txtAll] = xlsread(data2import, name);
                dataType = 2; % Excel file from Hysitron
            catch
                disp(['No Excel sheet named:', name, 'found in the Excel file !']);
                try
                    [dataAll, txtAll] = xlsread(data2import, 'Feuil1');
                    dataType = 2; % Excel file from Hysitron
                    
                catch
                    disp(['No Excel sheet named:', 'Feuil1', 'found in the Excel file !']);
                    try
                        [dataAll, txtAll] = xlsread(data2import, 'Results');
                        dataType = 2; % Excel file from Hysitron
                    catch
                        disp(['No Excel sheet named:', 'Results', 'found in the Excel file !']);
                    end
                end
            end
        end
        if dataType == 1
            ind_Xstep = find(strcmp(txtAll(1,:), 'X Test Position'));
            ind_Ystep = find(strcmp(txtAll(1,:), 'Y Test Position'));
            ind_YM = find(strncmp(txtAll(1,:), 'Avg Modulus', 10));
            ind_H = find(strncmp(txtAll(1,:), 'Avg Hardness', 10));
            endLines = 3;
        elseif dataType == 2
            ind_Xstep = find(strcmp(txtAll(3,:), 'X(mm)'));
            ind_Ystep = find(strcmp(txtAll(3,:), 'Y(mm)'));
            ind_YM = find(strncmp(txtAll(3,:), 'Er(GPa)', 10));
            ind_H = find(strncmp(txtAll(3,:), 'H(GPa)', 10));
            endLines = 0;
        end
        
        % Rotation angle in degrees
        if ~isempty(ind_Xstep) && ~isempty(ind_Ystep)
            config.data.Xcoord = dataAll(:,ind_Xstep-1);
            
            config.data.N_XStep = sqrt(length(config.data.Xcoord)-endLines); % Wrong if the indentation map is not square !
            config.data.Ycoord = dataAll(:,ind_Ystep-1);
            config.data.N_YStep = sqrt(length(config.data.Ycoord)-endLines); % Wrong if the indentation map is not square !
            if dataType == 1
                deltaXX = abs(config.data.Xcoord(2) - config.data.Xcoord(1));
                deltaYX = abs(config.data.Ycoord(2) - config.data.Ycoord(1));
                deltaYY = abs(config.data.Ycoord(config.data.N_YStep*2) - ...
                    config.data.Ycoord(1));
                deltaXY = abs(config.data.Xcoord(config.data.N_YStep*2) - ...
                    config.data.Xcoord(1));
            elseif dataType == 2
                deltaXX = config.data.XStep_default;
                deltaYX = 0;
                deltaYY = config.data.YStep_default;
                deltaXY = 0;
            end
            angleRotation_X = atand(deltaYX/deltaXX);
            angleRotation_Y = atand(deltaXY/deltaYY);
            if angleRotation_X == angleRotation_Y
                config.data.angleRotation = angleRotation_X;
            else
                error('Wrong calculations of rotationnal angle');
            end
        else
            config.data.angleRotation = config.data.angleRotation_default;
        end
        config.data.angleRotation = mod(config.data.angleRotation, 90);
        
        % X step in microns
        if ~isempty(ind_Xstep)
            config.data.XStep = deltaXX / cosd(config.data.angleRotation);
        else
            config.data.XStep = config.data.XStep_default;
        end
        
        % Y step in microns
        if ~isempty(ind_Ystep)
            config.data.YStep = deltaYY / cosd(config.data.angleRotation);
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
        data.expValues_mat.YM = reshape(data.expValues.YM(1:end-endLines,1),[NX,NY]);
        data.expValues_mat.H = reshape(data.expValues.H(1:end-endLines,1),[NX,NY]);
        
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
