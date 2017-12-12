%% Copyright 2014 MERCIER David
function TriDiMap_plotMatchThreshold
%% Function to plot match as a function of all threshold

g = guidata(gcf);

% For elastic modulus and hardness
numThres = str2num(get(g.handles.value_numThres_GUI, 'String'));
maxE = 2*round(nanmean(g.data.expValues.YM));
maxH = 2*round(nanmean(g.data.expValues.H));
crit_E = 0:maxE/numThres:maxE;
crit_H = 0:maxH/numThres:maxH;

matchPercent_E = zeros(1,length(crit_E));
matchPercent_H = zeros(1,length(crit_H));
for ii = 1:length(crit_E)
    g.config.criterionBinMap_E = crit_E(ii);
    g.config.criterionBinMap_H = crit_H(ii);
    guidata(gcf, g);
    TriDiMap_runBin(1);
    matchPercent_E(ii) = TriDiMap_diff_plotting(1,1);
    matchPercent_H(ii) = TriDiMap_diff_plotting(2,1);
end

hNewFig_E = figure;
plot(crit_E, matchPercent_E, 'r+', 'Linewidth', 3);
ylim([0 100])
hXLabel = xlabel(['Elastic modulus threshold (', char(g.config.strUnit_Property),')']);
hYLabel = ylabel('Match ($\%$)');
hTitle = title('Evolution of match between E map and image');
set([hXLabel, hYLabel, hTitle], ...
    'Color', [0,0,0], 'FontSize', 14, ...
    'Interpreter', 'Latex');
grid on;

hNewFig_H = figure;
plot(crit_H, matchPercent_H, 'r+', 'Linewidth', 3);
ylim([0 100]);
hXLabel = xlabel(['Hardness threshold (', char(g.config.strUnit_Property),')']);
hYLabel = ylabel('Match ($\%$)');
hTitle = title('Evolution of match between H map and image');
set([hXLabel, hYLabel, hTitle], ...
    'Color', [0,0,0], 'FontSize', 14, ...
    'Interpreter', 'Latex');
grid on;

% For elastic modulus vs hardness
matchPercent_EH = zeros(length(crit_E), length(crit_H));

h = waitbar(0,'Please wait...');
for ii = 1:length(crit_E)
    for jj = 1:length(crit_H)
        g.config.criterionBinMap_E = crit_E(ii);
        g.config.criterionBinMap_H = crit_H(jj);
        guidata(gcf, g);
        TriDiMap_runBin(1);
        matchPercent_EH(ii,jj) = TriDiMap_diff_plotting(3,1);
    end
    waitbar(ii / length(crit_E));
end
close(h);

hNewFig_EH = figure;
%imagesc(crit_E, crit_H, matchPercent_EH);
surf(meshgrid(crit_E,1:numThres+1)', meshgrid(crit_H,1:numThres+1), ...
    matchPercent_EH);
colormap('gray');
xlim([0 max(crit_E)]);
ylim([0 max(crit_H)]);
zlim([0 100]);
hXLabel = xlabel(['Elastic modulus threshold (', char(g.config.strUnit_Property),')']);
hYLabel = ylabel(['Hardness threshold (', char(g.config.strUnit_Property),')']);
hZLabel = zlabel('Match ($\%$)');
hTitle = title('Evolution of match between E and H maps');
set([hXLabel, hYLabel, hZLabel, hTitle], ...
    'Color', [0,0,0], 'FontSize', 14, ...
    'Interpreter', 'Latex');
grid on;
view(0,90);

end