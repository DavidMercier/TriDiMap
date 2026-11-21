function TriDiMap_plotPhaseLabels(ax, labels, displayLabels, gui, titleText)
set(gcf, 'CurrentAxes', ax);
colorbar off;
cla(ax);
imagesc(flipud(labels), 'XData', gui.data.xData_interp, ...
    'YData', gui.data.yData_interp);
axisMap([], titleText, gui.config.FontSizeVal, ...
    (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
    (gui.config.N_YStep_default-1)*gui.config.YStep_default, ...
    gui.config.flipColor, gui.config.strUnit_Length);

phaseCount = numel(displayLabels);
if isfield(gui.config, 'grayscalePlots') && gui.config.grayscalePlots
    palette = gray(phaseCount);
else
    palette = lines(phaseCount);
end
if gui.config.flipColor
    palette = flipud(palette);
end
colormap(ax, palette);
caxis(ax, [0.5, phaseCount+0.5]);
bar = colorbar;
set(bar, 'Ticks', 1:phaseCount, 'TickLabels', displayLabels);
axis equal;
axis tight;
end
