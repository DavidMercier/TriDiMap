%% Copyright 2014 MERCIER David
function legendBinaryMap(color1, color2, symbol1, symbol2, ...
    legendStr, FontSizeVal, varargin)
%% Function to set legend for a binary map.

if nargin < 6
    FontSizeVal = 14;
end

if nargin < 5
    legendStr = {'Phase1' , 'Phase2'};
end

if nargin < 4
    symbol2 = 's';
end

if nargin < 3
    symbol1 = 's';
end

if nargin < 2
    color2 = 'k';
end

if nargin < 1
    color1 = 'w';
end

hp(1) = plot(nan,nan,[color1, symbol1]);
hp(2) = plot(nan,nan,[color2, symbol2]);
set(hp(1),'MarkerEdgeColor',color1,'MarkerFaceColor',color1)
set(hp(2),'MarkerEdgeColor',color2,'MarkerFaceColor',color2)
hl = legend(hp, {char(legendStr(1));char(legendStr(2))});
set(hl, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
set(hl, 'Location', 'NorthEast'); %'NorthEastOutside'
set(hl, 'color', [0.83 0.83 0.83]);
ch = findobj(get(hl,'children'), 'type', 'text'); %// children of legend of type text
set(ch, 'Fontsize', 1.5*FontSizeVal); %// set value as desired
ch = findobj(get(hl,'children'), 'type', 'line'); %// children of legend of type line
set(ch, 'Markersize', 1.2*FontSizeVal); %// set value as desired

end