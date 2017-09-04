%% Copyright 2014 MERCIER David
function TriDiMap_diff_plotting
%% Function to plot the difference between property map and microscopic image
gui = guidata(gcf);

cMap = gui.config.colorMap;

% Display % of error - If 0, then perfect match and if 1 perfect mismatch.

%gui.results.diffYM = (rot90(YM_binarized) == flipud(gui.data.picture_scaled));
gui.results.diffYM = rot90(int8(gui.data.data2plot)) - ...
    flipud(int8(gui.image.image2plot));
gui.results.diffYM(gui.results.diffYM~=0)=1;
diff_error = sum(sum(gui.results.diffYM))/...
    (gui.config.N_XStep_default * gui.config.N_YStep_default);
display(diff_error);
set(gui.handles.value_diffVal_GUI, 'String', num2str((1-diff_error)*100));

hFig = imagesc(flipud(gui.results.diffYM), ...
    'XData',gui.data.xData_interp,'YData',gui.data.yData_interp);

axisMap(cMap, 'Difference map', gui.config.FontSizeVal, ...
    (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
    (gui.config.N_YStep_default-1)*gui.config.YStep_default, ...
    gui.config.flipColor);
axis equal;
axis tight;

%legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);

%% Difference between YM map and H map
% gui.results.diff_EH = rot90(int8(YM_binarized)) - rot90(int8(H_binarized));
% gui.results.diff_EH(gui.results.diff_EH~=0)=1;
% diff_EH_error = sum(sum(gui.results.diff_EH))/(gui.config.N_XStep_default * gui.config.N_YStep_default);
% display(diff_EH_error);
% f(9) = figure('position', [WX, WY, WW, WH]);
% hi(9) = imagesc(flipud(gui.results.diff_EH), 'XData',xData_interp,'YData',yData_interp);
% hold on;
% axisMap(gray, 'Elastic modulus-Hardness difference map', gui.config.FontSizeVal, ...
%     (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
%     (gui.config.N_YStep_default-1)*gui.config.YStep_default);
% legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);
% hold off;

%% Difference between microstructure map and YM map (only black pixels)
% for ii = 1:size(YM_binarized,1)
%     for jj = 1:size(YM_binarized,2)
%         if rot90(int8(YM_binarized(ii,jj))) == 127 && flipud(int8(gui.data.picture_scaled(ii,jj))) == 127
%             gui.results.diffYM2(ii,jj) = 0;
%         else
%             gui.results.diffYM2(ii,jj) = 1;
%         end
%     end
% end
% diff_YM_error2 = sum(sum(abs(gui.results.diffYM2-1)))/(sum(sum(gui.data.picture_scaled/255)));
% display(diff_YM_error2);

end

