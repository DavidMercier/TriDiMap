%% Copyright 2014 MERCIER David
function TriDiMap_runPlot
%% Function to run the mapping
TriDiMap_getParam;

gui = guidata(gcf);
config = gui.config;

%% Clean data from Excel files
if config.flag_data
    dataYM = gui.data.expValues_mat.YM;
    dataH = gui.data.expValues_mat.H;
    
    if gui.config.noNan
        dataYM_cleaned = TriDiMap_cleaningData(dataYM);
        dataH_cleaned = TriDiMap_cleaningData(dataH);
        dataYM = dataYM_cleaned;
        dataH = dataH_cleaned;
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
        gui.data.expValues_mat_average.YM = mean(mean(dataYM));
        gui.data.expValues_mat_norm.YM = dataYM - gui.data.expValues_mat_average.YM;
        % Normalization of hardness
        gui.data.expValues_mat_average.H = mean(mean(dataH));
        gui.data.expValues_mat_norm.H = dataH - gui.data.expValues_mat_average.H;
    elseif gui.config.translationStep && gui.config.normalizationStep
        display('Translation not possible because normalization is active.');
    end
    
    %% Normalization of dataset
    if gui.config.normalizationStep && ~gui.config.translationStep
        if gui.config.normalizationStepVal == 1
            dataYM = dataYM/min(min(dataYM));
            dataH = dataH/min(min(dataH));
        elseif gui.config.normalizationStepVal == 2
            dataYM = dataYM/mean(mean(dataYM));
            dataH = dataH/mean(mean(dataH));
        elseif gui.config.normalizationStepVal == 3
            dataYM = dataYM/max(max(dataYM));
            dataH = dataH/max(max(dataH));
        end
        
    elseif gui.config.normalizationStep && transStep
        display('Normalization not possible because translation is active.');
    end
    
    %% Interpolating, smoothing and binarizing steps of dataset
    if gui.config.noNan
        [gui.data.YM.expValuesInterp, gui.data.YM.expValuesSmoothed, ...
            gui.data.YM.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            dataYM, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid);
        
        [gui.data.H.expValuesInterp, gui.data.H.expValuesSmoothed, ...
            gui.data.H.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            dataH, ...
            gui.config.interpBool, gui.config.interpFact, ...
            gui.config.smoothBool, gui.config.smoothFact,...
            gui.config.binarizedGrid);
    else
        gui.data.YM.expValuesInterp = dataYM;
        gui.data.YM.expValuesSmoothed = dataYM;
        gui.data.YM.expValuesInterpSmoothed = dataYM;
        gui.data.H.expValuesInterp = dataH;
        gui.data.H.expValuesSmoothed = dataH;
        gui.data.H.expValuesInterpSmoothed = dataH;
    end
    
    %% Grid meshing
    x_step = gui.config.XStep;
    y_step = gui.config.YStep;
    
    if gui.config.N_XStep_default == gui.config.N_YStep_default
        gui.data.xData = 0:x_step:(size(dataYM,1)-1)*x_step;
        gui.data.yData = 0:y_step:(size(dataYM,2)-1)*y_step;
    elseif gui.config.N_XStep_default ~= gui.config.N_YStep_default
        gui.data.xData = 0:x_step:(size(dataYM,1)-1)*x_step;
        gui.data.yData = 0:y_step:(size(dataYM,2)-1)*y_step;
    end
    
    if gui.config.N_XStep ~= gui.config.N_YStep
        [gui.data.xData_markers, gui.data.yData_markers] = ...
            meshgrid(1:length(gui.data.xData),1:length(gui.data.yData));
        gui.data.xData_markers = (gui.data.xData_markers-1)*x_step;
        gui.data.yData_markers = (gui.data.yData_markers-1)*y_step;
    else
        [gui.data.xData_markers, gui.data.yData_markers] = ...
            meshgrid(gui.data.xData, gui.data.yData);
    end
    %     [xData_interp, yData_interp] = ...
    %         meshgrid(0:x_step:(size(gui.data.YM.expValuesInterpSmoothed,1)-1)*x_step, ...
    %         0:y_step:(size(gui.data.YM.expValuesInterpSmoothed,2)-1)*y_step);
    
    if gui.config.rawData
        gui.data.xData_interp = gui.data.xData;
        gui.data.yData_interp = gui.data.yData;
        %     elseif gui.config.rawData && gui.config.interpBool
        %         gui.data.xData_interp = xData_interp./(2^(gui.config.interpFact));
        %         gui.data.yData_interp = yData_interp./(2^(gui.config.interpFact));
    elseif ~gui.config.rawData
        gui.data.xData_interp = gui.data.xData_markers;
        gui.data.yData_interp = gui.data.yData_markers;
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