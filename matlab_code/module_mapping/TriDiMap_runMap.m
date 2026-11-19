%% Copyright 2014 MERCIER David
%% Script to plot E or H map

%% Clean data
if config.flag_data
    %% Normalization of dataset
    if config.normalizationStep && ~config.translationStep
        if config.property == 10
            finite = data2use(isfinite(data2use));
            scales = [min(finite), mean(finite), max(finite)];
            scale = scales(config.normalizationStepVal);
            if isempty(scale) || ~isfinite(scale) || scale == 0
                error('TriDiMap:MLInput', 'The selected descriptor normalization scale is zero or nonfinite. Choose another scale or disable normalization.');
            end
            config.legend = ['Normalized ', config.legend];
            data2use = data2use/scale;
        elseif config.normalizationStepVal == 1
            data2use = data2use/(min(min(data2use)));
        elseif config.normalizationStepVal == 2
            data2use = data2use/(nanmean(nanmean(data2use)));
        elseif config.normalizationStepVal == 3
            data2use = data2use/(max(max(data2use)));
        end
        disp('Translation not possible because normalization is active.');
    end
    
    %% Translation step
    if config.translationStep && ~config.normalizationStep
        data2use = data2use + config.translationStepVal;
        if config.property ~= 10
            data2use((data2use)<0) = 0;
            disp('Negative values for the property are replaced by 0.');
        end
        disp('Normalization not possible because translation is active.');
    end
    
    %% Interpolating, smoothing and binarizing steps of dataset
    if isfield(gui.data, 'coordinates')
        gui.data.expValuesInterp = data2use;
        gui.data.expValuesSmoothed = data2use;
        gui.data.expValuesInterpSmoothed = data2use;
        gui.data.xData_interp = gui.data.coordinates(:, 1);
        gui.data.yData_interp = gui.data.coordinates(:, 2);
        gui.data.xData_markers = gui.data.coordinates(:, 1);
        gui.data.yData_markers = gui.data.coordinates(:, 2);
    elseif config.noNan
        [gui.data.expValuesInterp, gui.data.expValuesSmoothed, ...
            gui.data.expValuesInterpSmoothed] = ...
            TriDiMap_interpolation_smoothing(...
            data2use, ...
            config.interpBool, config.interpFact, ...
            config.smoothBool, config.smoothFact);
    else
        gui.data.expValuesInterp = data2use;
        gui.data.expValuesSmoothed = data2use;
        gui.data.expValuesInterpSmoothed = data2use;
    end
    guidata(gcf, gui);
    
    %% Grid meshing
    if ~isfield(gui.data, 'coordinates')
        TriDiMap_meshingGrid(data2use);
    end
    gui = guidata(gcf);
end

%% Legend + Map
if config.flag_data
    gui.data.data2plot = gui.data.expValuesInterpSmoothed;
    
    if ~config.normalizationStep
        if config.property == 1
            if isfield(gui.data, 'originalProperties') || isfield(gui.data, 'modulusIsReduced')
                if ~config.FrenchLeg
                    config.legend = strcat({'Reduced indentation modulus ('},config.strUnit_Property, ')');
                else
                    config.legend = strcat({'Module d''\''indentation r\''eduit ('},config.strUnit_Property, ')');
                end
            elseif ~config.FrenchLeg
                config.legend = strcat({'Elastic modulus ('},config.strUnit_Property, ')');
            else
                config.legend = strcat({'Module d''\''elasticit\''e ('},config.strUnit_Property, ')');
            end
        elseif config.property == 2
            if ~config.FrenchLeg
                config.legend = strcat({'Hardness ('},config.strUnit_Property, ')');
            else
                config.legend = strcat({'Duret\''e ('},config.strUnit_Property, ')');
            end
        elseif config.property == 3
                config.legend = 'Phase';
        end
        
    elseif config.normalizationStep > 0
        if config.normalizationStepVal == 1
            if config.property == 1
                if ~config.FrenchLeg
                    config.legend = 'Normalized elastic modulus by minimum elastic modulus value';
                else
                    config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur minimum';
                end
            elseif config.property == 2
                if ~config.FrenchLeg
                    config.legend = 'Normalized hardness by minimum hardness value';
                else
                    config.legend = 'Duret\''e normalis\''ee par la valeur minimum';
                end
            end
        elseif config.normalizationStepVal == 2
            if config.property == 1
                if ~config.FrenchLeg
                    config.legend = 'Normalized elastic modulus by mean elastic modulus value';
                else
                    config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur moyenne';
                end
            elseif config.property == 2
                if ~config.FrenchLeg
                    config.legend = 'Normalized hardness by mean hardness value';
                else
                    config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur moyenne';
                end
            end
        elseif config.normalizationStepVal == 3
            if config.property == 1
                if ~config.FrenchLeg
                    config.legend = 'Normalized elastic modulus by maximum elastic modulus value';
                else
                    config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur maximum';
                end
            elseif config.property == 2
                if ~config.FrenchLeg
                    config.legend = 'Normalized hardness by maximum hardness value';
                else
                    config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur maximum';
                end
            end
        end
    end
    if config.normalizationStep && config.property == 1 && ...
            (isfield(gui.data, 'originalProperties') || isfield(gui.data, 'modulusIsReduced'))
        config.legend = strrep(config.legend, 'elastic modulus', 'reduced indentation modulus');
        config.legend = strrep(config.legend, 'Module d''\''elasticit\''e', ...
            'Module d''\''indentation r\''eduit');
    end
    gui.config = config;
    guidata(gcf, gui);
    if get(gui.handles.cb_errorMap_GUI, 'Value')
        TriDiMap_plot_error;
    else
        TriDiMap_plot;
    end
    gui = guidata(gcf);
else
    errordlg(['First set indentation grid parameters and load an '...
        'Excel file to plot a property map !']);
end