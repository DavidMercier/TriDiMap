%% Copyright 2014 MERCIER David
function TriDiMap_runPlot
%% Function to run the mapping
TriDiMap_getParam;

gui = guidata(gcf);
config = gui.config;

%% Clean data from Excel files
if config.flag_data
    
    if gui.config.noNan
        gui.data.expValues_mat.YM = ...
            TriDiMap_cleaningData(gui.data.expValues_mat.YM);
        gui.data.expValues_mat.H = ...
            TriDiMap_cleaningData(gui.data.expValues_mat.H);
        YM4calc = gui.data.expValues_mat.YM;
        H4calc = gui.data.expValues_mat.H;
    end
    
    gui.config.data_path = config.data_path;
    gui.config.flag_data = config.flag_data;
    gui.config.N_XStep = config.N_XStep;
    gui.config.N_YStep = config.N_YStep;
    gui.config.XStep = config.XStep;
    gui.config.YStep = config.YStep;
    
    %% Translation step
    if gui.config.translationStep && ~gui.config.normalizationStep
        % Normalization of elastic modulus
        gui.data.expValues_mat_average.YM = mean(mean(gui.data.expValues_mat.YM));
        gui.data.expValues_mat_norm.YM = gui.data.expValues_mat.YM - gui.data.expValues_mat_average.YM;
        % Normalization of hardness
        gui.data.expValues_mat_average.H = mean(mean(gui.data.expValues_mat.H));
        gui.data.expValues_mat_norm.H = gui.data.expValues_mat.H - gui.data.expValues_mat_average.H;
    elseif gui.config.translationStep && gui.config.normalizationStep
        display('Translation not possible because normalization is active.');
    end
    
    %% Normalization of dataset
    if gui.config.normalizationStep && ~gui.config.translationStep
        if gui.config.normalizationStepVal == 1
            YM4calc = gui.data.expValues_mat.YM/min(min(gui.data.expValues_mat.YM));
            H4calc = gui.data.expValues_mat.H/min(min(gui.data.expValues_mat.H));
        elseif gui.config.normalizationStepVal == 2
            YM4calc = gui.data.expValues_mat.YM/mean(mean(gui.data.expValues_mat.YM));
            H4calc = gui.data.expValues_mat.H/mean(mean(gui.data.expValues_mat.H));
        elseif gui.config.normalizationStepVal == 3
            YM4calc = gui.data.expValues_mat.YM/max(max(gui.data.expValues_mat.YM));
            H4calc = gui.data.expValues_mat.H/max(max(gui.data.expValues_mat.H));
        end
        
    elseif gui.config.normalizationStep && transStep
        display('Normalization not possible because translation is active.');
    end
    
    %% Interpolating, smoothing and binarizing steps of dataset
    if gui.config.noNan
        [gui.data.YM.expValuesInterp, gui.data.YM.expValuesSmoothed, ...
            gui.data.YM.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            YM4calc, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid);

        [gui.data.H.expValuesInterp, gui.data.H.expValuesSmoothed, ...
            gui.data.H.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            H4calc, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid);
    else
        gui.data.YM.expValuesInterp = gui.data.expValues_mat.YM;
        gui.data.YM.expValuesSmoothed = gui.data.expValues_mat.YM;
        gui.data.YM.expValuesInterpSmoothed = gui.data.expValues_mat.YM;
        gui.data.H.expValuesInterp = gui.data.expValues_mat.H;
        gui.data.H.expValuesSmoothed = gui.data.expValues_mat.H;
        gui.data.H.expValuesInterpSmoothed = gui.data.expValues_mat.H;
    end
    
    %% Grid meshing
    x_step = gui.config.XStep;
    y_step = gui.config.YStep;
    
    if gui.config.N_XStep_default == gui.config.N_YStep_default
        gui.data.xData = 0:x_step:(size(gui.data.expValues_mat.YM,1)-1)*x_step;
        gui.data.yData = 0:y_step:(size(gui.data.expValues_mat.YM,2)-1)*y_step;
    elseif gui.config.N_XStep_default ~= gui.config.N_YStep_default
        gui.data.xData = 0:x_step:(size(gui.data.expValues_mat.YM,1)-1)*x_step;
        gui.data.yData = 0:y_step:(size(gui.data.expValues_mat.YM,2)-1)*y_step;
    end
    
    [gui.data.xData_markers, gui.data.yData_markers] = ...
        meshgrid(gui.data.xData, gui.data.yData);
    
    [xData_interp, yData_interp] = ...
        meshgrid(0:x_step:(size(gui.data.YM.expValuesInterpSmoothed,1)-1)*x_step, ...
        0:y_step:(size(gui.data.YM.expValuesInterpSmoothed,2)-1)*y_step);
    
    if gui.config.rawData
        gui.data.xData_interp = gui.data.xData;
        gui.data.yData_interp = gui.data.yData;
    else
        if gui.config.interpBool
            gui.data.xData_interp = xData_interp./(2^(gui.config.interpFact));
            gui.data.yData_interp = yData_interp./(2^(gui.config.interpFact));
        else
            gui.data.xData_interp = gui.data.xData_markers;
            gui.data.yData_interp = gui.data.yData_markers;
        end
    end
end

%% Legend + Map
if config.flag_data
    if gui.config.property == 1
        gui.data.data2plot = gui.data.YM.expValuesInterpSmoothed;
    elseif gui.config.property == 2
        gui.data.data2plot = gui.data.H.expValuesInterpSmoothed;
    end
    
    if ~gui.config.normalizationStep
        if gui.config.property == 1
            gui.config.legend = strcat({'Elastic modulus ('},gui.config.strUnit_Property, ')');
            %gui.config.legend = 'Module d''\''elasticit\''e (GPa)';
        elseif gui.config.property == 2
            gui.config.legend = strcat({'Hardness ('},gui.config.strUnit_Property, ')');
            %gui.config.legend = 'Duret\''e (GPa)';
        end
        
    elseif gui.config.normalizationStep > 0
        if gui.config.normalizationStepVal == 1
            if gui.config.property == 1
                gui.config.legend = 'Normalized elastic modulus by minimum elastic modulus value';
            elseif gui.config.property == 2
                gui.config.legend = 'Normalized hardness by minimum hardness value';
            end
        elseif gui.config.normalizationStepVal == 2
            if gui.config.property == 1
                gui.config.legend = 'Normalized elastic modulus by mean elastic modulus value';
            elseif gui.config.property == 2
                gui.config.legend = 'Normalized hardness by mean hardness value';
            end
        elseif gui.config.normalizationStepVal == 3
            if gui.config.property == 1
                gui.config.legend = 'Normalized elastic modulus by maximum elastic modulus value';
            elseif gui.config.property == 2
                gui.config.legend = 'Normalized hardness by maximum hardness value';
            end
        end
    end
    guidata(gcf, gui);
    if get(gui.handles.cb_errorMap_GUI, 'Value')
        TriDiMap_error_plotting;
    else    
        TriDiMap_mapping_plotting;
    end
    gui = guidata(gcf);
end
guidata(gcf, gui);
end