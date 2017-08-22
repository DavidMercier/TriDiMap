function TriDiMap_error_plotting
%% Plot difference between interpolated data and smoothed data
gui = guidata(gcf);

if gui.config.property == 1
    differenceVal = (gui.data.YM.expValuesInterpSmoothed' - ...
        gui.data.YM.expValuesInterp');
elseif gui.config.property == 2
    differenceVal = (gui.data.H.expValuesInterpSmoothed' - ...
        gui.data.H.expValuesInterp');
end

hError = surf(gui.data.xData_interp, gui.data.yData_interp, ...
    differenceVal,...
    'FaceColor','interp',...
    'EdgeColor','none',...
    'FaceLighting','gouraud');

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

if ~gui.config.flipColor
    colormap(gui.config.colorMap);
else
    colormap(flipud(gui.config.colorMap));
end
hcb = colorbar;
ylabel(hcb, 'Error map (GPa)', ...
    'Interpreter', 'Latex', ...
    'FontSize', gui.config.FontSizeVal);

end