function TriDiMap_recalculateMaps
gui = guidata(gcf);
if ~strcmp(get(gui.handles.binarization_GUI, 'String'), 'BINARIZATION') || ...
        ~gui.config.flag_data || ~gui.config.flagValid
    errordlg('Load a valid indentation map in the mapping window first.', 'Contact model');
    return
end

[choice, accepted] = listdlg('PromptString', 'Select the contact model for the entire map:', ...
    'SelectionMode', 'single', 'ListString', {'Sink-in: Oliver-Pharr', 'Pile-up: Loubet'});
if ~accepted
    return
end
if choice == 1
    model = 'Oliver-Pharr';
else
    model = 'Loubet';
end
answers = inputdlg({'Oliver-Pharr epsilon:', 'Loubet alpha:', ...
    'Loubet tip defect (nm):', 'Geometric correction beta:', ...
    'Area coefficients C0,C1,...,C8 (depth in nm, area in nm^2):'}, ...
    'Contact model calibration', 1, {'0.75', '1.2', '0', '1.034', '24.56'});
if isempty(answers)
    return
end
epsilon = str2double(answers{1});
alpha = str2double(answers{2});
tipDefect = str2double(answers{3});
beta = str2double(answers{4});
coefficientStrings = strsplit(answers{5}, ',', 'CollapseDelimiters', false);
coefficients = cellfun(@str2double, coefficientStrings);

[filename, pathname] = uigetfile({'*.xls;*.xlsx', 'Excel spreadsheets (*.xls, *.xlsx)'}, ...
    'Select per-indent measurements');
if isequal(filename, 0)
    return
end
try
    [~, ~, raw] = xlsread(fullfile(pathname, filename));
    headers = {'Depth (nm)', 'Load (mN)', 'Stiffness (mN/nm)'};
    count = numel(gui.data.expValues_mat.H);
    if size(raw, 1) ~= count + 1 || size(raw, 2) ~= 3 || ...
            ~isequal(raw(1, :), headers) || ...
            ~all(cellfun(@(x) isnumeric(x) && isscalar(x), reshape(raw(2:end, :), [], 1)))
        error('TriDiMap:InvalidSpreadsheet', ...
            'Expected the three documented headers and exactly one numeric row per indent, in acquisition order.');
    end
    measurements = cell2mat(raw(2:end, :));
    [modulus, hardness] = TriDiMap_contactModel(measurements(:, 1), ...
        measurements(:, 2), measurements(:, 3), model, epsilon, alpha, ...
        tipDefect, beta, coefficients);
catch exception
    errordlg(exception.message, 'Contact model recalculation');
    return
end

if ~isfield(gui.data, 'originalProperties')
    gui.data.originalProperties.expValues = gui.data.expValues;
    gui.data.originalProperties.expValues_mat = gui.data.expValues_mat;
    gui.data.originalProperties.unit = get(gui.handles.unitProp_GUI, 'Value');
end
gui.data.expValues.YM = modulus;
gui.data.expValues.H = hardness;
gridSize = size(gui.data.expValues_mat.H);
gui.data.expValues_mat.YM = reshape(modulus, gridSize);
gui.data.expValues_mat.H = reshape(hardness, gridSize);
if gui.data.mappingDataType ~= 2
    for ii = 2:2:gridSize(2)
        gui.data.expValues_mat.YM(:, ii) = flipud(gui.data.expValues_mat.YM(:, ii));
        gui.data.expValues_mat.H(:, ii) = flipud(gui.data.expValues_mat.H(:, ii));
    end
end
gui.config.flagZplot = 0;
gui.config.flag_ClusterGauss = 0;
gui.config.flag_fit = 0;
if isfield(gui, 'resultsPDF')
    gui = rmfield(gui, 'resultsPDF');
end
if isfield(gui, 'resultsCDF')
    gui = rmfield(gui, 'resultsCDF');
end
set(gui.handles.cb_CdfFromPdf_GUI, 'Value', 0);
set(gui.handles.cb_plotErrorPDF_GUI, 'Value', 0);
set(gui.handles.unitProp_GUI, 'Value', 2, 'Enable', 'off');
set(gui.handles.property_GUI, 'Value', 2);
set(gui.handles.pm_pixData_GUI, 'Value', 1);
set(gui.handles.value_MinVal_GUI, 'String', '');
set(gui.handles.value_MaxVal_GUI, 'String', '');
set(gui.handles.pm_autoColorbar_GUI, 'Value', 1);
guidata(gui.handles.MainWindow, gui);
TriDiMap_runPlot;
end
