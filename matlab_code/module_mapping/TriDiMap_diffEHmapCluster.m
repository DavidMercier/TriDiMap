% Copyright 2014 MERCIER David
function TriDiMap_diffEHmapCluster
%% Function to plot difference map between clusterized mechanical map and
% microstructural map using E-H plot
TriDiMap_loadingImage(0);

g = guidata(gcf);
cMap = g.config.colorMap;
strTitle = 'EvsH-Image difference map';
flagFlipCM = 0;

data2plot = rot90(g.data.dataH_SectorLabMat);
image2plot = g.image.image2use;

g.results.diffEHmap = (data2plot-1) + (double(image2plot))/255;
g.results.diffEHmap(g.results.diffEHmap==1) = -1; % No Match
g.results.diffEHmap(g.results.diffEHmap==2) = 1; % Hard phase
g.results.diffEHmap(g.results.diffEHmap==0) = 0; % Soft phase


diff_error = (1-(sum(sum(abs(g.results.diffEHmap)))/ ...
    (g.config.N_XStep_default * g.config.N_YStep_default)))*100;
data2plot_soft = (data2plot==0);
image2plot_soft = (image2plot==0);
g.results.matchSoft = ((data2plot_soft + image2plot_soft)==2);
data2plot_hard = (data2plot==255);
image2plot_hard = (image2plot==255);
g.results.matchHard = ((data2plot_hard + image2plot_hard)==2);

figure;
hAxis = surf(flipud(g.results.diffEHmap), ...
    'XData',g.data.xData_interp,'YData',g.data.yData_interp);

axisMap(cMap, strTitle, g.config.FontSizeVal, ...
    (g.config.N_XStep_default-1)*g.config.XStep_default, ...
    (g.config.N_YStep_default-1)*g.config.YStep_default, ...
    g.config.flipColor, g.config.strUnit_Length);
axis equal;
axis tight;
hold on;
view([0 90]);
shading flat;

g.handles.hLeg2 = legendMap(3, cMap, 'EastOutside', ...
    {'No Match','Soft match', 'Stiff/Hard match'}, 12, ...
    flagFlipCM, [0.85 0.3]);

disp(diff_error);
Hmat = rot90(g.data.expValues_mat.H);
Emat = rot90(g.data.expValues_mat.YM);
g.results.meanH_softPh = nanmean(Hmat(g.results.diffEHmap==0));
g.results.meandH_softPh = nanstd(Hmat(g.results.diffEHmap==0));
g.results.meanH_hardPh = nanmean(Hmat(g.results.diffEHmap==1));
g.results.meandH_hardPh = nanstd(Hmat(g.results.diffEHmap==1));
g.results.meanE_softPh = nanmean(Emat(g.results.diffEHmap==0));
g.results.meandE_softPh = nanstd(Emat(g.results.diffEHmap==0));
g.results.meanE_hardPh = nanmean(Emat(g.results.diffEHmap==1));
g.results.meandE_hardPh = nanstd(Emat(g.results.diffEHmap==1));

clc;
disp('Cleaned mean hardness and std deviation for the soft phase:');
disp(strcat('(',num2str(g.results.meanH_softPh), '±', ...
    num2str(g.results.meandH_softPh),')', g.config.strUnit_Property));

disp('Cleaned mean hardness and std deviation for the hard phase:');
disp(strcat('(',num2str(g.results.meanH_hardPh), '±', ...
    num2str(g.results.meandH_hardPh),')', g.config.strUnit_Property));

disp('Cleaned mean elastic modulus and std deviation for the soft phase:');
disp(strcat('(',num2str(g.results.meanE_softPh), '±', ...
    num2str(g.results.meandE_softPh),')', g.config.strUnit_Property));

disp('Cleaned mean elastic modulus and std deviation for the hard phase:');
disp(strcat('(',num2str(g.results.meanE_hardPh), '±', ...
    num2str(g.results.meandE_hardPh),')', g.config.strUnit_Property));

guidata(gcf, g);


end