%% Copyright 2014 MERCIER David
function [dataCropped, flagCrop] = TriDiMap_cropping(data)
%% Function to crop the map
gui = guidata(gcf);
config = gui.config;
handles = gui.handles;
flagCrop = 1;

xMin = round(abs(config.MinXCrop));
xMax = round(abs(config.MaxXCrop));
yMin = round(abs(config.MinYCrop));
yMax = round(abs(config.MaxYCrop));

set(handles.value_MinXCrop_GUI, 'String', num2str(xMin));
set(handles.value_MaxXCrop_GUI, 'String', num2str(xMax));
set(handles.value_MinYCrop_GUI, 'String', num2str(yMin));
set(handles.value_MaxYCrop_GUI, 'String', num2str(yMax));

if xMin <= 0 || xMax <= 0 || yMin < 0 || yMax < 0
    errordlg('Minimum number of indents along X has to be positive !');
    flagCrop = 0;
end
if xMax < 0
    errordlg('Maximum number of indents along X has to be positive !');
    flagCrop = 0;
end
if yMin < 0
    errordlg('Minimum number of indents along Y has to be positive !');
    flagCrop = 0;
end
if yMax < 0
    errordlg('Maximum number of indents along Y has to be positive !');
    flagCrop = 0;
end
if xMax > config.N_XStep
    errordlg('Maximum number of indents along X is higher than in the indentation grid !');
    flagCrop = 0;
end
if yMax > config.N_YStep
    errordlg('Maximum number of indents along Y is higher than in the indentation grid !');
    flagCrop = 0;
end
if xMin > xMax
    errordlg('Maximum number of indents along X is less than minimum number of indents along X !');
    flagCrop = 0;
end
if yMin > yMax    
    errordlg('Maximum number of indents along Y is less than minimum number of indents along Y !');
    flagCrop = 0;
end

if flagCrop
    dataCropped = data(xMin:xMax, yMin:yMax);
else
    dataCropped = 0;
end

end