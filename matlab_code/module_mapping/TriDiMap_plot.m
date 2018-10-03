%% Copyright 2014 MERCIER David
function TriDiMap_plot
%% Function to plot a 3D map of material properties in function of X/Y coordinates
gui = guidata(gcf);

rawData = gui.config.rawData;
if rawData < 8
    xData_interp = gui.data.xData_interp;
    yData_interp = gui.data.yData_interp;
    data2plot = gui.data.data2plot;
    if strcmp(get(gui.handles.binarization_GUI, 'String'), 'BINARIZATION')
        if get(gui.handles.cb_plotSectMap_GUI, 'Value')
            data2plot = gui.data.dataH_Sector;
        end
    end
else
    xData_interp = gui.slice_data_mat.xData_interp;
    yData_interp = gui.slice_data_mat.yData_interp;
    zData_interp = gui.slice_data_mat.zData_interp;
    data2plot = fliplr(rot90(gui.slice_data_mat.InterSmoothed));
end

cMap = gui.config.colorMap;
flagPlot = 0;

if strcmp(get(gui.handles.binarization_GUI, 'String'), 'BINARIZATION')
    cmin = gui.config.cmin;
    cmax = gui.config.cmax;
    intervalScaleBar = gui.config.intervalScaleBar;
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
            %hFig = pcolor(xData_interp, xData_interp, (data2plot'));
        end
        set(gca,'YDir','normal');
        % Following line to not plot NaN but doesn't work...
        %set(hFig,'AlphaData',~isnan(data2plot'));
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
                    hFig = contour(xData_interp, yData_interp, log(data2plot'),...
                        intervalScaleBar);
                else
                    hFig = contour(xData_interp, yData_interp, data2plot',...
                        intervalScaleBar);
                end
            elseif get(gui.handles.cb_textContourPlotMap_GUI, 'Value')
                if logZ
                    hFig = contour(xData_interp, yData_interp, log(data2plot'),...
                        intervalScaleBar,'ShowText','on');
                else
                    hFig = contour(xData_interp, yData_interp, data2plot',...
                        intervalScaleBar,'ShowText','on');
                end
            end
        elseif contourPlot == 3
            if ~get(gui.handles.cb_textContourPlotMap_GUI, 'Value')
                if logZ
                    hFig = contourf(xData_interp, yData_interp, log(data2plot'),...
                        intervalScaleBar);
                else
                    hFig = contourf(xData_interp, yData_interp, data2plot',...
                        intervalScaleBar);
                end
            elseif get(gui.handles.cb_textContourPlotMap_GUI, 'Value')
                if logZ
                    hFig = contourf(xData_interp, yData_interp, log(data2plot'),...
                        intervalScaleBar,'ShowText','on');
                else
                    hFig = contourf(xData_interp, yData_interp, data2plot',...
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
        hFig = bar3(yData_interp(:,1)',data2plot');
        XdataVal = get(hFig,'XData');
        YdataVal = get(hFig,'YData');
        axis tight;
        for ii = 1:length(XdataVal)
            XdataVal{ii} = ...
                XdataVal{ii}+(min(xData_interp(1,:))-1)*ones(size(XdataVal{ii}));
            if gui.config.interpFactVal == 1
                set(hFig(ii),'XData',XdataVal{ii}*gui.config.XStep);
            else
                set(hFig(ii),'XData',XdataVal{ii}/(2^(gui.config.interpFact-1)));
            end
        end
        set(gca,'XDir','normal');
        set(gca,'YDir','normal');
        stringSurf = 'Flat';   
        [Match, noMatch] = regexp(gui.config.MatlabRelease,'20..','match','split');
        if str2num(char(cellstr(Match))) > 2014 || ...
                (str2num(char(cellstr(Match))) == 2014 && strcmp(char(noMatch(2)),'b)'))
            for ii = 1:length(hFig)
                zdata = hFig(ii).ZData;
                hFig(ii).CData = zdata;
                hFig(ii).FaceColor = 'Flat'%char(stringSurf);
            end
        else
            for ii = 1:length(hFig)
                zdata = get(hFig(ii),'Zdata');
                try
                    set(hFig(ii),'Cdata',zdata,'FaceColor',char(stringSurf));
                catch
                end
            end
            
        end
        flagPlot = 1;
    elseif rawData == 8
        %xslice = max(max(xData_interp(:,:,1)));
        xslice = NaN;
        %yslice = max(max(yData_interp(:,:,1)));
        yslice = NaN;
        minZ = min(zData_interp(1,1,:));
        maxZ = max(zData_interp(1,1,:));
        stepZ = (maxZ-minZ)/(gui.config.sliceNum-1);
        zslice = zeros(gui.config.sliceNum,1);
        zslice(1) = minZ;
        for ii = 2:(gui.config.sliceNum-1)
            zslice(ii) = minZ + stepZ*(ii-1);
        end
        zslice(gui.config.sliceNum) = maxZ;
        if gui.config.gifFlag
            jj = 1;
            handleFig = zeros(1,gui.config.sliceNum);
            for ii = gui.config.sliceNum:-1:1
                handleFig(jj) = figure;
                gui.config.FontSizeVal = 6;
                guidata(gcf,gui);
                kk = gui.config.sliceNum:-1:ii;
                hFig = slice(xData_interp,yData_interp,zData_interp,...
                    data2plot,xslice,yslice,zslice(kk));%'linear', 'cubic', 'nearest'
                set(hFig, 'EdgeColor','none', 'FaceColor','flat'); %interp
                alpha(gui.config.alpha);
                set(gca,'ZDir','reverse');
                hold on;
                %TriDiMap_plot_options(xData_interp, yData_interp, data2plot, 1);
                hcb = colorbar;
                pos = get(hcb, 'Position');
                set(hcb, 'Position', [pos(1) pos(2) pos(3)*0.5 pos(4)*0.9]);
                ha = gca;
                pos = get(ha, 'Position');
                set(ha, 'Position', [pos(1) pos(2) pos(3)*0.9 pos(4)]);
                %pause(0.1);
                hold on;
                %                delete(findall(findall(gcf,'Type','axe'),'Type','text'));
                %               axis off; box off;
                %                 set(gca,'units','normalized','position',[0 0 1 1]);
                pathnameFig = gui.slice_data_xls.pathname_data;
                filenameFig = gui.slice_data_xls.filename_data;
                if ii < 10
                    str_ii = ['0',num2str(ii)];
                else
                    str_ii = num2str(ii);
                end
                grid off;
                titleFig = fullfile(pathnameFig, [filenameFig ,'_',str_ii]);
                export_fig(titleFig, isolate_axes(gca));
                close(handleFig(jj));
                jj = jj+1;
            end
        else
            try
                hFig = slice(xData_interp,yData_interp,zData_interp,...
                    data2plot,xslice,yslice,zslice);%'linear', 'cubic', 'nearest'
                set(hFig, 'EdgeColor','none', 'FaceColor','flat'); %interp
                alpha(gui.config.alpha);
                set(gca,'ZDir','reverse');
                hold on;
            catch
                errordlg('Wrong inputs! No CSM mode, but only 1 value at maximum load...');
            end
        end
        gui.config.gifFlag = 0;
        guidata(gcf, gui);
        flagPlot = 1;
    end
    TriDiMap_plot_options(xData_interp, yData_interp, data2plot, flagPlot);
    hold on;
    
else
    [token, remain] = strtok(gui.config.colorMap);
    if strcmp(token,'DivergingMap') == 1
        [RGB1, RGB2] = listDivCmap(str2num(remain));
        cmap = diverging_map(0:(1/(10-1)):1,RGB1,RGB2);
    else
        cMap = gui.config.colorMap;
    end
    
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
    
    guidata(gcf, gui);
    
end
end