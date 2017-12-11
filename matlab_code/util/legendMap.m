%% Copyright 2014 MERCIER David
function hLeg = legendMap(numPh, cMap, loc, legendStr, ...
    FontSizeVal, flagFlipCM, posLeg, varargin)
%% Function to set legend for an image or a map.
if nargin < 6
    flagFlipCM = 0;
end

if nargin < 5
    FontSizeVal = 14;
end

if nargin < 4
    legendStr = {'Phase1' , 'Phase2'};
end

if nargin < 3
    loc = 'EastOutside';
end

if nargin < 2
    cMap = 'default';
end

if nargin < 1
    numPh = 2;
end

cmap = colormap;
if flagFlipCM
    cmap = flipud(cmap);
end
[token, remain] = strtok(cMap);
szCM = size(colormap,1)/2;
if flagFlipCM
    hFig(2) = plot(NaN,NaN,'sk','MarkerFaceColor',cmap(end,:));
    if numPh == 3
        hFig(3) = plot(NaN,NaN,'sk','MarkerFaceColor',cmap(szCM,:));
    end
    hFig(4) = plot(NaN,NaN,'sk','MarkerFaceColor',cmap(1,:));
else
    hFig(2) = plot(NaN,NaN,'sk','MarkerFaceColor',cmap(1,:));
    if numPh == 3
        hFig(3) = plot(NaN,NaN,'sk','MarkerFaceColor',cmap(szCM,:));
    end
    hFig(4) = plot(NaN,NaN,'sk','MarkerFaceColor',cmap(end,:));
end

if numPh == 2
    hLeg = legend([hFig(2) hFig(4)],...
        legendStr, 'Location',loc);
elseif numPh == 3
    hLeg = legend([hFig(2) hFig(3) hFig(4)],...
        legendStr, 'Location', loc);
end
pos = get(hLeg,'position');
if ~isempty(posLeg)
    set(hLeg, 'position',[posLeg pos(3:4)]);
end
set(hLeg, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
legend boxoff;

end