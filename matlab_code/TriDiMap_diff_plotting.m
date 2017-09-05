%% Copyright 2014 MERCIER David
function diff_error = TriDiMap_diff_plotting(property, plotMatch, varargin)
%% Function to plot the difference between property map and microscopic image
if nargin < 2
    plotMatch = 0;
end

gui = guidata(gcf);

cMap = gui.config.colorMap;

% Display % of error - If 0, then perfect match and if 1 perfect mismatch.

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
    %gui.results.diff = (rot90(YM_binarized) == flipud(gui.data.picture_scaled));
    gui.results.diff = rot90(int8(data2plot)) - ...
        flipud(int8(gui.image.image2plot));
    gui.results.diff(gui.results.diff~=0)=1;
    diff_error = sum(sum(gui.results.diff))/...
        (gui.config.N_XStep_default * gui.config.N_YStep_default);
    if ~plotMatch
        display(diff_error);
        if property == 1
            set(gui.handles.value_diffValE_GUI, 'String', num2str((1-diff_error)*100));
            strTitle = 'E-Image difference map';
        elseif property == 2
            set(gui.handles.value_diffValH_GUI, 'String', num2str((1-diff_error)*100));
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
        
        %legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);
    end
else
    %% Difference between E map and H map
    gui.results.diff_EH = rot90(int8(data2plot_E)) - rot90(int8(data2plot_H));
    gui.results.diff_EH(gui.results.diff_EH~=0)=1;
    diff_error = sum(sum(gui.results.diff_EH))/(gui.config.N_XStep_default * gui.config.N_YStep_default);
    if ~plotMatch
        display(diff_error);
        set(gui.handles.value_diffValEH_GUI, 'String', num2str((1-diff_error)*100));
        
        hFig = imagesc(flipud(gui.results.diff_EH), ...
            'XData',gui.data.xData_interp, 'YData',gui.data.yData_interp);
        
        axisMap(cMap, 'E-H difference map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default, ...
            gui.config.flipColor);
        
        % legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);
    end
end
%% Difference between microstructure map and YM map (only black pixels)
% for ii = 1:size(YM_binarized,1)
%     for jj = 1:size(YM_binarized,2)
%         if rot90(int8(YM_binarized(ii,jj))) == 127 && flipud(int8(gui.data.picture_scaled(ii,jj))) == 127
%             gui.results.diff2(ii,jj) = 0;
%         else
%             gui.results.diff2(ii,jj) = 1;
%         end
%     end
% end
% diff_YM_error2 = sum(sum(abs(gui.results.diff2-1)))/(sum(sum(gui.data.picture_scaled/255)));
% display(diff_YM_error2);

end