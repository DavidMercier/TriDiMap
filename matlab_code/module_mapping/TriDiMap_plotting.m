%% Copyright 2014 MERCIER David
function TriDiMap_plotting(xData_interp, yData_interp, data2plot, flagPlot)
% Function to set plots
gui = guidata(gcf);
FontSizeVal = gui.config.FontSizeVal;
rawData = gui.config.rawData;
logZ = gui.config.logZ;
cMap = gui.config.colorMap;
cmin = gui.config.cmin;
cmax = gui.config.cmax;
intervalScaleBar = gui.config.intervalScaleBar;
contourPlot = gui.config.contourPlot;

if ~rawData == 8
    zString = gui.config.legend;
    titleString = gui.config.legend;
else
    zString = gui.config.legendSlice;
    titleString = gui.config.legend;
end

if flagPlot
    hold on;
    
    axis equal;
    axis tight;
    if length(xData_interp) > 5*length(yData_interp) || length(yData_interp) > 5*length(xData_interp)
        axis normal;
    end
    if rawData == 1
        view(2); % or view(0,90);
    else
        view(3);
    end
    %zlim([0 2]);
    zlim auto;
    daspect([1 1 gui.config.zAxisRatioVal]);
    if logZ && ~contourPlot
        set(gca, 'zsc', 'log');
        %set(hFig, 'cdata', real(log10(get(hFig, 'cdata'))));
    end
    if logZ && rawData ==1
        set(gca, 'zsc', 'linear');
    end
    hold on;
    
    if strcmp(gui.config.strUnit_Length, 'µm')
        gui.config.strUnit_Length_Latex = '$\mu$m';
        hXLabel = xlabel(strcat({'X coordinates ('},gui.config.strUnit_Length_Latex, ')'));
        if ~gui.config.flagZplot
            hYLabel = ylabel(strcat({'Y coordinates ('},gui.config.strUnit_Length_Latex, ')'));
        else
            hYLabel = ylabel(strcat({'Z coordinates ('},gui.config.strUnit_Length_Latex, ')'));
        end
    else
        hXLabel = xlabel(strcat({'X coordinates ('},gui.config.strUnit_Length, ')'));
        if ~gui.config.flagZplot
            hYLabel = ylabel(strcat({'Y coordinates ('},gui.config.strUnit_Length, ')'));
        else
            hYLabel = ylabel(strcat({'Z coordinates ('},gui.config.strUnit_Length, ')'));
        end
    end
    hZLabel = zlabel(zString);
    hTitle(1) = title(strcat({'Mapping of '}, titleString));
    set([hXLabel, hYLabel, hZLabel, hTitle(1)], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    
    % Set number of intervals to 0 for a continuous scalebar.
    [token, remain] = strtok(cMap);
    if intervalScaleBar > 0
        if strcmp(token,'DivergingMap') == 1
            [RGB1, RGB2] = listDivCmap(str2num(remain));
            cmap = diverging_map(0:(1/(intervalScaleBar-1)):1,RGB1,RGB2);
        else
            if rawData == 2
                if ~contourPlot
                    cmap = [cMap, '(',num2str(intervalScaleBar),')'];
                else
                    if logZ
                        cmap = cMap;
                    else
                        cmap = [cMap, '(',num2str(intervalScaleBar),')'];
                    end
                end
            else
                if logZ
                    cmap = cMap;
                else
                    cmap = [cMap, '(',num2str(intervalScaleBar),')'];
                end
            end
        end
        cmap_Flip = colormap(cmap);
    elseif intervalScaleBar == 0
        intervalScaleBar = 10000;
        if strcmp(cMap,'Diverging map') == 1
            [RGB1, RGB2] = listDivCmap(remain);
            cmap_Flip = diverging_map(0:(1/(intervalScaleBar-1)):1,RGB1,RGB2);
        else
            cmap_Flip = colormap([cMap, '(',num2str(intervalScaleBar),')']);
            
        end
    end
    if ~gui.config.flipColor
        colormap(cmap_Flip);
    else
        colormap(flipud(cmap_Flip));
    end
    if ~gui.config.scaleAxis
        if cmin == round(min(data2plot(:)))
            cmin = gui.config.cminOld;
            set(gui.handles.value_colorMin_GUI, 'String', num2str(cmin));
        end
        if cmax == round(max(data2plot(:)))
            cmax = gui.config.cmaxOld;
            set(gui.handles.value_colorMax_GUI, 'String', num2str(cmax));
        end
        if cmin >= cmax
            cmax = cmin*1.2;
            warning('Minimum property value has to be lower than the maximum property value !');
            gui.config.cmax = cmax;
            set(gui.handles.value_colorMax_GUI, 'String', num2str(cmax));
        end
        if logZ && contourPlot
            caxis(log([cmin, cmax]));
        elseif logZ && rawData == 1
            caxis(log([cmin, cmax]));
        else
            caxis([cmin, cmax]);
        end
    else
        if cmin ~= round(min(data2plot(:)))
            gui.config.cminOld = str2num(get(gui.handles.value_colorMin_GUI, 'String'));
        end
        if cmax ~= round(max(data2plot(:)))
            gui.config.cmaxOld = str2num(get(gui.handles.value_colorMax_GUI, 'String'));
        end
        set(gui.handles.value_colorMin_GUI, 'String', num2str(round(min(data2plot(:)))));
        set(gui.handles.value_colorMax_GUI, 'String', num2str(round(max(data2plot(:)))));
        gui.config.cmin = num2str(round(min(data2plot(:))));
        gui.config.cmax = num2str(round(max(data2plot(:))));
    end
    
    Contours = cmin:(cmax-cmin)/intervalScaleBar:cmax;
    if logZ && contourPlot
        hcb1 = colorbar('YTick',log(Contours),'YTickLabel',Contours);
    elseif logZ && rawData == 1
        hcb1 = colorbar('YTick',log(Contours),'YTickLabel',Contours);
    else 
        hcb1 = colorbar;
    end
    
    %if logScale
    %hcb1 = colorbar('Yscale','log');
    %end
    ylabel(hcb1, titleString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
    gui.handles.hcb1 = hcb1;
    set(gca, 'Fontsize', FontSizeVal);
    hold off;
    guidata(gcf, gui);
else
    errordlg('Wrong map size for 3D plot!');
end
guidata(gcf, gui);
end