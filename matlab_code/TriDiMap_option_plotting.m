%% Copyright 2014 MERCIER David
function TriDiMap_option_plotting
% Function to set plot options

gui = guidata(gcf);
data2plot = gui.data.data2plot;
FontSizeVal = gui.config.FontSizeVal;

if gui.config.minorTicks;
    set(gui.handle.hcb1, 'YMinorTick', 'on');
end

if gui.config.grid
    grid on;
else
    grid off;
end

if gui.config.MinMax
    [rowMin, colMin] = find(data2plot==min(data2plot(:)));
    [rowMax, colMax] = find(data2plot==max(data2plot(:)));
    strmin = min(data2plot(:));
    strmax = max(data2plot(:));
    
    %((round(abs(x_value)/gui.config.XStep)+1)*gui.config.interpFactVal)-(gui.config.interpFactVal-1)
    text(...
        (((rowMax+(gui.config.interpFactVal-1))/gui.config.interpFactVal)-1)*gui.config.XStep, ...
        (((colMax+(gui.config.interpFactVal-1))/gui.config.interpFactVal)-1)*gui.config.YStep, ...
        num2str(strmax), 'Color','Black','FontSize',FontSizeVal);
    if gui.config.flagZplot
        text(...
            (((rowMin+(gui.config.interpFactVal-1))/gui.config.interpFactVal)-1)*gui.config.XStep, ...
            -(((colMin+(gui.config.interpFactVal-1))/gui.config.interpFactVal)-1)*gui.config.YStep, ...
            num2str(strmin), 'Color','Black','FontSize',FontSizeVal);
    else
        text(...
            (((rowMin+(gui.config.interpFactVal-1))/gui.config.interpFactVal)-1)*gui.config.XStep, ...
            (((colMin+(gui.config.interpFactVal-1))/gui.config.interpFactVal)-1)*gui.config.YStep, ...
            num2str(strmin), 'Color','Black','FontSize',FontSizeVal);
    end
end

xData_markers = gui.data.xData_markers;
yData_markers = gui.data.yData_markers;
maxVal = max(max(data2plot));

% Set z positions of markers
if ~gui.config.contourPlot;
    markersVal = ones(size(xData_markers,1),size(xData_markers,2)) * maxVal;
else
    markersVal = ones(size(xData_markers,1),size(xData_markers,2));
end

hold on;

if gui.config.Markers
    plot3(xData_markers', yData_markers', markersVal','k+');
    hold on;
end
end