function test_pdf_axis_limits
root = fileparts(fileparts(mfilename('fullpath')));
previous = path;
cleanup = onCleanup(@() path(previous));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));
addpath(fullfile(root, 'matlab_code', 'util'));
addpath(fullfile(root, 'third_party_codes', 'nansuite'));
fig = figure('Visible', 'off');
closeFigure = onCleanup(@() close(fig));
ax = axes('Parent', fig);
gui.config = struct('autobinSize', false, 'binSize', 1, ...
    'MinHistVal', 0, 'MaxHistVal', 41);
gui.handles.cb_plotErrorPDF_GUI = uicontrol('Parent', fig, 'Style', 'checkbox', 'Value', 0);
gui.handles.cb_deconvolutionHist_GUI = uicontrol('Parent', fig, 'Style', 'checkbox', 'Value', 0);
config = struct('flag_data', true, 'FrenchLeg', false);
data2use = reshape(repmat(1:40, 1, 5), 10, 20);
strUnit_Property = 'GPa';
LWval = 1.5;
for property = [4, 5]
    cla;
    config.property = property;
    TriDiMap_runPdf;
    bars = findall(ax, 'Type', 'bar');
    peak = max(get(bars, 'YData'));
    limits = ylim(ax);
    assert(limits(1) == 0 && abs(limits(2)-1.1*peak) < 1e-12);
    assert(limits(2) < 0.1);
end
errorHistogram = histcounts(data2use(:), 0:41)';
errorResults = struct('GaussianFit', 0.9*errorHistogram'/numel(data2use), ...
    'hist_xy', [(1:41)', errorHistogram/numel(data2use)], ...
    'hist_val', data2use(:));
gui.resultsPDF.E = errorResults;
gui.resultsPDF.H = errorResults;
gui.resultsPDF.H.GaussianFit = 1.2*errorHistogram/numel(data2use);
gui.config.flag_fit = 1;
for property = [4, 5]
    cla;
    config.property = property;
    set(gui.handles.cb_plotErrorPDF_GUI, 'Value', 1);
    lastwarn('');
    TriDiMap_runPdf;
    [~, warningID] = lastwarn;
    assert(strcmp(warningID, 'TriDiMap:EmptyPDFErrorBins'));
    errorProperty = 'E';
    expectedError = 0.1;
    if property == 5
        errorProperty = 'H';
        expectedError = -0.2;
    end
    storedError = gui.resultsPDF.(errorProperty).errorFit;
    assert(isequal(size(storedError), [41, 1]));
    assert(all(isnan(storedError(errorHistogram == 0))));
    assert(max(abs(storedError(errorHistogram > 0)-expectedError)) < 1e-12);
    errorLine = findall(ax, 'Type', 'line');
    assert(isequal(get(errorLine, 'XData'), 1:41));
    assert(max(abs(ylim(ax)-[-abs(expectedError), abs(expectedError)])) < 1e-12);
    assert(~isfield(gui, 'results'));
end
gui.resultsPDF.H.GaussianFit = errorHistogram/numel(data2use);
cla;
TriDiMap_runPdf;
assert(all(gui.resultsPDF.H.errorFit(errorHistogram > 0) == 0));
assert(isequal(ylim(ax), [-1, 1]));
gui.resultsPDF = struct('E', errorResults);
originalErrorData = data2use;
set(gui.handles.cb_deconvolutionHist_GUI, 'Value', 1);
for missingFitCase = 1:3
    config.property = 5;
    gui.config.MinHistVal = 0;
    gui.config.MaxHistVal = 41;
    data2use = originalErrorData;
    if missingFitCase == 2
        config.property = 4;
        gui.config.MinHistVal = 1;
        gui.config.MaxHistVal = 42;
    elseif missingFitCase == 3
        config.property = 4;
        data2use(1) = 1.5;
    end
    gui.config.flag_fit = 1;
    set(gui.handles.cb_plotErrorPDF_GUI, 'Value', 1);
    cla;
    figuresBefore = findall(0, 'Type', 'figure');
    TriDiMap_runPdf;
    errorDialogs = setdiff(findall(0, 'Type', 'figure'), figuresBefore);
    closeDialogs = onCleanup(@() delete(errorDialogs));
    assert(numel(errorDialogs) == 1);
    assert(strcmp(get(errorDialogs, 'Name'), 'PDF fit error'));
    assert(get(gui.handles.cb_plotErrorPDF_GUI, 'Value') == 0);
    assert(gui.config.flag_fit == 0);
    assert(isequal(gcf, fig));
    assert(~isempty(findall(ax, 'Type', 'bar')));
    assert(~isfield(gui, 'results'));
    clear closeDialogs;
end
data2use = originalErrorData;
set(gui.handles.cb_deconvolutionHist_GUI, 'Value', 0);
gui.config.MinHistVal = 80;
gui.config.MaxHistVal = 100;
cla;
lastwarn('');
TriDiMap_runPdf;
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'TriDiMap:EmptyPDFRange'));
assert(isequal(ylim(ax), [0, 1]));
gui.handles.cb_colorHist_GUI = uicontrol('Parent', fig, 'Style', 'checkbox', 'Value', 0);
gui.handles.value_IterResHist_GUI = uicontrol('Parent', fig, 'Visible', 'off');
gui.handles.value_PrecHistRes_GUI = uicontrol('Parent', fig, 'Visible', 'off');
set(gui.handles.cb_deconvolutionHist_GUI, 'Value', 1);
guidata(fig, gui);
state = rng;
restoreRng = onCleanup(@() rng(state));
rng(0, 'twister');
values = (9.99:0.005:10.01)';
histogram = [(9.98:0.01:10.02)', 0.001*ones(5, 1)];
[components, overall, ~, ~, ~, position] = ...
    TriDiMap_runDeconvolution(values, histogram, 2, 0, 1e-6, 5, 'GPa', false);
peak = max([histogram(:, 2); components(:); overall(:)]);
assert(peak > 1.2);
limits = ylim(ax);
assert(limits(1) == 0 && abs(limits(2)-1.1*peak) < 1e-12);
assert(position(4) < limits(2));
if ~verLessThan('matlab', '9.0')
    addpath(fullfile(root, 'third_party_codes'));
    gui.config.licenceStat_Flag = false;
    gui.config.licenceOpt_Flag = false;
    gui.resultsPDF.E = struct('position', [0, 81, 81, 0.9], ...
        'pdfData', struct('minmeanVec', [20, 50], 'minstddev', [2, 10], 'minf', [0.4, 0.6]));
    gui.resultsPDF.H = struct('position', [0, 8.1, 8.1, 0.9], ...
        'pdfData', struct('minmeanVec', [2, 7], 'minstddev', [0.4, 1], 'minf', [0.3, 0.7]));
    controls = {'cb_GaussianPlot_GUI', 'cb_GaussianFit_GUI', ...
        'cb_WeibullFit_GUI', 'cb_CdfFromPdf_GUI'};
    for ii = 1:numel(controls)
        gui.handles.(controls{ii}) = uicontrol('Parent', fig, 'Style', 'checkbox', 'Value', 0);
    end
    set(gui.handles.cb_CdfFromPdf_GUI, 'Value', 1);
    set(gui.handles.cb_deconvolutionHist_GUI, 'Value', 0);
    for property = [8, 9]
        legend(ax, 'off');
        cla(ax, 'reset');
        config.property = property;
        gui.config.property = property;
        gui.config.MinHistVal = 0;
        gui.config.binSize = 1;
        gui.config.MaxHistVal = 81;
        data2use = reshape(1:80, 8, 10);
        selectedFit = gui.resultsPDF.E;
        if property == 9
            gui.config.binSize = 0.1;
            gui.config.MaxHistVal = 8.1;
            data2use = data2use/10;
            selectedFit = gui.resultsPDF.H;
        end
        TriDiMap_runPdfCdf;
        rulers = get(ax, 'YAxis');
        assert(numel(rulers) == 2);
        assert(isequal(rulers(2).Limits, [0, 1]));
        assert(strcmp(rulers(1).Label.String, 'Frequency density'));
        assert(strcmp(rulers(2).Label.String, 'Cumulative density function'));
        bars = findall(ax, 'Type', 'bar');
        peak = max(get(bars, 'YData'));
        assert(abs(rulers(1).Limits(2)-1.1*peak) < 1e-12);
        assert(rulers(1).Limits(2) < 0.1);
        assert(isequal(xlim(ax), [0, gui.config.MaxHistVal]));
        expected = sum(bsxfun(@times, ...
            cdfGaussian(sort(data2use(:)'), selectedFit.pdfData.minmeanVec, ...
            selectedFit.pdfData.minstddev), selectedFit.pdfData.minf(:)), 1);
        assert(max(abs(get(hp_All, 'YData')-expected)) < 1e-12);
        yyaxis(ax, 'right');
        assert(ismember(hp_All, get(ax, 'Children')));
        yyaxis(ax, 'left');
        assert(ismember(bars, get(ax, 'Children')));
        before = get(hp(1), 'Color');
        TriDiMap_applyGrayscale(ax, true);
        gray = get(hp(1), 'Color');
        assert(gray(1) == gray(2) && gray(2) == gray(3));
        TriDiMap_applyGrayscale(ax, false);
        assert(isequal(get(hp(1), 'Color'), before));
        checkCombinedLegend(ax, 2);
    end
    legend(ax, 'off');
    cla(ax, 'reset');
    config.property = 8;
    gui.config.property = 8;
    gui.config.binSize = 1;
    gui.config.MaxHistVal = 81;
    data2use = reshape(1:80, 8, 10);
    gui.resultsPDF.E.pdfData = struct('minmeanVec', 10:10:60, ...
        'minstddev', 3*ones(1, 6), 'minf', ones(1, 6)/6);
    TriDiMap_runPdfCdf;
    checkCombinedLegend(ax, 6);
    gui.handles.value_PhNumHist_GUI = uicontrol('Parent', fig, 'Style', 'edit', 'String', '2');
    gui.handles.value_IterMaxHist_GUI = uicontrol('Parent', fig, 'Style', 'edit', 'String', '0');
    gui.handles.value_PrecHist_GUI = uicontrol('Parent', fig, 'Style', 'edit', 'String', '1e-6');
    set(gui.handles.cb_deconvolutionHist_GUI, 'Value', 1);
    guidata(fig, gui);
    for cdfFromPdf = [1, 0]
        rng(0, 'twister');
        legend(ax, 'off');
        cla(ax, 'reset');
        set(gui.handles.cb_CdfFromPdf_GUI, 'Value', cdfFromPdf);
        TriDiMap_runPdfCdf;
        checkCombinedLegend(ax, 2);
        plotChildren = allchild(ax);
        assert(numel(findall(plotChildren, 'Tag', 'TriDiMapPDFPhase')) == 2);
        assert(numel(findall(plotChildren, 'Tag', 'TriDiMapCDFPhase')) == 2*cdfFromPdf);
        assert(numel(findall(plotChildren, 'Tag', 'TriDiMapOverallPDF')) == 1);
        rulers = get(ax, 'YAxis');
        assert(isequal(rulers(2).Limits, [0, 1]));
    end
    legend(ax, 'off');
    cla(ax, 'reset');
    config.property = 6;
    gui.config.property = 6;
    set(gui.handles.cb_CdfFromPdf_GUI, 'Value', 1);
    TriDiMap_runCdf;
    assert(numel(get(ax, 'YAxis')) == 1);
    assert(numel(findall(ax, 'Tag', 'TriDiMapCDFPhaseSummary')) == 2);
else
    warning('TriDiMap:TestDualAxesUnavailable', ...
        'MATLAB R2016a or newer is required for the combined PDF+CDF axis checks.');
end
disp('E/H histogram and fitted-PDF axis limits adapt to displayed peaks.');
end

function checkCombinedLegend(ax, phaseCount)
plotChildren = allchild(ax);
assert(isempty(findall(plotChildren, 'Tag', 'TriDiMapPDFPhaseSummary')));
assert(isempty(findall(plotChildren, 'Tag', 'TriDiMapCDFPhaseSummary')));
plotLegend = findall(ancestor(ax, 'figure'), 'Type', 'legend');
assert(numel(plotLegend) == 1);
descriptions = get(plotLegend, 'String');
phaseDescriptions = descriptions(~cellfun(@isempty, regexp(descriptions, '^Phase \d+\n', 'once')));
assert(numel(phaseDescriptions) == phaseCount);
for ii = 1:phaseCount
    prefix = sprintf('Phase %d\n', ii);
    assert(strncmp(phaseDescriptions{ii}, prefix, numel(prefix)));
end
drawnow;
axesUnits = get(ax, 'Units');
legendUnits = get(plotLegend, 'Units');
restoreAxesUnits = onCleanup(@() set(ax, 'Units', axesUnits));
restoreLegendUnits = onCleanup(@() set(plotLegend, 'Units', legendUnits));
set(ax, 'Units', 'normalized');
set(plotLegend, 'Units', 'normalized');
axesPosition = get(ax, 'Position');
legendPosition = get(plotLegend, 'Position');
assert(legendPosition(1) >= axesPosition(1)+axesPosition(3)-1e-3);
assert(all(legendPosition(1:2) >= -1e-3));
assert(all(legendPosition(1:2)+legendPosition(3:4) <= 1+1e-3));
end
