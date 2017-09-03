%% Copyright 2014 MERCIER David
function coordSyst(handle)
%% Function to plot coordinate systems

set(0, 'currentfigure', handle);

xVal = 0.93;
yVal = 0.89;
arrowLength = 0.03;

xX = [xVal, xVal + arrowLength];
yX = [yVal, yVal];
handles.arrowX = annotation('arrow',xX,yX);
handles.textX = uicontrol('Parent', handle,...
    'Units', 'normalized',...
    'Style', 'text',...
    'Position', [xVal+arrowLength yVal-0.01 0.02 0.02],...
    'String', 'X');

xY = [xVal, xVal];
yY = [yVal, yVal + 2*arrowLength];
handles.arrowY = annotation('arrow',xY,yY);
handles.textY = uicontrol('Parent', handle,...
    'Units', 'normalized',...
    'Style', 'text',...
    'Position', [xVal-0.01 yVal+2*arrowLength 0.02 0.02],...
    'String', 'Y');

end