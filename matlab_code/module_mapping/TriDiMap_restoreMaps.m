function TriDiMap_restoreMaps
gui = guidata(gcf);
if ~strcmp(get(gui.handles.binarization_GUI, 'String'), 'BINARIZATION')
    errordlg('Return to the mapping window to restore imported values.', 'Contact model');
    return
end
if ~isfield(gui.data, 'originalProperties')
    errordlg('There are no recalculated values to restore.', 'Contact model');
    return
end
gui.data.expValues = gui.data.originalProperties.expValues;
gui.data.expValues_mat = gui.data.originalProperties.expValues_mat;
set(gui.handles.unitProp_GUI, 'Value', gui.data.originalProperties.unit, 'Enable', 'on');
gui.data = rmfield(gui.data, 'originalProperties');
gui.config.flag_ClusterGauss = 0;
gui.config.flag_fit = 0;
if isfield(gui, 'resultsPDF')
    gui = rmfield(gui, 'resultsPDF');
end
if isfield(gui, 'resultsCDF')
    gui = rmfield(gui, 'resultsCDF');
end
set(gui.handles.cb_CdfFromPdf_GUI, 'Value', 0);
set(gui.handles.cb_plotErrorPDF_GUI, 'Value', 0);
set(gui.handles.value_MinVal_GUI, 'String', '');
set(gui.handles.value_MaxVal_GUI, 'String', '');
set(gui.handles.pm_autoColorbar_GUI, 'Value', 1);
guidata(gui.handles.MainWindow, gui);
TriDiMap_runPlot;
end
