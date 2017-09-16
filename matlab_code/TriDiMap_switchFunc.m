%% Copyright 2014 MERCIER David
function TriDiMap_switchFunc
%% Function to swith the button on the GUI between mapping and binarization

gui = guidata(gcf);
strButton = get(gui.handles.binarization_GUI, 'String');

clf;

if strcmp(strButton, 'BINARIZATION')
    TriDiMap_setGUI(2);
elseif strcmp(strButton, 'MAPPING')
    TriDiMap_setGUI(1);
end

end