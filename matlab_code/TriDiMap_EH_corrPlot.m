%% Copyright 2014 MERCIER David
function TriDiMap_EH_corrPlot
% Function to plot correlation between E-micro and H-micro difference maps
g = guidata(gcf);
if g.config.data_path
    cMap = g.config.colorMap;
    flagFlipCM = get(g.handles.cb_flipColormap_GUI, 'Value');
    strTitle = 'E-H difference map';
    
    diffEH = (g.results.diffE + g.results.diffH);
    diffEH(diffEH==2) = 1;
    diffEH(diffEH==-2) = -1;
    
    % New plot
    figure;
    hFig = imagesc(flipud(diffEH), ...
        'XData',g.data.xData_interp,'YData',g.data.yData_interp);
    
    axisMap(cMap, strTitle, g.config.FontSizeVal, ...
        (g.config.N_XStep_default-1)*g.config.XStep_default, ...
        (g.config.N_YStep_default-1)*g.config.YStep_default, ...
        g.config.flipColor, g.config.strUnit_Length);
    colormap(cMap);
    
    set(gca,'YDir','normal');
    axis equal;
    axis tight;
    hold on;
    % delete(findall(findall(gcf,'Type','axe'),'Type','text'));
    % axis off; box off;
    % set(gca,'units','normalized','position',[0 0 1 1]);
    % export_fig('test', isolate_axes(gca));
    
    cmap = colormap;
    
    % Legend for E-micro and H-micro maps
    if flagFlipCM
        hFig(2) = plot(NaN,NaN,'sk','MarkerFaceColor',max(cmap));
        hFig(3) = plot(NaN,NaN,'sk','MarkerFaceColor',mean(cmap));
        hFig(4) = plot(NaN,NaN,'sk','MarkerFaceColor',min(cmap));
    else
        hFig(2) = plot(NaN,NaN,'sk','MarkerFaceColor',min(cmap));
        hFig(3) = plot(NaN,NaN,'sk','MarkerFaceColor',mean(cmap));
        hFig(4) = plot(NaN,NaN,'sk','MarkerFaceColor',max(cmap));
    end
    hLeg = legend([hFig(2) hFig(3) hFig(4)], ...
        'No Match','Soft match','Stiff/Hard match', ...
        'Location','EastOutside');
    legend boxoff;
else
    errordlg(['First set indentation grid parameters and load an Excel file '...
        'to plot a property map !']);
end

end