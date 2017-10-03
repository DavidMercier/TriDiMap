%% Copyright 2014 MERCIER David
function axisMap(cmap, titleStr, FontSizeVal, xMax, yMax, flipFlag, unitStr, ...
    varargin)
%% Function to set axis for a binary map.

if nargin < 7
    unitStr = '$\mu$m';
end

if nargin < 6
    flipFlag = 0;
end

if nargin < 5
    yMax = 1;
end

if nargin < 4
    xMax = 1;
end

if nargin < 3
    FontSizeVal = 14;
end

if nargin < 2
    titleStr = 'Map';
end

if nargin < 1
    cmap = gray;
end

if ~isempty(cmap)
    colormap(cmap);
    if flipFlag
        colormap(flipud(colormap(cmap)));
    end
end
set(gca,'YDir','normal');
axis equal;
axis tight;
if strcmp(unitStr, 'µm')
    unitStr = '$\mu$m';
end
hXLabel = xlabel(strcat('X coordinates (', unitStr, ')'));
hYLabel = ylabel(strcat('Y coordinates (', unitStr, ')'));
hTitle = title(titleStr);
set([hXLabel, hYLabel, hTitle], ...
    'Color', [0,0,0], 'FontSize', FontSizeVal, ...
    'Interpreter', 'Latex');
% xlim([0 xMax]);
% ylim([0 yMax]);
set(gca, 'Fontsize', FontSizeVal);
%set(gca,'visible','off');
end