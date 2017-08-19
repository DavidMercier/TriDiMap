function TriDiMap_error_plotting
%% Plot difference between interpolated data and smoothed data
gui = guidata(gcf);

if ~rawData
    differenceVal = (expValuesInterpSmoothed' - expValuesInterp'); %./expValuesInterp
    
    f = figure('position', [WX, WY, WW, WH]);
    colormap(gui.config.colorMap);
    
    hError = surf(xData_interp, yData_interp, differenceVal,...
        'FaceColor','interp',...
        'EdgeColor','none',...
        'FaceLighting','gouraud');
    
    axis equal;
    shading interp;
    view(0,90);
    
    hXLabel = xlabel('X coordinates ($\mu$m)');
    hYLabel = ylabel('Y coordinates ($\mu$m)');
    hZLabel = zlabel(zString);
    hTitle = title(['Mapping of difference', ...
        ' between interpolated and smoothed data']);
    set([hXLabel, hYLabel, hZLabel, hTitle], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    
    colormap('jet'); % Use flipud to reverse colormap
    hcb = colorbar;
    ylabel(hcb, 'Error map (GPa)', ...
        'Interpreter', 'Latex', ...
        'FontSize', FontSizeVal);
end

end