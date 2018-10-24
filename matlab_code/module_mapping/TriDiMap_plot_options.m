%% Copyright 2014 MERCIER David
function TriDiMap_plot_options(xData_interp, yData_interp, ...
    data2plot, flagPlot, varargin)
%% Function to set plots

gui = guidata(gcf);
FontSizeVal = gui.config.FontSizeVal;
rawData = gui.config.rawData;
logZ = gui.config.logZ;
if ~get(gui.handles.cb_plotSectMap_GUI, 'Value')
    cminVal = gui.config.cmin;
    cmaxVal = gui.config.cmax;
    intervalScaleBar = gui.config.intervalScaleBar;
    cMap = gui.config.colorMap;
else
    if gui.config.plotClusters == 2
        cMap = [1 1 1
            0 0 0
            1 0 0
            0 1 0
            0 0 1];% w k r g b
        cminVal = 0;
        cmaxVal = 4;
        intervalScaleBar = 4;
    elseif gui.config.plotClusters == 3
        if gui.config.K_GMM == 2
            cMap = [1 0 0;0 0 1]; %b r
            cminVal = 0;
            cmaxVal = gui.config.K_GMM;
            intervalScaleBar = gui.config.K_GMM;
        elseif gui.config.K_GMM == 3
            cMap = [0 0 1; 1 0 0; 0 1 0]; %b r g
            cminVal = 0;
            cmaxVal = gui.config.K_GMM;
            intervalScaleBar = gui.config.K_GMM;
            
        end
    end
end
contourPlot = gui.config.contourPlot;

if nargin == 0
    xData_interp = NaN;
    yData_interp = NaN;
    if rawData < 8
        data2plot = gui.data.data2plot;
    else
        if ~get(gui.handles.cb_plotSectMap_GUI, 'Value')
            data2plot = gui.slice_data_mat.InterSmoothed;
        else
            data2plot = gui.data.dataH_Sector;
        end
    end
    flagPlot = 1;
end

if ~rawData == 8
    zString = gui.config.legend;
    titleString = gui.config.legend;
else
    zString = gui.config.legendSlice;
    titleString = gui.config.legend;
end

if get(gui.handles.cb_plotSectMap_GUI, 'Value')
    titleString = 'Phase';
end

if flagPlot
    hold on;
    
    axis equal;
    axis tight;
    if length(xData_interp) > 5*length(yData_interp) || ...
            length(yData_interp) > 5*length(xData_interp)
        axis normal;
    end
    if rawData == 1 || gui.config.plotClusters > 1
        view(2); % or view(0,90);
    else
        view(3);
    end
    %zlim([0 2]);
    zlim auto;
    daspect([1 1 gui.config.zAxisRatioVal]);
    set(gca, 'zsc', 'linear');
    hold on;
    
    if strcmp(gui.config.strUnit_Length, 'µm')
        gui.config.strUnit_Length_Latex = '$\mu$m';
        hXLabel = xlabel(strcat({'X coordinates ('},...
            gui.config.strUnit_Length_Latex, ')'));
        if ~gui.config.flagZplot
            hYLabel = ylabel(strcat({'Y coordinates ('},...
                gui.config.strUnit_Length_Latex, ')'));
        else
            hYLabel = ylabel(strcat({'Z coordinates ('},...
                gui.config.strUnit_Length_Latex, ')'));
        end
    else
        hXLabel = xlabel(strcat({'X coordinates ('},...
            gui.config.strUnit_Length, ')'));
        if ~gui.config.flagZplot
            hYLabel = ylabel(strcat({'Y coordinates ('},...
                gui.config.strUnit_Length, ')'));
        else
            hYLabel = ylabel(strcat({'Z coordinates ('},...
                gui.config.strUnit_Length, ')'));
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
                    if ~get(gui.handles.cb_plotSectMap_GUI, 'Value')
                        cmap = [cMap, '(',num2str(intervalScaleBar),')'];
                    else
                        cmap = cMap;
                    end
                end
            end
        end
        cmap_Flip = colormap(cmap);
    elseif intervalScaleBar == 0
        intervalScaleBar = 10000;
        if strcmp(token,'DivergingMap') == 1
            [RGB1, RGB2] = listDivCmap(str2num(remain));
            cmap_Flip = diverging_map(0:(1/(intervalScaleBar-1)):1,RGB1,RGB2);
        else
            cmap_Flip = colormap([cMap, '(',num2str(intervalScaleBar),')']);
        end
    end
    if ~gui.config.noNan
        cMapNaN = [1 1 1 ; cmap_Flip];
    else
        cMapNaN = cmap_Flip;
    end
    if ~gui.config.flipColor
        colormap(cMapNaN);
    else
        colormap(flipud(cMapNaN));
    end
    if ~get(gui.handles.cb_plotSectMap_GUI, 'Value')
        if ~gui.config.scaleAxis
            if cminVal == round(min(data2plot(:)))
                cminVal = gui.config.cminOld;
                set(gui.handles.value_colorMin_GUI, 'String', num2str(cminVal));
            end
            if cmaxVal == round(max(data2plot(:)))
                cmaxVal = gui.config.cmaxOld;
                set(gui.handles.value_colorMax_GUI, 'String', num2str(cmaxVal));
            end
            if cminVal >= cmaxVal
                cmaxVal = cminVal*1.2;
                warning('Minimum property value has to be lower than the maximum property value !');
                gui.config.cmaxVal = cmaxVal;
                set(gui.handles.value_colorMax_GUI, 'String', num2str(cmaxVal));
            end
            if logZ && cminVal <= 0
                cminVal = eps;
            end
            if logZ
                caxis(log([cminVal, cmaxVal]));
            else
                caxis([cminVal, cmaxVal]);
            end
        else
            if cminVal ~= round(min(data2plot(:)))
                gui.config.cminValOld = ...
                    str2double(get(gui.handles.value_colorMin_GUI, 'String'));
            end
            if cmaxVal ~= round(max(data2plot(:)))
                gui.config.cmaxValOld = ...
                    str2double(get(gui.handles.value_colorMax_GUI, 'String'));
            end
            set(gui.handles.value_colorMin_GUI, 'String', num2str(round(min(data2plot(:)))));
            set(gui.handles.value_colorMax_GUI, 'String', num2str(round(max(data2plot(:)))));
            gui.config.cminVal = num2str(round(min(data2plot(:))));
            gui.config.cmaxVal = num2str(round(max(data2plot(:))));
        end
    end
    hold on;
    
    ContoursVal = cminVal:((cmaxVal-cminVal)/intervalScaleBar):cmaxVal;
    if logZ
        logCVal = log(ContoursVal);
        if max(ContoursVal) < 100
            ContoursVal = round(ContoursVal*10)/10;
        else
            ContoursVal = round(ContoursVal);
        end
        hcb1 = colorbar('YTick',logCVal,'YTickLabel',ContoursVal);
    else
        hcb1 = colorbar;
    end
    
    %     if logScale
    %         hcb1 = colorbar('Yscale','log');
    %     end
    ylabel(hcb1, titleString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
    gui.handles.hcb1 = hcb1;
    set(gca, 'Fontsize', FontSizeVal);
    hold off;
    guidata(gcf, gui);
    
    if gui.config.minorTicks
        %         if sscanf(gui.config.MatlabRelease,'(R%i') > 2014
        try
            set(gui.handles.hcb1, 'YMinorTick', 'on');
        catch err
            display(err.message);
            gui.handles.ha = axes('position',gui.handles.hcb1.Position);
            gui.handles.ha.YLim = gui.handles.hcb1.Limits;
            gui.handles.ha.Color = 'none';
            gui.handles.ha.XColor = 'none';
            gui.handles.ha.YTickLabelRotation = 45.0;
            gui.handles.ha.YTickLabel = [];
            gui.handles.ha.XTickLabel = [];
            gui.handles.ha.YTick = gui.handles.hcb1.Ticks;
            gui.handles.ha.TickDir = gui.handles.hcb1.TickDirection;
            gui.handles.ha.Box = 'on';
            set(gui.handles.ha,'YMinorTick','on');
        end
        %         else
        %             try
        %                 set(gui.handles.hcb1, 'YMinorTick', 'on');
        %             catch err
        %                 display(err.message);
        %             end
        %         end
    else
        try
            delete(gui.handles.ha);
        catch
        end
    end
else
    errordlg('Wrong plot! Try again...');
end
if get(gui.handles.cb_plotSectMap_GUI, 'Value')
    colorbar off
end

if gui.config.grid
    grid on;
else
    grid off;
end

if gui.config.MinMax
    [rowMin, colMin] = find(data2plot==min(data2plot(:)));
    [rowMax, colMax] = find(data2plot==max(data2plot(:)));
    strmin = num2str(min(data2plot(:)));
    strmax = num2str(max(data2plot(:)));
    if get(gui.handles.pm_pixData_GUI, 'Value') > 1
        zVal = max(data2plot(:));
    else
        zVal = 0;
    end
    
    %((round(abs(x_value)/gui.config.XStep)+1)*gui.config.interpFactVal)-(gui.config.interpFactVal-1)
    text(...
        (((rowMax+(gui.config.interpFactVal-1))/...
        gui.config.interpFactVal)-1)*gui.config.XStep, ...
        (((colMax+(gui.config.interpFactVal-1))/...
        gui.config.interpFactVal)-1)*gui.config.YStep, ...
        zVal, strmax, 'Color','Black','FontSize',FontSizeVal);
    if gui.config.flagZplot
        text(...
            (((rowMin+(gui.config.interpFactVal-1))/...
            gui.config.interpFactVal)-1)*gui.config.XStep, ...
            -(((colMin+(gui.config.interpFactVal-1))/...
            gui.config.interpFactVal)-1)*gui.config.YStep, ...
            zVal, strmin, 'Color','Black','FontSize',FontSizeVal);
    else
        text(...
            (((rowMin+(gui.config.interpFactVal-1))/...
            gui.config.interpFactVal)-1)*gui.config.XStep, ...
            (((colMin+(gui.config.interpFactVal-1))/...
            gui.config.interpFactVal)-1)*gui.config.YStep, ...
            zVal, strmin, 'Color','Black','FontSize',FontSizeVal);
    end
end

% Set and plot z positions of markers
xData_markers = gui.data.xData_markers;
yData_markers = gui.data.yData_markers;
markersVal = ones(size(xData_markers,1),size(xData_markers,2));
hold on;

if gui.config.Markers
    plot3(xData_markers', yData_markers', markersVal','k+');
    hold on;
end

if rawData == 8
    set(gcf, 'Renderer', 'opengl'); % For alpha transparency
else
    set(gcf, 'renderer', 'zbuffer'); % For plot of title and colorbar... otherwise plot bug
end

guidata(gcf, gui);
end