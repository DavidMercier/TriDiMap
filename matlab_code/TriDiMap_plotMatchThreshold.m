%% Copyright 2014 MERCIER David
function TriDiMap_plotMatchThreshold
%% Function to plot match as a function of all threshold

g = guidata(gcf);

% For elastic modulus and hardness
numThres = 20;
crit_E = ...
    0:round(max(max(g.data.expValues.YM)))/numThres:round(max(max(g.data.expValues.YM)));
crit_H = ...
    0:round(max(max(g.data.expValues.H)))/numThres:round(max(max(g.data.expValues.H)));

diff_errorE = zeros(1,length(crit_E));
diff_errorH = zeros(1,length(crit_H));
matchPercent_E = zeros(1,length(crit_E));
matchPercent_H = zeros(1,length(crit_H));
for ii = 1:length(crit_E)
    g.config.criterionBinMap_E = crit_E(ii);
    g.config.criterionBinMap_H = crit_H(ii);
    guidata(gcf, g);
    TriDiMap_runBin(1);
    diff_errorE(ii) = TriDiMap_diff_plotting(1,1);
    diff_errorH(ii) = TriDiMap_diff_plotting(2,1);
    matchPercent_E(ii) = (1-diff_errorE(ii))*100;
    matchPercent_H(ii) = (1-diff_errorH(ii))*100;
end

hNewFig_E = figure;
plot(crit_E, matchPercent_E, 'r+', 'Linewidth', 3);
ylim([0 100])
hXLabel = xlabel('Elastic modulus threshold');
hYLabel = ylabel('Match ($\%$)');
hTitle = title('Evolution of match between E map and image');
set([hXLabel, hYLabel, hTitle], ...
    'Color', [0,0,0], 'FontSize', 14, ...
    'Interpreter', 'Latex');
grid on;

hNewFig_H = figure;
plot(crit_H, matchPercent_H, 'r+', 'Linewidth', 3);
ylim([0 100]);
hXLabel = xlabel('Hardness modulus threshold');
hYLabel = ylabel('Match ($\%$)');
hTitle = title('Evolution of match between H map and image');
set([hXLabel, hYLabel, hTitle], ...
    'Color', [0,0,0], 'FontSize', 14, ...
    'Interpreter', 'Latex');
grid on;

% For elastic modulus vs hardness
diff_errorEH = zeros(length(crit_E), length(crit_H));
matchPercent_EH = zeros(length(crit_E), length(crit_H));
for ii = 1:length(crit_E)
    for jj = 1:length(crit_H)
        g.config.criterionBinMap_E = crit_E(ii);
        g.config.criterionBinMap_H = crit_H(jj);
        guidata(gcf, g);
        TriDiMap_runBin(1);
        diff_errorEH(ii,jj) = TriDiMap_diff_plotting(3,1);
        matchPercent_EH(ii,jj) = (1-diff_errorEH(ii,jj))*100;
    end
end

hNewFig_EH = figure;
%imagesc(crit_E, crit_H, matchPercent_EH);
surf(meshgrid(crit_E,1:numThres+1)', meshgrid(crit_H,1:numThres+1), ...
    matchPercent_EH);
colormap('gray');
xlim([0 max(crit_E)]);
ylim([0 max(crit_H)]);
zlim([0 100]);
hXLabel = xlabel('Elastic modulus threshold');
hYLabel = ylabel('Hardness threshold');
hZLabel = zlabel('Match ($\%$)');
hTitle = title('Evolution of match between E and H maps');
set([hXLabel, hYLabel, hZLabel, hTitle], ...
    'Color', [0,0,0], 'FontSize', 14, ...
    'Interpreter', 'Latex');
grid on;
view(0,90); 

end