function test_cdf_fitting
root = fileparts(fileparts(mfilename('fullpath')));
previous = path;
cleanup = onCleanup(@() path(previous));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));
addpath(fullfile(root, 'matlab_code', 'util'));
addpath(fullfile(root, 'third_party_codes'));
addpath(fullfile(root, 'third_party_codes', 'kstest_2s_2d'));
custom = struct('TolFun_value', 1e-8, 'MaxIter_value', 700, 'Min_mWeibull', 0.5);
[filled, initialized] = TriDiMap_cdfNumerics(custom);
assert(filled.TolFun_value == custom.TolFun_value);
assert(filled.MaxIter_value == custom.MaxIter_value && filled.Min_mWeibull == 0.5);
assert(~any(strcmp(initialized, 'TolFun_value')));
[again, initialized] = TriDiMap_cdfNumerics(filled);
assert(isequaln(again, filled) && isempty(initialized));
fig = figure('Visible', 'off');
closeFigure = onCleanup(@() close(fig));
axes('Parent', fig);
gui.config = struct('licenceOpt_Flag', false, 'licenceStat_Flag', false, ...
    'numerics', struct, 'property', 7, 'FrenchLeg', false);
controls = {'cb_GaussianPlot_GUI', 'cb_GaussianFit_GUI', ...
    'cb_WeibullFit_GUI', 'cb_CdfFromPdf_GUI'};
for ii = 1:numel(controls)
    gui.handles.(controls{ii}) = uicontrol('Parent', fig, 'Style', 'checkbox', 'Value', 0);
end
set(gui.handles.cb_WeibullFit_GUI, 'Value', 1);
guidata(fig, gui);
config = gui.config;
probabilities = ((1:40)-0.5)/40;
data2use = 2*(-log(1-probabilities)).^(1/3);
strUnit_Property = 'GPa';
LWval = 1.5;
TriDiMap_runCdf;
assert(isfield(gui.resultsCDF, 'Weibull') && ~isfield(gui.resultsCDF, 'Gaussian'));
assert(all(isfinite(gui.resultsCDF.Weibull.ydata_cdf_Fit)));
if exist('lsqcurvefit', 'file') == 2 && license('test', 'Optimization_Toolbox')
    for fittedModel = 1:2
        gui.resultsCDF = struct;
        gui.config.licenceOpt_Flag = true;
        gui.config.numerics = struct;
        guidata(fig, gui);
        gui.config.meanVal = mean(data2use);
        set(gui.handles.cb_GaussianFit_GUI, 'Value', fittedModel == 1);
        set(gui.handles.cb_WeibullFit_GUI, 'Value', fittedModel == 2);
        config = gui.config;
        cla;
        TriDiMap_runCdf;
        names = {'Gaussian', 'Weibull'};
        fit = gui.resultsCDF.(names{fittedModel});
        assert(all(isfinite(fit.ydata_cdf_Fit)) && numel(fit.coefEsts) == 2);
        assert(isfield(gui.config.numerics, 'TolFun_value'));
        assert(isfield(gui.config.numerics, 'Min_mGaussian'));
        assert(isfield(gui.config.numerics, 'Min_mWeibull'));
        assert(gui.config.meanVal == mean(data2use));
        stored = guidata(fig);
        assert(isequaln(stored.config.numerics, gui.config.numerics));
    end
else
    warning('TriDiMap:TestOptimizationUnavailable', ...
        'Optimization Toolbox is unavailable; licensed CDF fitting checks were skipped.');
end
disp('CDF default initialization, custom options and Weibull-only fitting checks passed.');
end
