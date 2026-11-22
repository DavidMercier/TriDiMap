function TriDiMap_runMultiphaseBin
gui = guidata(gcf);
phaseCount = gui.config.binPhaseCount;
if isscalar(gui.config.criterionBinMap_E)
    gui.config.criterionBinMap_E_binary = gui.config.criterionBinMap_E;
end
if isscalar(gui.config.criterionBinMap_H)
    gui.config.criterionBinMap_H_binary = gui.config.criterionBinMap_H;
end
if ~gui.config.flag_data || ~gui.config.flag_image
    errordlg('Load both an indentation map and an SEM image for multi-phase comparison.');
    return
end

try
    [modulus, cropValid] = TriDiMap_cropping(gui.data.expValues_mat.YM);
    if ~cropValid
        return
    end
    [hardness, cropValid] = TriDiMap_cropping(gui.data.expValues_mat.H);
    if ~cropValid
        return
    end
    image = gui.image.image2use;
    if size(image, 1) ~= size(gui.data.expValues_mat.YM, 2) || ...
            size(image, 2) ~= size(gui.data.expValues_mat.YM, 1)
        error('TriDiMap:MultiPhaseImage', ...
            'The SEM image must be pixelated to the indentation grid before comparison.');
    end
    xMin = round(gui.config.MinXCrop);
    xMax = round(gui.config.MaxXCrop);
    yMin = round(gui.config.MinYCrop);
    yMax = round(gui.config.MaxYCrop);
    if ndims(image) == 3
        image = image(yMin:yMax, xMin:xMax, :);
    else
        image = image(yMin:yMax, xMin:xMax);
    end

    [semLabels, semThresholds, semFractions] = ...
        TriDiMap_multiOtsu(image, phaseCount);
    eFractions = fractionsAtAvailablePoints(semLabels, rot90(modulus));
    hFractions = fractionsAtAvailablePoints(semLabels, rot90(hardness));
    [eLabels, eThresholds, eMapFractions] = TriDiMap_matchPhaseFractions( ...
        modulus, eFractions, requestedThresholds(gui.config.criterionBinMap_E, phaseCount));
    [hLabels, hThresholds, hMapFractions] = TriDiMap_matchPhaseFractions( ...
        hardness, hFractions, requestedThresholds(gui.config.criterionBinMap_H, phaseCount));
    [eConfusion, eMetrics, eMismatch] = ...
        TriDiMap_comparePhases(semLabels, rot90(eLabels), phaseCount);
    [hConfusion, hMetrics, hMismatch] = ...
        TriDiMap_comparePhases(semLabels, rot90(hLabels), phaseCount);
    [ehConfusion, ehMetrics, ehMismatch] = ...
        TriDiMap_comparePhases(rot90(eLabels), rot90(hLabels), phaseCount);
catch exception
    if any(strcmp(exception.identifier, {'TriDiMap:MultiPhaseImage', ...
            'TriDiMap:MultiPhaseThresholds', 'TriDiMap:MultiPhaseCompare'}))
        errordlg(exception.message, 'Multi-phase SEM comparison');
        return
    end
    rethrow(exception);
end

gui.data.data2plot_E = eLabels;
gui.data.data2plot_H = hLabels;
gui.data.data2plot = eLabels;
gui.data.xData_interp = (0:size(modulus, 1)-1) * gui.config.XStep;
gui.data.yData_interp = (0:size(modulus, 2)-1) * gui.config.YStep;
gui.image.image2plot = semLabels;
gui.config.sizeCheck = 1;
gui.data.binPhaseCount = phaseCount;
gui.data.semThresholds = semThresholds;
gui.data.semPhaseFractions = semFractions;
gui.data.eThresholds = eThresholds;
gui.data.hThresholds = hThresholds;
gui.data.ePhaseFractions = eMapFractions;
gui.data.hPhaseFractions = hMapFractions;
gui.results.confusionE = eConfusion;
gui.results.confusionH = hConfusion;
gui.results.confusionEH = ehConfusion;
gui.results.phaseMetricsE = eMetrics;
gui.results.phaseMetricsH = hMetrics;
gui.results.phaseMetricsEH = ehMetrics;
gui.results.diffE = 1 - 2*double(eMismatch);
gui.results.diffH = 1 - 2*double(hMismatch);
gui.results.diff_EH = 1 - 2*double(ehMismatch);
gui.results.diffE(isnan(eMismatch)) = NaN;
gui.results.diffH(isnan(hMismatch)) = NaN;
gui.results.diff_EH(isnan(ehMismatch)) = NaN;

set(gui.handles.value_criterionE_GUI, 'String', mat2str(eThresholds, 5));
set(gui.handles.value_criterionH_GUI, 'String', mat2str(hThresholds, 5));
set(gui.handles.value_ratioLow_E_GUI, 'String', percent(eMapFractions(1)));
set(gui.handles.value_ratioHigh_E_GUI, 'String', percent(eMapFractions(end)));
set(gui.handles.value_ratioLow_H_GUI, 'String', percent(hMapFractions(1)));
set(gui.handles.value_ratioHigh_H_GUI, 'String', percent(hMapFractions(end)));
set(gui.handles.value_ratioLow_I_GUI, 'String', percent(semFractions(1)));
set(gui.handles.value_ratioHigh_I_GUI, 'String', percent(semFractions(end)));
set(gui.handles.title_ratioLow_E_GUI, 'String', 'E - Phase 1');
set(gui.handles.title_ratioHigh_E_GUI, 'String', sprintf('E - Phase %d', phaseCount));
set(gui.handles.title_ratioLow_H_GUI, 'String', 'H - Phase 1');
set(gui.handles.title_ratioHigh_H_GUI, 'String', sprintf('H - Phase %d', phaseCount));
set(gui.handles.title_ratioLow_I_GUI, 'String', 'SEM - Phase 1');
set(gui.handles.title_ratioHigh_I_GUI, 'String', sprintf('SEM - Phase %d', phaseCount));
[eMean, eStd] = phaseStats(modulus, eLabels);
[hMean, hStd] = phaseStats(hardness, hLabels);
set(gui.handles.title_valMeanLow_E_GUI, 'String', 'Mean E - Ph. 1');
set(gui.handles.title_valMeanHigh_E_GUI, 'String', sprintf('Mean E - Ph. %d', phaseCount));
set(gui.handles.title_valMeanLow_H_GUI, 'String', 'Mean H - Ph. 1');
set(gui.handles.title_valMeanHigh_H_GUI, 'String', sprintf('Mean H - Ph. %d', phaseCount));
set(gui.handles.value_valMeanLow_E_GUI, 'String', meanStd(eMean(1), eStd(1)));
set(gui.handles.value_valMeanHigh_E_GUI, 'String', meanStd(eMean(end), eStd(end)));
set(gui.handles.value_valMeanLow_H_GUI, 'String', meanStd(hMean(1), hStd(1)));
set(gui.handles.value_valMeanHigh_H_GUI, 'String', meanStd(hMean(end), hStd(end)));
set(gui.handles.value_diffValE_GUI, 'String', percent(eMetrics.accuracy));
set(gui.handles.value_diffValH_GUI, 'String', percent(hMetrics.accuracy));
set(gui.handles.value_diffValEH_GUI, 'String', percent(ehMetrics.accuracy));
guidata(gcf, gui);

fprintf('SEM grayscale thresholds (normalized 0-255): %s\n', mat2str(semThresholds, 4));
fprintf('E thresholds (GPa): %s; E vs SEM accuracy: %.1f%%\n', ...
    mat2str(eThresholds, 5), 100*eMetrics.accuracy);
fprintf('H thresholds (GPa): %s; H vs SEM accuracy: %.1f%%\n', ...
    mat2str(hThresholds, 5), 100*hMetrics.accuracy);
disp('E vs SEM confusion matrix (rows=SEM phase, columns=E phase):');
disp(eConfusion);
disp('E-phase recall and IoU:');
disp([eMetrics.recall, eMetrics.iou]);
fprintf('%-6s %8s %8s %8s %18s %18s\n', 'Phase', 'SEM %', 'E %', 'H %', ...
    'E (GPa)', 'H (GPa)');
for row = 1:phaseCount
    fprintf('%-6d %8.1f %8.1f %8.1f %18s %18s\n', row, ...
        100*semFractions(row), 100*eMapFractions(row), ...
        100*hMapFractions(row), meanStd(eMean(row), eStd(row)), ...
        meanStd(hMean(row), hStd(row)));
end

axesToPlot = [gui.handles.AxisPlot_GUI_1, gui.handles.AxisPlot_GUI_2, ...
    gui.handles.AxisPlot_GUI_3, gui.handles.AxisPlot_GUI_4, ...
    gui.handles.AxisPlot_GUI_5, gui.handles.AxisPlot_GUI_6];
if gui.config.saveFlagBin == 0
    plots = 1:6;
else
    plots = gui.config.saveFlagBin;
end
for plotIndex = plots
    switch plotIndex
        case 1
            labels = rot90(eLabels);
            names = phaseNames('E phase', phaseCount);
            titleText = 'E map phases';
        case 2
            labels = rot90(hLabels);
            names = phaseNames('H phase', phaseCount);
            titleText = 'H map phases';
        case 3
            labels = semLabels;
            names = phaseNames('SEM phase', phaseCount);
            titleText = 'SEM grayscale phases';
        case 4
            labels = eMismatch + 1;
            names = {'Match', 'Mismatch'};
            titleText = sprintf('E vs SEM (%.1f\\%% match)', 100*eMetrics.accuracy);
        case 5
            labels = hMismatch + 1;
            names = {'Match', 'Mismatch'};
            titleText = sprintf('H vs SEM (%.1f\\%% match)', 100*hMetrics.accuracy);
        case 6
            labels = ehMismatch + 1;
            names = {'E/H agree', 'E/H disagree'};
            titleText = sprintf('E vs H agreement (%.1f\\%%)', 100*ehMetrics.accuracy);
    end
    TriDiMap_plotPhaseLabels(axesToPlot(plotIndex), labels, names, gui, titleText);
end

    function value = percent(fraction)
        value = num2str(round(fraction*1000)/10);
    end

    function [means, stds] = phaseStats(values, labels)
        means = NaN(phaseCount, 1);
        stds = NaN(phaseCount, 1);
        for phaseIndex = 1:phaseCount
            phaseValues = values(labels == phaseIndex & isfinite(values));
            if ~isempty(phaseValues)
                means(phaseIndex) = mean(phaseValues);
                stds(phaseIndex) = std(phaseValues);
            end
        end
    end

    function value = meanStd(meanValue, stdValue)
        value = sprintf('%.1f%s%.1f', meanValue, char(177), stdValue);
    end

    function names = phaseNames(prefix, count)
        names = cell(1, count);
        for phaseIndex = 1:count
            names{phaseIndex} = sprintf('%s %d', prefix, phaseIndex);
        end
    end

    function fractions = fractionsAtAvailablePoints(referenceLabels, data)
        available = isfinite(data);
        fractions = accumarray(referenceLabels(available), 1, [phaseCount, 1]);
        if sum(fractions) == 0
            error('TriDiMap:MultiPhaseThresholds', ...
                'The property map contains no finite measurements in the cropped region.');
        end
        fractions = fractions / sum(fractions);
    end

    function thresholds = requestedThresholds(value, count)
        thresholds = value(:);
        if numel(thresholds) ~= count-1
            thresholds = [];
        end
    end
end
