%% Copyright 2014 MERCIER David
function TriDiMap_mapping_plotting
%% Function to plot a 3D map of material properties in function of X/Y coordinates
gui = guidata(gcf);

FontSizeVal = gui.config.FontSizeVal;
xData_interp = gui.data.xData_interp;
yData_interp = gui.data.yData_interp;
data2plot = gui.data.data2plot;
cMap = gui.config.colorMap;
flagPlot = 0;

if strcmp(get(gui.handles.binarization_GUI, 'String'), 'BINARIZATION')
    zString = gui.config.legend;
    cmin = gui.config.cmin;
    cmax = gui.config.cmax;
    intervalScaleBar = gui.config.intervalScaleBar;
    rawData = gui.config.rawData;
    contourPlot = gui.config.contourPlot;
    logZ = gui.config.logZ;
    
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
    
    if size(data2plot,1) == 1 || size(data2plot,2) == 1
        flagSize = 0;
    else
        flagSize = 1;
    end
    
    if rawData == 1
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
        flagPlot = 1;
    elseif rawData == 2 && flagSize
        if contourPlot < 2
            hFig = surf(xData_interp, yData_interp, data2plot',...
                'FaceColor','interp',...
                'EdgeColor','none',...
                'FaceLighting','gouraud');
            if gui.config.shadingData == 1
                shading flat;
            elseif gui.config.shadingData == 2
                shading interp;
            elseif gui.config.shadingData == 3
                shading faceted;
            end
        elseif contourPlot == 2
            if ~get(gui.handles.cb_textContourPlotMap_GUI, 'Value')
                if logZ
                    contour(xData_interp, yData_interp, log(data2plot'),...
                        intervalScaleBar);
                else
                    contour(xData_interp, yData_interp, data2plot',...
                        intervalScaleBar);
                end
            elseif get(gui.handles.cb_textContourPlotMap_GUI, 'Value')
                if logZ
                    contour(xData_interp, yData_interp, log(data2plot'),...
                        intervalScaleBar,'ShowText','on');
                else
                    contour(xData_interp, yData_interp, data2plot',...
                        intervalScaleBar,'ShowText','on');
                end
            end
        elseif contourPlot == 3
            if ~get(gui.handles.cb_textContourPlotMap_GUI, 'Value')
                if logZ
                    contourf(xData_interp, yData_interp, log(data2plot'),...
                        intervalScaleBar);
                else
                    contourf(xData_interp, yData_interp, data2plot',...
                        intervalScaleBar);
                end
            elseif get(gui.handles.cb_textContourPlotMap_GUI, 'Value')
                if logZ
                    contourf(xData_interp, yData_interp, log(data2plot'),...
                        intervalScaleBar,'ShowText','on');
                else
                    contourf(xData_interp, yData_interp, data2plot',...
                        intervalScaleBar,'ShowText','on');
                end
            end
        end
        flagPlot = 1;
    elseif rawData == 3 && flagSize
        hFig = surfc(xData_interp, yData_interp, data2plot');
        flagPlot = 1;
    elseif rawData == 4 && flagSize
        hFig = waterfall(xData_interp, yData_interp, data2plot');
        flagPlot = 1;
    elseif rawData == 5 && flagSize
        hFig = contour3(xData_interp, yData_interp, data2plot', ...
            intervalScaleBar);
        flagPlot = 1;
    elseif rawData == 6 && flagSize
        hFig = meshz(xData_interp, yData_interp, data2plot');
        if gui.config.meshHidden == 1
            hidden on;
        else
            hidden off;
        end
        flagPlot = 1;
    elseif rawData == 7
        hFig = bar3(data2plot');
        stringSurf = get_value_popupmenu(gui.handles.pm_surfShading_GUI, listSurf);
        [Match, noMatch] = regexp(gui.config.MatlabRelease,'20..','match','split');
        if str2num(char(cellstr(Match))) > 2014 || ...
                (str2num(char(cellstr(Match))) == 2014 && strcmp(char(noMatch(2)),'b)'))
            for ii = 1:length(hFig)
                zdata = hFig(ii).ZData;
                hFig(ii).CData = zdata;
                hFig(ii).FaceColor = stringSurf;
            end
        else
            for ii = 1:length(hFig)
                zdata = get(hFig(ii),'Zdata');
                set(hFig(ii),'Cdata',zdata,'FaceColor',char(stringSurf));
            end
            
        end
        flagPlot = 1;
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
        hTitle(1) = title(strcat({'Mapping of '}, zString));
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
        ylabel(hcb1, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
        
        gui.handle.hcb1 = hcb1;
        set(gca, 'Fontsize', FontSizeVal);
        hold off;
    else
        errordlg('Wrong map size for 3D plot!');
    end
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
        gui.config.flipColor, gui.config.strUnit_Length);
    axis equal;
    axis tight;
end

guidata(gcf, gui);

end