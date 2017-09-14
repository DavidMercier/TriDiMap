%% Copyright 2014 MERCIER David
function diff_error = TriDiMap_diff_plotting(property, plotMatch, varargin)
%% Function to plot the difference between property map and microscopic image
if nargin < 2
    plotMatch = 0;
end

gui = guidata(gcf);

cMap = gui.config.colorMap;

% Display % of error - If 1, then perfect match and if 0 perfect mismatch.

if property == 1
    data2plot = gui.data.data2plot_E;
elseif property == 2
    data2plot = gui.data.data2plot_H;
elseif property == 3
    data2plot_E = gui.data.data2plot_E;
    data2plot_H = gui.data.data2plot_H;
end

if property < 3
    %% Difference between property map and image
    image2plot = gui.image.image2plot;
    if size(data2plot) == size(image2plot)
        gui.config.sizeCheck = 1;
    else
        gui.config.sizeCheck = 0;
    end
    
    if gui.config.sizeCheck
        if get(gui.handles.pixelList_GUI, 'Value') == 1
            %gui.results.diff = (rot90(data2plot) == flipud(image2plot));
            gui.results.diff = rot90(int8(data2plot)) - ...
                (int8(image2plot));
            gui.results.diff(gui.results.diff~=0) = 1;
            diff_error = (1-(sum(sum(abs(gui.results.diff)))/ ...
                (gui.config.N_XStep_default * gui.config.N_YStep_default)))*100;
        elseif get(gui.handles.pixelList_GUI, 'Value') == 2
            d2plot = rot90(data2plot);
            for ii = 1:size(data2plot,1)
                for jj = 1:size(data2plot,2)
                    if (int8(d2plot(ii,jj))) > 0 && ...
                            (int8(image2plot(ii,jj))) > 0
                        gui.results.diff(ii,jj) = 0;
                    else
                        gui.results.diff(ii,jj) = 1;
                    end
                end
            end
            diff_error = (((gui.config.N_XStep_default * gui.config.N_YStep_default) - ...
                sum(sum(abs(gui.results.diff)))) / sum(sum(data2plot/255)))*100;
        elseif get(gui.handles.pixelList_GUI, 'Value') == 3
            d2plot = rot90(data2plot);
            for ii = 1:size(data2plot,1)
                for jj = 1:size(data2plot,2)
                    if (int8(d2plot(ii,jj))) == 0 && ...
                            (int8(image2plot(ii,jj))) == 0
                        gui.results.diff(ii,jj) = 0;
                    else
                        gui.results.diff(ii,jj) = 1;
                    end
                end
            end
            diff_error = (1-((sum(sum(abs(gui.results.diff))))/...
                (gui.config.N_XStep_default * gui.config.N_YStep_default)))*100;
        end
        
        if ~plotMatch
            display(diff_error);
            if property == 1
                set(gui.handles.value_diffValE_GUI, 'String', ...
                    num2str(round(diff_error*10)/10));
                strTitle = 'E-Image difference map';
            elseif property == 2
                set(gui.handles.value_diffValH_GUI, 'String', ...
                    num2str(round(diff_error*10)/10));
                strTitle = 'H-Image difference map';
            end
            
            hFig = imagesc(flipud(gui.results.diff), ...
                'XData',gui.data.xData_interp,'YData',gui.data.yData_interp);
            
            axisMap(cMap, strTitle, gui.config.FontSizeVal, ...
                (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
                (gui.config.N_YStep_default-1)*gui.config.YStep_default, ...
                gui.config.flipColor);
            axis equal;
            axis tight;
        end
    else
        errordlg('Not the same size between property maps and microstructural image !');
    end
    %% Difference between E map and H map
else
    if get(gui.handles.pixelList_GUI, 'Value') == 1
        gui.results.diff_EH = rot90(int8(data2plot_E)) - ...
            rot90(int8(data2plot_H));
        gui.results.diff_EH(gui.results.diff_EH~=0)=1;
        diff_error = (1-(sum(sum(gui.results.diff_EH)) / ...
            (gui.config.N_XStep_default * gui.config.N_YStep_default)))*100;
    elseif get(gui.handles.pixelList_GUI, 'Value') == 2
        d2plot_E = rot90(data2plot_E);
        d2plot_H = rot90(data2plot_H);
        for ii = 1:size(data2plot_E,1)
            for jj = 1:size(data2plot_E,2)
                if (int8(d2plot_E(ii,jj))) > 0 && ...
                        (int8(d2plot_H(ii,jj))) > 0
                    gui.results.diff_EH(ii,jj) = 0;
                else
                    gui.results.diff_EH(ii,jj) = 1;
                end
            end
        end
        diff_error = (((gui.config.N_XStep_default * gui.config.N_YStep_default) - ...
            sum(sum(abs(gui.results.diff_EH)))) / sum(sum(data2plot_E/255)))*100;
    elseif get(gui.handles.pixelList_GUI, 'Value') == 3
        d2plot_E = rot90(data2plot_E);
        d2plot_H = rot90(data2plot_H);
        for ii = 1:size(data2plot_E,1)
            for jj = 1:size(data2plot_E,2)
                if (int8(d2plot_E(ii,jj))) == 0 && ...
                        (int8(d2plot_H(ii,jj))) == 0
                    gui.results.diff_EH(ii,jj) = 0;
                else
                    gui.results.diff_EH(ii,jj) = 1;
                end
            end
        end
        diff_error = (1-((sum(sum(abs(gui.results.diff_EH))))/...
            (gui.config.N_XStep_default * gui.config.N_YStep_default)))*100;
    end
    if ~plotMatch
        display(diff_error);
        set(gui.handles.value_diffValEH_GUI, 'String', ...
            num2str(round(diff_error*10)/10));
        
        hFig(1) = imagesc(flipud(gui.results.diff_EH), ...
            'XData',gui.data.xData_interp, 'YData',gui.data.yData_interp);
        
        axisMap(cMap, 'E-H difference map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default, ...
            gui.config.flipColor);
        hold on;
        if get(gui.handles.cb_legend_GUI, 'Value')
            cmap = colormap;
            hFig(2) = plot(NaN,NaN,'sk','MarkerFaceColor',min(cmap));
            hFig(3) = plot(NaN,NaN,'sk','MarkerFaceColor',max(cmap));
            gui.handles.hLeg2 = legend([hFig(2) hFig(3)],'No Match','Match', ...
                'Location','EastOutside');
            pos = get(gui.handles.hLeg2,'position');
            set(gui.handles.hLeg2, 'position',[0.87 0.25 pos(3:4)]);
            legend boxoff ;
        else
            legend('hide');
        end
    end
end
guidata(gcf, gui);
end