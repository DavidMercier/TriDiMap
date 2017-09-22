%% Copyright 2014 MERCIER David
function TriDiMap_mapping_plotting
%% Function to plot a 3D map of material properties in function of X/Y coordinates
gui = guidata(gcf);

FontSizeVal = gui.config.FontSizeVal;
xData_interp = gui.data.xData_interp;
yData_interp = gui.data.yData_interp;
data2plot = gui.data.data2plot;
cMap = gui.config.colorMap;

if strcmp(get(gui.handles.binarization_GUI, 'String'), 'BINARIZATION')
    zString = gui.config.legend;
    cmin = gui.config.cmin;
    cmax = gui.config.cmax;
    Markers = gui.config.Markers;
    xData_markers = gui.data.xData_markers;
    yData_markers = gui.data.yData_markers;
    intervalScaleBar = gui.config.intervalScaleBar;
    rawData = gui.config.rawData;
    contourPlot = gui.config.contourPlot;
    logZ = gui.config.logZ;
    minorTicks = gui.config.minorTicks;
    
    %% 1 map (with or without markers)
    if gui.config.cminOld < 0
        gui.config.cminOld = 0;
    end
    if logZ
        if cmin < 1
            cmin = 1;
            set(gui.handles.value_colorMin_GUI, 'String', num2str(cmin));
        end
        if gui.config.cminOld == 0
            gui.config.cminOld = 1;
        end
    end
    
    if ~rawData
        if ~contourPlot
            hFig = surf(xData_interp, yData_interp, data2plot',...
                'FaceColor','interp',...
                'EdgeColor','none',...
                'FaceLighting','gouraud');
            % 'Marker', '+'
            shading interp;
        else
            if logZ
                contourf(xData_interp, yData_interp, log(data2plot'),...
                    intervalScaleBar);
            else
                contourf(xData_interp, yData_interp, data2plot',...
                    intervalScaleBar);
            end
        end
    else
        if logZ
            hFig = imagesc(real(log(data2plot')),...
                'XData',xData_interp,'YData',yData_interp);
        else
            hFig = imagesc((data2plot'),...
                'XData',xData_interp,'YData',yData_interp);
            %             zVal = zeros(length(xData_interp));
            %             hFig = scatter3(xData_interp, yData_interp, zVal);
        end
        set(gca,'YDir','normal');
        set(hFig,'alphadata',~isnan(data2plot'));
    end
    
    hold on;
    maxVal = max(max(data2plot));
    
    % Set z positions of markers
    if ~contourPlot
        markersVal = ones(size(xData_markers,1),size(xData_markers,2)) * maxVal;
    else
        markersVal = ones(size(xData_markers,1),size(xData_markers,2));
    end
    
    hold on;
    
    if Markers
        plot3(xData_markers', yData_markers', markersVal','k+');
        hold on;
    end
    
    axis equal;
    axis tight;
    if length(xData_interp) > 5*length(yData_interp) || length(yData_interp) > 5*length(xData_interp)
        axis normal;
    end
    view(0,90);
    %zlim([0 2]);
    zlim auto;
    if logZ && ~contourPlot
        set(gca, 'zsc', 'log');
        %set(hFig, 'cdata', real(log10(get(hFig, 'cdata'))));
    end
    if logZ && rawData
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
    hTitle(1) = title(strcat({'Mapping of '}, zString));
    set([hXLabel, hYLabel, hZLabel, hTitle(1)], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    
    % Set number of intervals to 0 for a continuous scalebar.
    if intervalScaleBar > 0
        if ~rawData
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
        cmap_Flip = colormap(cmap);
        if ~gui.config.flipColor
            colormap(cmap_Flip);
        else
            colormap(flipud(cmap_Flip));
        end
    elseif intervalScaleBar == 0
        cmap_Flip = colormap([cMap, '(',num2str(10000),')']);
        if ~gui.config.flipColor
            colormap(cmap_Flip);
        else
            colormap(flipud(cmap_Flip));
        end
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
        elseif logZ && rawData
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
    
    Contours = cmin:(cmax-cmin)/intervalScaleBar:cmax;
    if logZ && contourPlot
        hcb1 = colorbar('YTick',log(Contours),'YTickLabel',Contours);
    elseif logZ && rawData
        hcb1 = colorbar('YTick',log(Contours),'YTickLabel',Contours);
    else
        hcb1 = colorbar;
    end
    
    if minorTicks
        set(hcb1, 'YMinorTick', 'on');
    end
    %if logScale
    %hcb1 = colorbar('Yscale','log');
    %end
    ylabel(hcb1, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
    set(gca, 'Fontsize', FontSizeVal);
    hold off;
    
else
    cMap = gui.config.colorMap;
    
    hFig = imagesc((data2plot'),...
        'XData',xData_interp,'YData',yData_interp);
    set(gca,'YDir','normal');
    set(hFig,'alphadata',~isnan(data2plot'));
    axisMap(cMap, ['Binarized ', gui.legend, ' ', 'map'], ...
        gui.config.FontSizeVal, ...
        (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
        (gui.config.N_YStep_default-1)*gui.config.YStep_default, ...
        gui.config.flipColor);
    axis equal;
    axis tight;
end

guidata(gcf, gui);

end