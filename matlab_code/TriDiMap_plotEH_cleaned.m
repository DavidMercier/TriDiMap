%% Copyright 2014 MERCIER David
function TriDiMap_plotEH_cleaned
% Function to plot E vs H graphics in different configurations

%% Get data from the main TriDiMap GUI
g = guidata(gcf);
Hmat = rot90(g.data.expValues_mat.H);
Emat = rot90(g.data.expValues_mat.YM);
H_HardPh_Ref = 3.9;
E_HardPh_Ref = 219.7;
H_SoftPh_Ref = 11.7;
E_SoftPh_Ref = 343.2;
xMax = max(max(Hmat));
yMax = max(max(Emat));
critH = g.config.criterionBinMap_H;
critE = g.config.criterionBinMap_E;
xData = 0:1:1.2*round(xMax);
yData = 0:1:1.2*round(yMax);

%% Display mean and std values for each phases after matching and cleaning process
g.results.meanH_softPh = nanmean(Hmat(g.results.diffH==0 & g.results.diffE==0));
g.results.meandH_softPh = nanstd(Hmat(g.results.diffH==0 & g.results.diffE==0));
g.results.meanH_hardPh = nanmean(Hmat(g.results.diffH==1 & g.results.diffE==1));
g.results.meandH_hardPh = nanstd(Hmat(g.results.diffH==1 & g.results.diffE==1));
g.results.meanE_softPh = nanmean(Emat(g.results.diffH==0 & g.results.diffE==0));
g.results.meandE_softPh = nanstd(Emat(g.results.diffH==0 & g.results.diffE==0));
g.results.meanE_hardPh = nanmean(Emat(g.results.diffH==1 & g.results.diffE==1));
g.results.meandE_hardPh = nanstd(Emat(g.results.diffH==1 & g.results.diffE==1));

clc;
display('Cleaned mean hardness and std deviation for the soft phase:');
display(strcat('(',num2str(g.results.meanH_softPh), '±', ...
    num2str(g.results.meandH_softPh),')', g.config.strUnit_Property));

display('Cleaned mean hardness and std deviation for the hard phase:');
display(strcat('(',num2str(g.results.meanH_hardPh), '±', ...
    num2str(g.results.meandH_hardPh),')', g.config.strUnit_Property));

display('Cleaned mean elastic modulus and std deviation for the soft phase:');
display(strcat('(',num2str(g.results.meanE_softPh), '±', ...
    num2str(g.results.meandE_softPh),')', g.config.strUnit_Property));

display('Cleaned mean elastic modulus and std deviation for the hard phase:');
display(strcat('(',num2str(g.results.meanE_hardPh), '±', ...
    num2str(g.results.meandE_hardPh),')', g.config.strUnit_Property));

guidata(gcf, g);

%% Plots
figure;
h1 = plot(Hmat(g.results.diffH==0), Emat(g.results.diffH==0), 'r+');
hold on;
h2 = plot(Hmat(g.results.diffH==1), Emat(g.results.diffH==1), 'bo');
hold on;
h3 = plot(Hmat(g.results.diffH==-1), Emat(g.results.diffH==-1), 'kx');
hold on;
h_line1 = plot(ones(1,length(yData))*critH,yData,'k--');
legend([h1 h2 h3], 'Soft phase', 'Hard phase', 'No match', ...
    'Location', 'SouthEast');
hXLabel = xlabel(strcat('Hardness (', g.config.strUnit_Property, ')'));
hYLabel = ylabel (strcat('Elastic modulus (', g.config.strUnit_Property, ')'));
FontSizeVal = 14;
set([h1 h2 h3 h_line1], 'Linewidth', 1.5);
set([hXLabel, hYLabel], ...
    'Color', [0,0,0], 'FontSize', FontSizeVal, ...
    'Interpreter', 'Latex');
xlim([0 1.2*xMax]);
ylim([0 1.2*yMax]);
set(gca, 'Fontsize', FontSizeVal);

figure;
h4 = plot(Hmat(g.results.diffE==0), Emat(g.results.diffE==0), 'r+');
hold on;
h5 = plot(Hmat(g.results.diffE==1), Emat(g.results.diffE==1), 'bo');
hold on;
h6 = plot(Hmat(g.results.diffE==-1), Emat(g.results.diffE==-1), 'kx');
hold on;
h_line2 = plot(xData, ones(1,length(xData))*critE,'k--');
legend([h4 h5 h6], 'Soft phase', 'Hard phase', 'No match', ...
    'Location', 'SouthEast');
hXLabel = xlabel(strcat('Hardness (', g.config.strUnit_Property, ')'));
hYLabel = ylabel (strcat('Elastic modulus (', g.config.strUnit_Property, ')'));
FontSizeVal = 14;
set([h4 h5 h6 h_line2], 'Linewidth', 1.5);
set([hXLabel, hYLabel], ...
    'Color', [0,0,0], 'FontSize', FontSizeVal, ...
    'Interpreter', 'Latex');
xlim([0 1.2*xMax]);
ylim([0 1.2*yMax]);
set(gca, 'Fontsize', FontSizeVal);

figure;
h_all = plot(Hmat(g.results.diffH==0 & g.results.diffE==0), ...
    Emat(g.results.diffH==0 & g.results.diffE==0), 'x', ...
    'MarkerEdgeColor', [0.5 0.5 0.5]);
hold on;
h8 = plot(Hmat(g.results.diffH==1 & g.results.diffE==1), ...
    Emat(g.results.diffH==1 & g.results.diffE==1), 'k+');
hold on;
h_ref1 = plot(H_HardPh_Ref, E_HardPh_Ref, 'rs');
hold on;
h_ref2 = plot(H_SoftPh_Ref, E_SoftPh_Ref, 'bo');
hold on;
legend([h_all h8 h_ref1 h_ref2], ...
    'Soft phase', 'Hard phase', 'Soft ref', 'Hard ref',...
    'Location', 'SouthEast');
hXLabel = xlabel(strcat('Hardness (', g.config.strUnit_Property, ')'));
hYLabel = ylabel (strcat('Elastic modulus (', g.config.strUnit_Property, ')'));
FontSizeVal = 14;
set([h_all h8 h_ref1 h_ref2], 'Linewidth', 1.5);
set([hXLabel, hYLabel], ...
    'Color', [0,0,0], 'FontSize', FontSizeVal, ...
    'Interpreter', 'Latex');
xlim([0 1.2*xMax]);
ylim([0 1.2*yMax]);
set(gca, 'Fontsize', FontSizeVal);

figure;
h_all = plot(Hmat(g.results.diffH==0 & g.results.diffE==0), ...
    Emat(g.results.diffH==0 & g.results.diffE==0), 'x', ...
    'MarkerEdgeColor', [0.5 0.5 0.5]);
hold on;
h8 = plot(Hmat(g.results.diffH==1 & g.results.diffE==1), ...
    Emat(g.results.diffH==1 & g.results.diffE==1), 'k+');
hold on;
h_ref1 = plot(H_HardPh_Ref, E_HardPh_Ref, 'rs');
hold on;
h_ref2 = plot(H_SoftPh_Ref, E_SoftPh_Ref, 'bo');
hold on;
h9 = plot(Hmat(g.results.diffH==-1 & g.results.diffE==-1), ...
    Emat(g.results.diffH==-1 & g.results.diffE==-1), 'kx');
hold on;
h10 = plot(Hmat(g.results.diffH==-1 & (g.results.diffE==0 | g.results.diffE==1)), ...
    Emat(g.results.diffH==-1 & (g.results.diffE==0 | g.results.diffE==1)), 'g.');
hold on;
h11 = plot(Hmat((g.results.diffH==0 | g.results.diffH==1) & g.results.diffE==-1), ...
    Emat((g.results.diffH==0 | g.results.diffH==1) & g.results.diffE==-1), 'm*');
legend([h_all h8 h_ref1 h_ref2 h9 h10 h11], ...
    'Soft phase', 'Hard phase', 'Soft ref', 'Hard ref',...
    'No match', 'Only E valid', 'Only H valid', ...
    'Location', 'SouthEast');
hXLabel = xlabel(strcat('Hardness (', g.config.strUnit_Property, ')'));
hYLabel = ylabel (strcat('Elastic modulus (', g.config.strUnit_Property, ')'));
FontSizeVal = 14;
set([h_all h8 h_ref1 h_ref2], 'Linewidth', 1.5);
set([hXLabel, hYLabel], ...
    'Color', [0,0,0], 'FontSize', FontSizeVal, ...
    'Interpreter', 'Latex');
xlim([0 1.2*xMax]);
ylim([0 1.2*yMax]);
set(gca, 'Fontsize', FontSizeVal);

end