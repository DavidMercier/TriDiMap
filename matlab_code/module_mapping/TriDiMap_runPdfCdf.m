if ~ismember(exist('yyaxis', 'file'), [2, 3, 6]) && exist('yyaxis', 'builtin') ~= 5
    error('TriDiMap:PDFCDFVersion', ...
        'Combined PDF+CDF plots with separate y-axes require MATLAB R2016a or newer. Use separate PDF and CDF views on older releases.');
end
yyaxis left;
TriDiMap_runPdf;
pdfLimits = ylim;
propertyLimits = xlim;
hold on;
yyaxis right;
TriDiMap_runCdf;
set(gca, 'YScale', 'linear');
ylim([0, 1]);
xlim(propertyLimits);
yyaxis left;
ylim(pdfLimits);

plotChildren = allchild(gca);
pdfBars = flipud(findall(plotChildren, 'Type', 'bar'));
combinedHandles = gobjects(numel(pdfBars)+1, 1);
combinedHandles(1:numel(pdfBars)) = pdfBars;
combinedHandles(end) = h_CDF;
combinedDescriptions = cell(numel(pdfBars)+1, 1);
for ii = 1:numel(pdfBars)
    combinedDescriptions{ii} = get(pdfBars(ii), 'DisplayName');
    if numel(pdfBars) == 1 || isempty(combinedDescriptions{ii})
        combinedDescriptions{ii} = 'Experimental PDF';
    end
end
combinedDescriptions{end} = 'Experimental CDF';
phaseHandles = findall(plotChildren, 'Tag', 'TriDiMapCDFPhase');
if isempty(phaseHandles)
    phaseHandles = findall(plotChildren, 'Tag', 'TriDiMapPDFPhase');
end
if ~isempty(phaseHandles)
    phaseIDs = zeros(numel(phaseHandles), 1);
    for ii = 1:numel(phaseHandles)
        phaseIDs(ii) = get(phaseHandles(ii), 'UserData');
    end
    [phaseIDs, phaseOrder] = sort(phaseIDs);
    phaseHandles = phaseHandles(phaseOrder);
    pdfProperty = 'E';
    if config.property == 9
        pdfProperty = 'H';
    end
    phaseData = gui.resultsPDF.(pdfProperty).pdfData;
    for ii = 1:numel(phaseHandles)
        phaseID = phaseIDs(ii);
        combinedHandles(end+1, 1) = phaseHandles(ii);
        combinedDescriptions{end+1, 1} = sprintf('Phase %d\nMean %.3f | SD %.3f | f %.3f', ...
            phaseID, phaseData.minmeanVec(phaseID), ...
            phaseData.minstddev(phaseID), phaseData.minf(phaseID));
    end
end
overallPDF = findall(plotChildren, 'Tag', 'TriDiMapOverallPDF');
if ~isempty(overallPDF)
    combinedHandles(end+1, 1) = overallPDF;
    combinedDescriptions{end+1, 1} = 'Overall PDF fit';
end
if Gplot
    combinedHandles(end+1, 1) = h_CDF_fit;
    combinedDescriptions{end+1, 1} = 'Gaussian CDF';
end
if Gfit
    combinedHandles(end+1, 1) = h_Gfit;
    combinedDescriptions{end+1, 1} = 'Gaussian CDF fit';
end
if Wfit
    combinedHandles(end+1, 1) = h_Wfit;
    combinedDescriptions{end+1, 1} = 'Weibull CDF fit';
end
if AllCDF
    combinedHandles(end+1, 1) = hp_All;
    combinedDescriptions{end+1, 1} = 'CDF fit from PDF fit';
end
phaseSummaries = [findall(plotChildren, 'Tag', 'TriDiMapPDFPhaseSummary'); ...
    findall(plotChildren, 'Tag', 'TriDiMapCDFPhaseSummary')];
delete(phaseSummaries);
legend(combinedHandles, combinedDescriptions, 'Location', 'northeastoutside', ...
    'Interpreter', 'none');
legend boxoff;
