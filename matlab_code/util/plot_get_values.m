%% Copyright 2014 MERCIER David
function plot_get_values
%% Function used to get values
gui = guidata(gcf);

if gui.config.flag_data == 0
    helpdlg('Import data first !', '!!!');
    
else
    [x_value, y_value] = ginput(1);
    
    set(gui.handles.value_x_values_GUI, 'String', ...
        num2str(round(x_value)));
    %num2str((round((x_value*1000)/10))/100))
    
    set(gui.handles.value_y_values_GUI, 'String', ...
        num2str(round(y_value)));
    
    error; % Wrong value for z;
    set(gui.handles.value_z_values_GUI, 'String', ...
        num2str(gui.data.data2plot(round(x_value), round(y_value))));
    
end

end