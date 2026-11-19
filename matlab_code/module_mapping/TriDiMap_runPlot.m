%% Copyright 2014 MERCIER David
function TriDiMap_runPlot(gifFlag, varargin)
%% Function to run the mapping
if nargin < 1
    gifFlag = 0;
end
TriDiMap_applyGrayscale(gca, false);
reset(gca);
gui = guidata(gcf);
axes(gui.handles.AxisPlot_GUI);
LWval = 1.5; %LineWidth
gui.config.gifFlag = gifFlag;
guidata(gcf, gui); gui = guidata(gcf);
if ~gui.config.saveFlag
    TriDiMap_updateUnit_and_GUI;
else
    figure(gui.config.hNewFig);
end
TriDiMap_getParam;
gui = guidata(gcf);
config = gui.config;
if isfield(gui.data, 'originalProperties') && config.rawData == 8 && config.property < 3
    plotFigure = gcf;
    errordlg('Depth slices use separate data and cannot use the recalculated map values.', 'Contact model');
    set(0, 'CurrentFigure', plotFigure);
    set(gui.handles.pm_pixData_GUI, 'Value', 1);
    TriDiMap_getParam;
    gui = guidata(gcf);
    config = gui.config;
end
strUnit_Property = ...
    get_value_popupmenu(gui.handles.unitProp_GUI, listUnitProperty);
guidata(gcf, gui);
if config.property == 10
    if ~config.flag_data
        errordlg('Load a mechanical property map first.', 'KAMM map');
    else
        try
            if config.flagZplot || isfield(gui.data, 'coordinates')
                error('TriDiMap:KAMMRequiresGrid', 'KAMM requires a 2D raster map; switch back from depth mapping.');
            end
            if ~strcmp(char(config.strUnit_Property), 'GPa')
                error('TriDiMap:MLInput', 'KAMM expects measured modulus and hardness in GPa.');
            end
            E = TriDiMap_cropping(gui.data.expValues_mat.YM);
            H = TriDiMap_cropping(gui.data.expValues_mat.H);
            gui = TriDiMap_cacheKamm(gui, E, H);
            names = {'KAMM', 'KAEM', 'KAPM', 'KAMM_RATIO', 'KAMM_NORMPROD'};
            data2use = gui.kamm.maps.(names{config.mlMetric});
            values = data2use(isfinite(data2use));
            if isempty(values)
                error('TriDiMap:MLInput', 'This descriptor has no finite values to display.');
            end
            set(gui.handles.value_MinVal_GUI, 'String', num2str(min(values)));
            set(gui.handles.value_MaxVal_GUI, 'String', num2str(max(values)));
            set(gui.handles.value_MeanVal_GUI, 'String', num2str(mean(values)));
            set(gui.handles.value_StdVal_GUI, 'String', num2str(std(values)));
            units = {'GPa$^2$', 'GPa', 'GPa', 'dimensionless', 'dimensionless'};
            config.kammUnit = units{config.mlMetric};
            config.legend = sprintf('%s (order %d; %s)', ...
                strrep(names{config.mlMetric}, '_', '\_'), config.mlOrder, config.kammUnit);
            [cleaned, ratioNan] = TriDiMap_cleaningData(data2use, true);
            set(gui.handles.value_NaNratio_GUI, 'String', num2str(ratioNan));
            if config.noNan
                data2use = cleaned;
            end
            gui.config = config;
            guidata(gcf, gui);
            TriDiMap_runMap;
        catch exception
            if any(strcmp(exception.identifier, {'TriDiMap:MLInput', 'TriDiMap:KAMMRequiresGrid'}))
                errordlg(exception.message, 'KAMM map');
            else
                rethrow(exception);
            end
        end
    end
elseif config.rawData == 8 && gui.config.property < 3% Code for 3D slices
    TriDiMap_sliceCalc(gui);
    gui = guidata(gcf);
else
    if config.flag_data
        if config.property == 1 || config.property == 4 || config.property == 6 || config.property == 8
            if ~config.flagZplot
                data2use = gui.data.expValues_mat.YM;
            else
                data2use = gui.data3D.meanZVal_YM;
            end
        elseif config.property == 2 || config.property == 5 || config.property == 7 || config.property == 9
            if ~config.flagZplot
                data2use = gui.data.expValues_mat.H;
            else
                data2use = gui.data3D.meanZVal_H;
            end
        elseif config.property == 3
            data2use_E = gui.data.expValues_mat.YM;
            data2use_H = gui.data.expValues_mat.H;
            data2use = data2use_H;
        end
        
        % Thresholding
        if gui.config.minVal < 0
            gui.config.minVal = 0;
        end
        if config.property == 3
            if gui.config.minVal >= nanmax(data2use_H) | gui.config.minVal >= nanmax(data2use_E)
                gui.config.minVal = 0;
            end
        end
        if ~isnan(gui.config.minVal) && (gui.config.propertyOld == gui.config.property)
            if config.property ~= 3
                data2use(data2use < (gui.config.minVal*0.9)) = NaN;
            else
                data2use_E(data2use_E < (gui.config.minVal*0.9)) = NaN;
                data2use_H(data2use_H < (gui.config.minVal*0.9)) = NaN;
            end
        else
            if config.property ~= 3
                gui.config.minVal = nanmin(data2use(:));
            else
                gui.config.minVal = nanmin(nanmin([data2use_E, data2use_H]));
            end
            
        end
        set(gui.handles.value_MinVal_GUI, 'String', num2str(round(100*(nanmin(gui.config.minVal)))/100));
        if gui.config.maxVal < 0 || gui.config.maxVal < gui.config.minVal
            gui.config.maxVal = gui.config.minVal + 100;
        end
        if ~isnan(gui.config.maxVal) && (gui.config.propertyOld == gui.config.property)
            if config.property ~= 3
                data2use(data2use > (gui.config.maxVal*1.1)) = NaN;
            else
                data2use_E(data2use_E > (gui.config.maxVal*1.1)) = NaN;
                data2use_H(data2use_H > (gui.config.maxVal*1.1)) = NaN;
            end
        else
            if config.property ~= 3
                gui.config.maxVal = nanmax(data2use(:));
            else
                gui.config.maxVal = nanmax(nanmax([data2use_E, data2use_H]));
            end
        end
        set(gui.handles.value_MaxVal_GUI, 'String', num2str(round(100*(nanmax(gui.config.maxVal)))/100));
        if config.property ~= 3
            gui.config.meanVal = round(100*(nanmean(data2use(:))))/100;
            gui.config.stdVal = round(100*(nanstd(data2use(:))))/100; %std(A,'omitnan')
        else
            gui.config.meanVal = round(100*(nanmean(nanmean([data2use_E, data2use_H]))))/100;
            gui.config.stdVal = round(100*(nanstd(nanstd([data2use_E, data2use_H]))))/100; %std(A,'omitnan')
        end
        set(gui.handles.value_MeanVal_GUI, 'String', num2str(nanmean(gui.config.meanVal)));
        set(gui.handles.value_StdVal_GUI, 'String', num2str((gui.config.stdVal)));
        
        % NaN values
        if config.property < 3
            if isfield(gui.data, 'coordinates')
                dataCleaned = data2use;
                ratioNan = 100 * sum(isnan(data2use(:))) / numel(data2use);
            else
                [dataCleaned, ratioNan] = TriDiMap_cleaningData(data2use);
            end
            set(gui.handles.value_NaNratio_GUI, 'String', num2str(ratioNan));
            if config.noNan
                data2use = dataCleaned;
            end
        end
        if config.property ~= 3
            %% Crop data
            [data2use, config.flagCrop] = TriDiMap_cropping(data2use);
            if length(data2use) == 1
                config.flag_data = 0;
            end
        else
            [data2use_E, config.flagCrop] = TriDiMap_cropping(data2use_E);
            [data2use_H, config.flagCrop] = TriDiMap_cropping(data2use_H);
            if length(data2use_E) == 1 && length(data2use_H) == 1
                config.flag_data = 0;
            end
        end
    end
    
    if config.property < 3
        TriDiMap_runMap;
    elseif config.property == 3
        TriDiMap_runEHmap;
    elseif config.property == 4 || config.property == 5
        TriDiMap_runPdf;
    elseif config.property == 6 || config.property == 7
        TriDiMap_runCdf;
    elseif config.property == 8 || config.property == 9
        TriDiMap_runPdf;
        hold on;
        TriDiMap_runCdf;
    end
    if config.flag_data
        if config.property < 3
            coordSyst(gui.handles.MainWindow);
        else
            if ~config.saveFlag
                set(0, 'currentfigure', gui.handles.MainWindow);
                try
                    delete(findall(gcf,'Tag','annotation'));
                catch
                end
            end
        end
    end
end

if gui.config.grid
    grid on;
else
    grid off;
end
hold off;

TriDiMap_applyGrayscale(gca, ...
    isfield(gui.config, 'grayscalePlots') && gui.config.grayscalePlots);
guidata(gcf, gui);
if gui.config.saveFlag
    TriDiMap_updateUnit_and_GUI;
end

end