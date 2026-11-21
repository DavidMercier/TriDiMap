%% Copyright 2014 MERCIER David
function TriDiMap_loadingAllTests
%% Load indentation curves for depth slices.
fig = gcf;
gui = guidata(fig);
[filename_data, pathname_data] = ...
    uigetfile('*.xls;*.xlsx;*.mat', 'File Selector', gui.config.data_path);
if isequal(filename_data, 0) || isequal(pathname_data, 0)
    disp('Slice data selection canceled.');
    return
end

fullname_data = fullfile(pathname_data, filename_data);
[~, ~, ext] = fileparts(filename_data);
disp(['User selected ', fullname_data]);

try
    if any(strcmpi(ext, {'.xls', '.xlsx'}))
        [sliceData, sheets] = TriDiMap_readSliceWorkbook(fullname_data);
        if isempty(sliceData)
            disp('Slice segment selection canceled.');
            return
        end
        matData = sliceData;
        save(fullfile(pathname_data, [filename_data, '_3DSlice.mat']), 'matData');
        gui.slice_data_xls.filename_data = filename_data;
        gui.slice_data_xls.pathname_data = pathname_data;
        gui.slice_data_xls.sheets_xls = sheets;
        gui.slice_data_xls.sheets_xls_notEmpty = numel(sliceData);
    elseif strcmpi(ext, '.mat')
        matFile = load(fullname_data, 'matData');
        if ~isfield(matFile, 'matData') || ~isstruct(matFile.matData) || ...
                isempty(matFile.matData) || ...
                ~all(isfield(matFile.matData, {'data_h', 'data_L', 'data_H', 'data_E'}))
            error('TriDiMap:InvalidSliceData', ...
                'The MAT file must contain indentation curves in matData.');
        end
        sliceData = matFile.matData;
    else
        error('TriDiMap:InvalidSliceData', 'Select an XLS, XLSX, or MAT file.');
    end
catch exception
    if strcmp(exception.identifier, 'TriDiMap:InvalidSliceData')
        errordlg(exception.message, 'Unable to load slice data');
        return
    end
    rethrow(exception);
end

gui.slice_data = sliceData;
gui.config.SliceFlagData = 1;
guidata(fig, gui);
end
