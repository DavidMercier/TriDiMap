%% Copyright 2014 MERCIER David
function plot_get_values
%% Function used to get values
TriDiMap_getParam;
gui = guidata(gcf);

if gui.config.flag_data == 0
    helpdlg('Import data first !', '!!!');
    
else
    [x_value, y_value] = ginput(1);
    
    set(gui.handles.value_x_values_GUI, 'String', ...
        num2str(abs(x_value)));
    %num2str((round((x_value*1000)/10))/100))
    
    set(gui.handles.value_y_values_GUI, 'String', ...
        num2str(abs(y_value)));
    %num2str((round((y_value*1000)/10))/100))
    
    try
        set(gui.handles.value_z_values_GUI, 'String', ...
            num2str(gui.data.data2plot(...
            ((round(abs(x_value)/gui.config.XStep)+1)*gui.config.interpFactVal)-(gui.config.interpFactVal-1), ...
            ((round(abs(y_value)/gui.config.YStep)+1)*gui.config.interpFactVal)-(gui.config.interpFactVal-1))));
    catch
        disp('No Z values!');
    end
end

end