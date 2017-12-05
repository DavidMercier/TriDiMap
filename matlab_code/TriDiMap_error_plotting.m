%% Copyright 2014 MERCIER David
function TriDiMap_error_plotting
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

if strcmp(gui.config.strUnit_Length, 'µm')
    gui.config.strUnit_Length_Latex = '$\mu$m';
    hXLabel = xlabel(strcat({'X coordinates ('},gui.config.strUnit_Length_Latex, ')'));
    hYLabel = ylabel(strcat({'Y coordinates ('},gui.config.strUnit_Length_Latex, ')'));
else
    hXLabel = xlabel(strcat({'X coordinates ('},gui.config.strUnit_Length, ')'));
    hYLabel = ylabel(strcat({'Y coordinates ('},gui.config.strUnit_Length, ')'));
end
hZLabel = zlabel(gui.config.legend);
hTitle = title(['Mapping of difference', ...
    ' between interpolated and smoothed data']);
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
ylabel(gui.handle.hcb1, strcat('Error map (', gui.config.strUnit_Property,')'), ...
    'Interpreter', 'Latex', ...
    'FontSize', gui.config.FontSizeVal);

set(gca, 'Fontsize', gui.config.FontSizeVal);

guidata(gcf, gui);

end