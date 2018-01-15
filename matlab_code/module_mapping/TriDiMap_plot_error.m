%% Copyright 2014 MERCIER David
function TriDiMap_plot_error
%% Plot difference between interpolated data and smoothed data
gui = guidata(gcf);

differenceVal = (gui.data.expValuesInterpSmoothed' - ...
    gui.data.expValuesInterp');

if size(differenceVal,2) == 1
    hError = imagesc(gui.data.xData_interp, gui.data.yData_interp, ...
        differenceVal);
else
    hError = surf(gui.data.xData_interp, gui.data.yData_interp, ...
        differenceVal,...
        'FaceColor','interp',...
        'EdgeColor','none',...
        'FaceLighting','gouraud');
end

axis equal;
shading interp;
view(0,90);
if ~gui.config.FrenchLeg
    xLab = 'X coordinates (';
    yLab = 'Y coordinates (';
else
    xLab = 'Coordonnées X (';
    yLab = 'Coordonnées Y (';
end
if strcmp(gui.config.strUnit_Length, 'µm')
    gui.config.strUnit_Length_Latex = '$\mu$m';
    hXLabel = xlabel(strcat({xLab},gui.config.strUnit_Length_Latex, ')'));
    hYLabel = ylabel(strcat({yLab},gui.config.strUnit_Length_Latex, ')'));
else
    hXLabel = xlabel(strcat({xLab},gui.config.strUnit_Length, ')'));
    hYLabel = ylabel(strcat({yLab},gui.config.strUnit_Length, ')'));
end
hZLabel = zlabel(gui.config.legend);
if ~gui.config.FrenchLeg
    titLab = 'Mapping of difference between interpolated and smoothed data';
else
    titLab = 'Cartographie des différences entre les données interpolées et lissées';
end
hTitle = title(titLab);
set([hXLabel, hYLabel, hZLabel, hTitle], ...
    'Color', [0,0,0], 'FontSize', gui.config.FontSizeVal, ...
    'Interpreter', 'Latex');

[token, remain] = strtok(gui.config.colorMap);
if strcmp(token, 'DivergingMap');
    [RGB1, RGB2] = listDivCmap(str2num(remain));
    cmapStr = diverging_map(0:(1/10000):1,RGB1,RGB2);
else
    cmapStr = gui.config.colorMap;
end
if ~gui.config.flipColor
    colormap(cmapStr);
else
    colormap(flipud(cmapStr));
end
gui.handle.hcb1 = colorbar;
if ~gui.config.FrenchLeg
    yTxt = 'Error map (';
else
    yTxt = 'Carte erreur (';
end
ylabel(gui.handle.hcb1, strcat(yTxt, gui.config.strUnit_Property,')'), ...
    'Interpreter', 'Latex', ...
    'FontSize', gui.config.FontSizeVal);

set(gca, 'Fontsize', gui.config.FontSizeVal);

guidata(gcf, gui);

end