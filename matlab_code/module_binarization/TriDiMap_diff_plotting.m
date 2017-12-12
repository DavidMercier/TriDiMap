%% Copyright 2014 MERCIER David
function diff_error = TriDiMap_diff_plotting(property, plotMatch, varargin)
%% Function to plot the difference between property map and microscopic image
if nargin < 2
    plotMatch = 0;
end

gui = guidata(gcf);

cMap = gui.config.colorMap;
flagFlipCM = get(gui.handles.cb_flipColormap_GUI, 'Value');

% Display % of error - If 1, then perfect match and if 0 perfect mismatch.

if property == 1
    data2plot = rot90(gui.data.data2plot_E);
    dataE = rot90(gui.data.expValues_mat.YM);
elseif property == 2
    data2plot = rot90(gui.data.data2plot_H);
    dataH = rot90(gui.data.expValues_mat.H);
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
            %gui.results.diff = int8(data2plot) - (int8(image2plot));
            gui.results.diff = (double(data2plot) + (double(image2plot)))/255;
            gui.results.diff(gui.results.diff==1) = -1; %No Match
            gui.results.diff(gui.results.diff==2) = 1; %SiC
            gui.results.diff(gui.results.diff==0) = 0; % Ni
            %gui.results.diff(gui.results.diff~=0) = 1;
            diff_error = (1-(sum(sum(abs(gui.results.diff)))/ ...
                (gui.config.N_XStep_default * gui.config.N_YStep_default)))*100;
            data2plot_soft = (data2plot==0);
            image2plot_soft = (image2plot==0);
            gui.results.matchSoft = ((data2plot_soft + image2plot_soft)==2);
            data2plot_hard = (data2plot==255);
            image2plot_hard = (image2plot==255);
            gui.results.matchHard = ((data2plot_hard + image2plot_hard)==2);
            if property == 1
                gui.results.diffE = gui.results.diff;
                display(nanmean(dataE(gui.results.matchSoft==1)));
                display(nanstd(dataE(gui.results.matchSoft==1)));
                display(nanmean(dataE(gui.results.matchHard==1)));
                display(nanstd(dataE(gui.results.matchHard==1)));
            elseif property == 2
                gui.results.diffH = gui.results.diff;
                display(nanmean(dataH(gui.results.matchSoft==1)));
                display(nanstd(dataH(gui.results.matchSoft==1)));
                display(nanmean(dataH(gui.results.matchHard==1)));
                display(nanstd(dataH(gui.results.matchHard==1)));
            end
            % Pixels ratios
            SiCSum = sum(sum(gui.results.diff==1));
            NiSum = sum(sum(gui.results.diff==0));
            TotSum = NiSum + SiCSum;
            display([SiCSum NiSum]);
            display(SiCSum/TotSum);
            display(NiSum/TotSum);
        elseif get(gui.handles.pixelList_GUI, 'Value') == 2
            for ii = 1:size(data2plot,1)
                for jj = 1:size(data2plot,2)
                    if (int8(data2plot(ii,jj))) > 0 && ...
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
            for ii = 1:size(data2plot,1)
                for jj = 1:size(data2plot,2)
                    if (int8(data2plot(ii,jj))) == 0 && ...
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
            
            hAxis = imagesc(flipud(gui.results.diff), ...
                'XData',gui.data.xData_interp,'YData',gui.data.yData_interp);
            
            axisMap(cMap, strTitle, gui.config.FontSizeVal, ...
                (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
                (gui.config.N_YStep_default-1)*gui.config.YStep_default, ...
                gui.config.flipColor, gui.config.strUnit_Length);
            axis equal;
            axis tight;
            hold on;
            
            if property == 1
                % Legend for E-micro and H-micro maps
                
                if get(gui.handles.cb_legend_GUI, 'Value')
                    gui.handles.hLeg2 = legendMap(3, cMap, 'EastOutside', ...
                        {'No Match','Soft match', 'Stiff/Hard match'}, 12, ...
                        flagFlipCM, [0.87 0.30]);
                    gui.handles.hTit2 = uicontrol('Parent', gcf,...
                        'Style','text',...
                        'Units', 'normalized',...
                        'String','(E or H) map - µ map legend',...
                        'HorizontalAlignment', 'center',...
                        'FontWeight', 'bold',...
                        'Position',[0.86 0.40 0.12 0.02],...
                        'Visible', 'on');
                else
                    set(gui.handles.hTit2, 'Visible', 'off');
                    try
                        delete(gui.handles.hLeg2);
                    catch
                    end
                end
            end
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
        for ii = 1:size(d2plot_E,1)
            for jj = 1:size(d2plot_H,2)
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
        for ii = 1:size(d2plot_E,1)
            for jj = 1:size(d2plot_H,2)
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
        
        hAxis = imagesc(flipud(gui.results.diff_EH), ...
            'XData',gui.data.xData_interp, 'YData',gui.data.yData_interp);
        
        axisMap(cMap, 'E-H difference map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default, ...
            gui.config.flipColor, gui.config.strUnit_Length);
        hold on;
        
        
        if get(gui.handles.cb_legend_GUI, 'Value')
            gui.handles.hLeg3 = legendMap(2, cMap, 'EastOutside', ...
                {'No Match','Match'}, 12, flagFlipCM, [0.87 0.15]);
            gui.handles.hTit3 = uicontrol('Parent', gcf,...
                'Style','text',...
                'Units', 'normalized',...
                'String','E map - H map legend',...
                'HorizontalAlignment', 'center',...
                'FontWeight', 'bold',...
                'Position',[0.86 0.25 0.12 0.02], ...
                'Visible', 'on');
        else
            set(gui.handles.hTit3, 'Visible', 'off');
            try
                delete(gui.handles.hLeg3);
            catch
            end
        end
    end
end
guidata(gcf, gui);
end