%% Copyright 2014 MERCIER David
function TriDiMap_runPlot(gifFlag, varargin)
%% Function to run the mapping
if nargin < 1
    gifFlag = 0;
end
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
strUnit_Property = ...
    get_value_popupmenu(gui.handles.unitProp_GUI, listUnitProperty);
guidata(gcf, gui);
if config.rawData == 8 && gui.config.property  < 3% Code for 3D slices
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
                data2use(data2use < gui.config.minVal) = NaN;
            else
                data2use_E(data2use_E < gui.config.minVal) = NaN;
                data2use_H(data2use_H < gui.config.minVal) = NaN;
            end
        else
            if config.property ~= 3
                gui.config.minVal = round(100*(nanmin(nanmin(data2use))))/100;
            else
                gui.config.minVal = round(100*(nanmin(nanmin([data2use_E, data2use_H]))))/100;
            end
            
        end
        set(gui.handles.value_MinVal_GUI, 'String', num2str(nanmin(gui.config.minVal)));
        if gui.config.maxVal < 0 || gui.config.maxVal < gui.config.minVal
            gui.config.maxVal = gui.config.minVal + 100;
        end
        if ~isnan(gui.config.maxVal) && (gui.config.propertyOld == gui.config.property)
            if config.property ~= 3
                data2use(data2use > gui.config.maxVal) = NaN;
            else
                data2use_E(data2use_E > gui.config.maxVal) = NaN;
                data2use_H(data2use_H > gui.config.maxVal) = NaN;
            end
        else
            if config.property ~= 3
                gui.config.maxVal = round(100*(nanmax(nanmax(data2use))))/100;
            else
                gui.config.maxVal = round(100*(nanmax(nanmax([data2use_E, data2use_H]))))/100;
            end
        end
        set(gui.handles.value_MaxVal_GUI, 'String', num2str(nanmax(gui.config.maxVal)));
        if config.property ~= 3
            gui.config.meanVal = round(100*(nanmean(nanmean(data2use))))/100;
        else
            gui.config.meanVal = round(100*(nanmean(nanmean([data2use_E, data2use_H]))))/100;
        end
        set(gui.handles.value_MeanVal_GUI, 'String', num2str(nanmean(gui.config.meanVal)));
        
        % NaN values
        if config.property < 3
            [dataCleaned, ratioNan] = TriDiMap_cleaningData(data2use);
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

guidata(gcf, gui);
if gui.config.saveFlag
    TriDiMap_updateUnit_and_GUI;
end
end