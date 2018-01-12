%% Copyright 2014 MERCIER David
function TriDiMap_meshingGrid(data2use, varargin)
%% Function used to define mesh grids
gui = guidata(gcf);
config = gui.config;

x_step = config.XStep;
y_step = config.YStep;

if nargin > 0
    if config.N_XStep_default == config.N_YStep_default
        gui.data.xData = 0:x_step:(size(data2use,1)-1)*x_step;
        gui.data.yData = 0:y_step:(size(data2use,2)-1)*y_step;
    elseif config.N_XStep_default ~= config.N_YStep_default
        gui.data.xData = 0:x_step:(size(data2use,1)-1)*x_step;
        gui.data.yData = 0:y_step:(size(data2use,2)-1)*y_step;
    end
    if config.flagZplot
        gui.data.yData = -gui.data.yData;
    end
    
    if config.N_XStep ~= config.N_YStep
        [gui.data.xData_markers, gui.data.yData_markers] = ...
            meshgrid(1:length(gui.data.xData),1:length(gui.data.yData));
        gui.data.xData_markers = (gui.data.xData_markers-1)*x_step;
        gui.data.yData_markers = (gui.data.yData_markers-1)*y_step;
    else
        [gui.data.xData_markers, gui.data.yData_markers] = ...
            meshgrid(gui.data.xData, gui.data.yData);
    end
end

if config.rawData == 1
    gui.data.xData_interp = gui.data.xData;
    gui.data.yData_interp = gui.data.yData;
    if get(gui.handles.cb_errorMap_GUI, 'Value')
        [xData_interp, yData_interp] = ...
            meshgrid(0:x_step:(size(gui.data.expValuesInterpSmoothed,1)-1)*x_step, ...
            0:y_step:(size(gui.data.expValuesInterpSmoothed,2)-1)*y_step);
        gui.data.xData_interp = xData_interp./(2^(config.interpFact));
        gui.data.yData_interp = yData_interp./(2^(config.interpFact));
    end
elseif config.rawData == 8
    min_z = gui.config.sliceDepthMin;
    max_z = gui.config.sliceDepthMax;
    sliceNum = gui.config.sliceNum;
    z_step = (1/(sliceNum-1))*(max_z-min_z);
    [xData_interp, yData_interp, zData_interp] = ...
        meshgrid(0:x_step:(size(gui.slice_data_mat.InterSmoothed,1)-1)*x_step, ...
        0:y_step:(size(gui.slice_data_mat.InterSmoothed,2)-1)*y_step, ...
        min_z:z_step:max_z);
    if get(gui.handles.cb_interpMap_GUI, 'Value')
        gui.slice_data_mat.xData_interp = xData_interp./(2^(config.interpFact));
        gui.slice_data_mat.yData_interp = yData_interp./(2^(config.interpFact));
        gui.slice_data_mat.zData_interp = zData_interp;
    else
        gui.slice_data_mat.xData_interp = xData_interp;
        gui.slice_data_mat.yData_interp = yData_interp;
        gui.slice_data_mat.zData_interp = zData_interp;
    end
else
    [xData_interp, yData_interp] = ...
        meshgrid(0:x_step:(size(gui.data.expValuesInterpSmoothed,1)-1)*x_step, ...
        0:y_step:(size(gui.data.expValuesInterpSmoothed,2)-1)*y_step);
    if get(gui.handles.cb_interpMap_GUI, 'Value')
        gui.data.xData_interp = xData_interp./(2^(config.interpFact));
        gui.data.yData_interp = yData_interp./(2^(config.interpFact));
    else
        gui.data.xData_interp = xData_interp;
        gui.data.yData_interp = yData_interp;
    end
end

guidata(gcf, gui);

end