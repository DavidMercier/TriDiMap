%% Copyright 2014 MERCIER David
function [config, data] = TriDiMap_loadingData(config)
%% Function to load Excel data from indentation tests

%% Open window to select file
title_importdata_Window = 'File Selector from';
data_path = config.data_path;

[data.filename_data, data.pathname_data, filterindex_data] = ...
    uigetfile('*.xls;*.xlsx', ...
    char(title_importdata_Window), data_path);

if data_path ~= 0
    config.data_path = data_path;
end

dataType = config.dataType;

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
    config.flag_data = 0;
else
    disp(['User selected: ', ...
        fullfile(data.pathname_data, data.filename_data)]);
    [pathstr, name, ext] = fileparts(data.filename_data);
    config.flag_data = 1;
end

data2import = [data.pathname_data, data.filename_data];
[pathstr,name,ext] = fileparts(data.filename_data);

%% Loading data
if config.flag_data
    if strcmp (ext, '.xls') == 1 || strcmp (ext, '.xlsx') == 1
        
        %% Results in Excel file
        if dataType == 1 % Excel file from MTS
            [dataAll, txtAll] = xlsread(data2import, 'Results');
        elseif dataType == 2 % Excel file from Hysitron
            try
                [dataAll, txtAll] = xlsread(data2import, name);
            catch
                disp(['No Excel sheet named:', name, 'found in the Excel file !']);
                try
                    [dataAll, txtAll] = xlsread(data2import, 'Feuil1');
                catch
                    disp(['No Excel sheet named:', 'Feuil1', 'found in the Excel file !']);
                    try
                        [dataAll, txtAll] = xlsread(data2import, 'Results');
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
            if isempty(ind_YM)
                if config.flagSKoss.typeData == 1
                    ind_YM = find(strncmp(txtAll(1,:), 'E Average Over Defined Range', 10));
                elseif config.flagSKoss.typeData == 2
                    ind_YM = find(strncmp(txtAll(1,:), 'Modulus From Unload', 10));
                end
                flagSKoss = 1;
            else
                flagSKoss = 0;
            end
            if isempty(ind_H)
                if config.flagSKoss.typeData == 1
                    ind_H = find(strncmp(txtAll(1,:), 'H Average Over Defined Range', 10));
                elseif config.flagSKoss.typeData == 2
                    ind_H = find(strncmp(txtAll(1,:), 'Hardness From Unload', 10));
                end
                flagSKoss = 1;
            else
                flagSKoss = 0;
            end
            endLines = 3;
        elseif dataType == 2
            ind_Xstep = find(strcmp(txtAll(3,:), 'X(mm)'));
            ind_Ystep = find(strcmp(txtAll(3,:), 'Y(mm)'));
            ind_YM = find(strncmp(txtAll(3,:), 'Er(GPa)', 10));
            ind_H = find(strncmp(txtAll(3,:), 'H(GPa)', 10));
            endLines = 0;
            flagSKoss = 0;
            if isempty(ind_Xstep)
                ind_Xstep = find(strcmp(txtAll(1,:), 'X(mm)'));
                ind_Ystep = find(strcmp(txtAll(1,:), 'Y(mm)'));
                ind_YM = find(strncmp(txtAll(1,:), 'Er(GPa)', 10));
                ind_H = find(strncmp(txtAll(1,:), 'H(GPa)', 10));
            else
                display('No headerlines found !');
            end
        end
        
        % Rotation angle in degrees
        if ~isempty(ind_Xstep) && ~isempty(ind_Ystep)
            if config.N_XStep_default == config.N_YStep_default
                if flagSKoss
                    config.Xcoord = dataAll(:,ind_Xstep);
                else
                    config.Xcoord = dataAll(:,ind_Xstep-1);
                end
                config.N_XStep = sqrt(length(config.Xcoord)-endLines); % Wrong if the indentation map is not square !
                if flagSKoss
                    config.Ycoord = dataAll(:,ind_Ystep);
                else
                    config.Ycoord = dataAll(:,ind_Ystep-1);
                end
                config.N_YStep = sqrt(length(config.Ycoord)-endLines); % Wrong if the indentation map is not square !
            else
                config.Xcoord = dataAll(:,ind_Xstep-1);
                config.Ycoord = dataAll(:,ind_Ystep-1);
                config.N_XStep = config.N_XStep_default;
                config.N_YStep = config.N_YStep_default;
            end
            if dataType == 1
                deltaXX = abs(config.Xcoord(2) - config.Xcoord(1));
                deltaYX = abs(config.Ycoord(2) - config.Ycoord(1));
                deltaYY = abs(config.Ycoord(config.N_YStep) - ...
                    config.Ycoord(1));
					% config.N_YStep*2 ???
                deltaXY = abs(config.Xcoord(config.N_YStep) - ...
                    config.Xcoord(1));
					% config.N_YStep*2 ???
            elseif dataType == 2
                deltaXX = config.XStep_default;
                deltaYX = 0;
                deltaYY = config.YStep_default;
                deltaXY = 0;
            end
            angleRotation_X = round(atand(deltaYX/deltaXX));
            angleRotation_Y = round(atand(deltaXY/deltaYY));
            if angleRotation_X == angleRotation_Y
                config.angleRotation = angleRotation_X;
            else
                display('Wrong calculations of rotationnal angle');
                config.angleRotation = config.angleRotation_default;
            end
        else
            config.angleRotation = config.angleRotation_default;
        end
        config.angleRotation = mod(config.angleRotation, 90);
        
        % X step in microns
        if ~isempty(ind_Xstep)
            config.XStep = deltaXX / cosd(config.angleRotation);
        else
            config.XStep = config.XStep_default;
        end
        
        % Y step in microns
        if ~isempty(ind_Ystep)
            config.YStep = deltaYY / cosd(config.angleRotation);
        else
            config.YStep = config.YStep_default;
        end
        
        % Young's modulus values
        if ~isempty(ind_YM)
            if flagSKoss
                data.expValues.YM = dataAll(:,ind_YM);
            else
                data.expValues.YM = dataAll(:,ind_YM-1);
            end
        else
            data.expValues.YM = NaN;
            config.flag_data = 0;
        end
        % Hardness values
        if ~isempty(ind_H)
            if flagSKoss
                data.expValues.H = dataAll(:,ind_H);
            else
                data.expValues.H = dataAll(:,ind_H-1);
            end
        else
            data.expValues.H = NaN;
            config.flag_data = 0;
        end
        
    end
    
    if config.flag_data
        NX = config.N_XStep;
        NY = config.N_YStep;
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