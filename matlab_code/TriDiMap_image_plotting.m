%% Copyright 2014 MERCIER David
function TriDiMap_image_plotting
%% Function to plot a microscopical image
gui = guidata(gcf);

cMap = gui.config.colorMap;

hFig = imagesc(flipud(gui.image.image2use), ...
    'XData',gui.data.xData_interp,'YData',gui.data.yData_interp);
axisMap(cMap, 'Binarized microscopical image', ...
    gui.config.FontSizeVal, ...
    (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
    (gui.config.N_YStep_default-1)*gui.config.YStep_default,...
    gui.config.flipColor);
axis equal;
axis tight;

guidata(gcf, gui);

end