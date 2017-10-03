%% Copyright 2014 MERCIER David
function TriDiMap_image_plotting
%% Function to plot a microscopical image
gui = guidata(gcf);
cMap = gui.config.colorMap;

hFig(1) = imagesc(flipud(gui.image.image2use), ...
    'XData',gui.data.xData_interp,'YData',gui.data.yData_interp);
axisMap(cMap, 'Binarized microscopical image', ...
    gui.config.FontSizeVal, ...
    (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
    (gui.config.N_YStep_default-1)*gui.config.YStep_default,...
    gui.config.flipColor, gui.config.strUnit_Length);
axis equal;
axis tight;
hold on;
if get(gui.handles.cb_legend_GUI, 'Value')
    cmap = colormap;
    hFig(2) = plot(NaN,NaN,'sk','MarkerFaceColor',min(cmap));
    hFig(3) = plot(NaN,NaN,'sk','MarkerFaceColor',max(cmap));
    gui.handles.hLeg1 = legend([hFig(2) hFig(3)],'Stiff/Hard phase','Soft phase',...
        'Location','EastOutside');
    pos = get(gui.handles.hLeg1,'position');
    set(gui.handles.hLeg1, 'position',[0.87 0.70 pos(3:4)]);
    legend boxoff;
else
    legend('hide');
end

guidata(gcf, gui);

end