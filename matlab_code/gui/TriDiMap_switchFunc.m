%% Copyright 2014 MERCIER David
function TriDiMap_switchFunc
%% Function to swith the button on the GUI between mapping and binarization

gui = guidata(gcf);
strButton = get(gui.handles.binarization_GUI, 'String');

if strcmp(strButton, 'MAPPING')
    TriDiMap_closeBinFigures(gui.handles.MainWindow);
    set(0, 'CurrentFigure', gui.handles.MainWindow);
end

clf;

if strcmp(strButton, 'BINARIZATION')
    TriDiMap_setGUI(2);
elseif strcmp(strButton, 'MAPPING')
    TriDiMap_setGUI(1);
end

end