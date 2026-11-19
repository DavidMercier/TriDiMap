%% Copyright 2014 MERCIER David
function [config, data] = TriDiMap_loadingMeanData(init, varargin)
%% Function to load Excel data from indentation tests
if nargin < 1
    init = 0;
end

TriDiMap_getParam;

g = guidata(gcf);
config = g.config;
h = g.handles;
config.SliceFlagData = 0;
if strcmp(get(g.handles.binarization_GUI, 'String'), 'BINARIZATION')
    set(h.cb_plotSectMap_GUI, 'Value', 0);
end

%% Open window to select file
if ~init
    title_importdata_Window = 'File Selector from';
    
    if ~isempty(config.data.data_pathNew)
        data_path = config.data.data_pathNew;
    else
        data_path = config.data.data_path;
    end
    
    if ~isempty(varargin)
        [data.pathname_data, fileName, fileExtension] = fileparts(varargin{1});
        data.filename_data = [fileName, fileExtension];
    else
        fileFilter = '*.xls;*.xlsx';
        if get(h.pm_set_file, 'Value') == 5
            fileFilter = '*.xls;*.xlsx;*.csv';
        end
        [data.filename_data, data.pathname_data, filterindex_data] = ...
            uigetfile(fileFilter, char(title_importdata_Window), data_path);
    end
    
    if data_path ~= 0
        g.config.data.data_path = data_path;
    end
else
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    data.pathname_data = fullfile(root, 'data_indentation');
    data.filename_data = 'MTS_example1_25x25.xls';
end

dataType = get(h.pm_set_file, 'Value');
data.mappingDataType = dataType;

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
    data.pathname_data = '';
    data.filename_data = 'no_data';
    ext = '.nul';
    config.flag_data = 0;
    config.flagValid = 0;
else
    disp(['User selected: ', ...
        fullfile(data.pathname_data, data.filename_data)]);
    [pathstr, name, ext] = fileparts(data.filename_data);
    config.flag_data = 1;
end

data2import = fullfile(data.pathname_data, data.filename_data);
[pathstr,name,ext] = fileparts(data.filename_data);

config.name = name;
config.pathStr = data.pathname_data;
config.data.data_pathNew = data.pathname_data;
set(g.handles.opendata_str_GUI, 'String', data.pathname_data);

%% Loading data
if config.flag_data && dataType == 5
    if ~strcmp(get(h.binarization_GUI, 'String'), 'BINARIZATION')
        config.flag_data = 0;
        config.flagValid = 0;
        errordlg('Return to the mapping window before importing irregular XY data.', 'Irregular XY');
        return
    end
    try
        measured = TriDiMap_readIrregularData(data2import);
    catch exception
        config.flag_data = 0;
        config.flagValid = 0;
        errordlg(exception.message, 'Invalid irregular XY data');
        return
    end
    measured.filename_data = data.filename_data;
    measured.pathname_data = data.pathname_data;
    measured.mappingDataType = dataType;
    data = measured;
    count = size(data.coordinates, 1);
    config.N_XStep = count;
    config.N_YStep = 1;
    config.flagValid = 1;
    config.flagZplot = 0;
    config.flag_ClusterGauss = 0;
    config.minVal = NaN;
    config.maxVal = NaN;
    set(h.value_MinVal_GUI, 'String', num2str(nanmin(data.expValues.H)));
    set(h.value_MaxVal_GUI, 'String', num2str(nanmax(data.expValues.H)));
    set([h.value_MinXCrop_GUI, h.value_MinYCrop_GUI, h.value_MaxYCrop_GUI], 'String', '1');
    set(h.value_MaxXCrop_GUI, 'String', num2str(count));
    set(h.unitLength_GUI, 'Value', 2);
    set(h.unitProp_GUI, 'Value', 2);
    set(h.property_GUI, 'Value', 2);
    set(h.pm_pixData_GUI, 'Value', 1);
    g.data = data;
    g.config = config;
    guidata(h.MainWindow, g);
    TriDiMap_runPlot;
    return
end
if config.flag_data
    if strcmp (ext, '.xls') == 1 || strcmp (ext, '.xlsx') == 1
        
        %% Results in Excel file
        try
            [dataAll, txtAll, raw] = TriDiMap_readMeanSheet(data2import, 'Results');
        catch
            disp(['No Excel sheet named:', 'Results', ' found in the Excel file !']);
            try
                [dataAll, txtAll, raw] = TriDiMap_readMeanSheet(data2import, 'Feuil1');
            catch
                disp(['No Excel sheet named:', 'Feuil1', ' found in the Excel file !']);
                try
                    [dataAll, txtAll, raw] = TriDiMap_readMeanSheet(data2import, 'Sheet1');
                catch
                    disp(['No Excel sheet named:', 'Sheet1', ' found in the Excel file !']);
                    try
                        [dataAll, txtAll, raw] = TriDiMap_readMeanSheet(data2import, name);
                    catch
                        disp(['No Excel sheet named:', name, ' found in the Excel file !']);
                        try
                            [dataAll, txtAll, raw] = TriDiMap_readMeanSheet(data2import);
                        catch exception
                            config.flag_data = 0;
                            config.flagValid = 0;
                            g.config = config;
                            guidata(h.MainWindow, g);
                            errordlg(sprintf('Unable to read Excel file:\n%s\n\n%s', ...
                                data2import, exception.message), 'Import failed');
                            return
                        end
                    end
                end
            end
        end
        
        try
            if dataType == 1 % Excel file from MTS
                ind_Xstep = find(strcmp(txtAll(1,:), 'X Test Position'));
                ind_Ystep = find(strcmp(txtAll(1,:), 'Y Test Position'));
                if isempty(ind_Xstep)
                    ind_Xstep = find(strncmp(txtAll(1,:), '_XLocation', 10))-1;
                end
                if isempty(ind_Ystep)
                    ind_Ystep = find(strncmp(txtAll(1,:), '_YLocation', 10))-1;
                end
                ind_YM = find(strncmp(txtAll(1,:), 'Avg Modulus', 10));
                ind_H = find(strncmp(txtAll(1,:), 'Avg Hardness', 10));
                flagSKoss = 0;
                if isempty(ind_YM)
                    ind_YM = find(strncmp(txtAll(1,:), 'Modulus At Max Load', 10));
                end
                if isempty(ind_H)
                    ind_H = find(strncmp(txtAll(1,:), 'Hardness At Max Load', 10));
                end
                if isempty(ind_YM)
                    ind_YM = find(strncmp(txtAll(1,:), 'E Average Over Defined Range', 10));
                    if isempty(ind_YM)
                        ind_YM = find(strncmp(txtAll(1,:), 'Modulus From Unload', 10));
                    end
                    flagSKoss = 1;
                end
                if isempty(ind_H)
                    ind_H = find(strncmp(txtAll(1,:), 'H Average Over Defined Range', 10));
                    if isempty(ind_H)
                        ind_H = find(strncmp(txtAll(1,:), 'Hardness From Unload', 10));
                    end
                    flagSKoss = 1;
                end
                if isempty(ind_YM)
                    ind_YM = find(strncmp(txtAll(1,:), 'AvgModulus', 10))-1;
                end
                if isempty(ind_H)
                    ind_H = find(strncmp(txtAll(1,:), 'AvgHardness', 10))-1;
                end
                endLines = 3;
            elseif dataType == 2 % Excel file from Hysitron
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
                    disp('No headerlines found !');
                end
            elseif dataType == 3 % Excel file from ASMEC
                ind_Xstep = '';
                ind_Ystep = '';
                ind_YM = find(strncmp(txtAll(1,:), 'E', 10));
                ind_H = find(strncmp(txtAll(1,:), 'H', 10));
                flagSKoss = 0;
                endLines = 0;
            else % Other files
                ind_Xstep = '';
                ind_Ystep = '';
                ind_YM = find(strncmp(txtAll(1,:), 'AvgModulus', 10));
                ind_H = find(strncmp(txtAll(1,:), 'AvgHardness', 10));
                flagSKoss = 0;
                endLines = 0;
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
                    deltaYY = abs(config.Ycoord(config.N_YStep+1) - ...
                        config.Ycoord(1));
                    % config.N_YStep*2 ???
                    deltaXY = abs(config.Xcoord(config.N_YStep) - ...
                        config.Xcoord(1));
                    % config.N_YStep*2 ???
                elseif dataType >= 2
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
                    disp('Wrong calculations of rotationnal angle');
                    config.angleRotation = 0;
                end
            else
                config.angleRotation = 0;
                config.N_XStep = config.N_XStep_default;
                config.N_YStep = config.N_YStep_default;
            end
            config.angleRotation = mod(config.angleRotation, 90);
            
            % X step in microns
            if ~isempty(ind_Xstep)
                config.XStep = deltaXX / cosd(config.angleRotation);
                set(g.handles.value_deltaXindents_GUI, 'String', num2str(config.XStep));
            else
                config.XStep = config.XStep_default;
            end
            
            % Y step in microns
            if ~isempty(ind_Ystep)
                config.YStep = deltaYY / cosd(config.angleRotation);
                set(g.handles.value_deltaYindents_GUI, 'String', num2str(config.YStep));
            else
                config.YStep = config.YStep_default;
            end
            
            % Young's modulus values
            if ~isempty(ind_YM)
                if flagSKoss
                    data.expValues.YM = dataAll(:,ind_YM);
                else
                    if dataType ~= 3
                        if dataType ~= 4
                            data.expValues.YM = dataAll(:,ind_YM-1);
                        else
                            data.expValues.YM = dataAll(:,ind_YM);
                        end
                    else
                        try
                            data.expValues.YM = str2num(char(raw(3:end,ind_YM)));
                        catch
                            data.expValues.YM = dataAll(:,ind_YM);
                        end
                    end
                end
            else
                disp('No elastic modulus values found !');
                data.expValues.YM = NaN;
                config.flag_data = 0;
            end
            % Hardness values
            if ~isempty(ind_H)
                if flagSKoss
                    data.expValues.H = dataAll(:,ind_H);
                else
                    if dataType ~= 3
                        
                        if dataType ~= 4
                            data.expValues.H = dataAll(:,ind_H-1);
                        else
                            data.expValues.H = dataAll(:,ind_H);
                        end
                    else
                        try
                            data.expValues.H = str2num(char(raw(3:end,ind_H)));
                        catch
                            data.expValues.H = dataAll(:,ind_H);
                        end
                    end
                end
            else
                disp('No hardness values found !');
                data.expValues.H = NaN;
                config.flag_data = 0;
            end
        catch exception
            config.flag_data = 0;
            errordlg(exception.message, 'Invalid indentation data');
        end
    end
    
    if config.flag_data
        NX = config.N_XStep;
        NY = config.N_YStep;
        % Vector to matrix (last three columns are average values in 'Results' sheet
        if dataType == 1 || dataType >= 3
            try
                data.expValues_mat.YM = reshape(data.expValues.YM(1:end-endLines,1),[NX,NY]);
                data.expValues_mat.H = reshape(data.expValues.H(1:end-endLines,1),[NX,NY]);
                % Flip even columns to respect nanoindentation pattern
                for evenIndex = 2:2:NY
                    data.expValues_mat.YM(:,evenIndex) = ...
                        flipud(data.expValues_mat.YM(:,evenIndex));
                    data.expValues_mat.H(:,evenIndex) = ...
                        flipud(data.expValues_mat.H(:,evenIndex));
                end
                config.flagValid = 1;
            catch
                try
                endLines=0; % In case of no end lines (eg average and STD values for each vectors...)
                data.expValues_mat.YM = reshape(data.expValues.YM(1:end-endLines,1),[NX,NY]);
                data.expValues_mat.H = reshape(data.expValues.H(1:end-endLines,1),[NX,NY]);
                % Flip even columns to respect nanoindentation pattern
                for evenIndex = 2:2:NY
                    data.expValues_mat.YM(:,evenIndex) = ...
                        flipud(data.expValues_mat.YM(:,evenIndex));
                    data.expValues_mat.H(:,evenIndex) = ...
                        flipud(data.expValues_mat.H(:,evenIndex));
                end
                config.flagValid = 1;
                catch
                    data.expValues_mat.YM = 0;
                    data.expValues_mat.H = 0;
                    errordlg('Wrong inputs for number of indents along X or/and Y axis !');
                    config.flagValid = 0;
                end
            end
        elseif dataType == 2
            try
                data.expValues_mat.YM = reshape(data.expValues.YM(1:end-endLines,1),[NX,NY]);
                data.expValues_mat.H = reshape(data.expValues.H(1:end-endLines,1),[NX,NY]);
                config.flagValid = 1;
            catch
                data.expValues_mat.YM = 0;
                data.expValues_mat.H = 0;
                errordlg('Wrong inputs for number of indents along X or/and Y axis !');
                config.flagValid = 0;
            end
        end
    else
        config.flagValid = 0;
    end

    if ~config.flag_data || ~config.flagValid
        g.config = config;
        guidata(h.MainWindow, g);
        return
    end
    
    set(h.value_MinXCrop_GUI, 'String', 1);
    set(h.value_MaxXCrop_GUI, 'String', num2str(get(h.value_numXindents_GUI, 'String')));
    set(h.value_MinYCrop_GUI, 'String', 1);
    set(h.value_MaxYCrop_GUI, 'String', num2str(get(h.value_numYindents_GUI, 'String')));
    
    minVal = nanmin(nanmin(data.expValues_mat.H));
    if minVal < 0
        minVal = 0;
    end
    maxVal = nanmax(nanmax(data.expValues_mat.H));
    if maxVal < 0
        maxVal = 0;
    end
    if strcmp(get(h.binarization_GUI, 'String'), 'BINARIZATION')
        set(h.value_MinVal_GUI, 'String', num2str((nanmin(minVal))));
        set(h.value_MaxVal_GUI, 'String', num2str((nanmax(maxVal))));
        set(h.property_GUI, 'Value', 2);
        config.flag_ClusterGauss = 0;
    end
    config.flagZplot = 0;
    
    g.data = data;
    g.config = config;
    g.handles = h;
    set(h.unitProp_GUI, 'Enable', 'on');
    guidata(gcf, g);
    if config.flagValid
        if strcmp(get(g.handles.binarization_GUI, 'String'), 'BINARIZATION')
            TriDiMap_runPlot;
        else
            set(g.handles.value_criterionE_GUI, 'String', ...
                num2str(round(nanmean(g.data.expValues.YM))));
            set(g.handles.value_criterionH_GUI, 'String', ...
                num2str(round(nanmean(g.data.expValues.H))));
            g.config.flag_image = 0;
            guidata(gcf, g);
            TriDiMap_runBin;
        end
    end
end
end