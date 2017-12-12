%% Copyright 2014 MERCIER David
function TriDiMap_runBin(plotMatch, varargin)
%% Function to run the binarization
if nargin < 1
    plotMatch = 0;
end

clc;

if ~plotMatch
    reset(gca);
    TriDiMap_getParam;
end
gui = guidata(gcf);
config = gui.config;

%% Data
if config.flag_data
    for iProp = 1:2
        if iProp == 1
            data2use = gui.data.expValues_mat.YM;
        elseif iProp == 2
            data2use = gui.data.expValues_mat.H;
        end
        
        [data_binarized, fractionMin, fractionMax] = ...
            TriDiMap_binStep(data2use, plotMatch, iProp);
        
        gui = guidata(gcf);
        
        if iProp == 1
            gui.data.data2plot_E = data_binarized;
            crit = gui.config.criterionBinMap_E;
            if ~plotMatch
                set(gui.handles.value_ratioLow_E_GUI, ...
                    'string', num2str(round(fractionMin*1000)/10));
                set(gui.handles.value_ratioHigh_E_GUI, ...
                    'string', num2str(round(fractionMax*1000)/10));
            end
        elseif iProp == 2
            gui.data.data2plot_H = data_binarized;
            crit = gui.config.criterionBinMap_H;
            if ~plotMatch
                set(gui.handles.value_ratioLow_H_GUI, 'string', ...
                    num2str(round(fractionMin*1000)/10));
                set(gui.handles.value_ratioHigh_H_GUI, 'string', ...
                    num2str(round(fractionMax*1000)/10));
            end
        end
        
        data2useHard = zeros(gui.config.N_XStep_default, ...
            gui.config.N_YStep_default);
        data2useSoft = zeros(gui.config.N_XStep_default, ...
            gui.config.N_YStep_default);
        for ii = 1:1:gui.config.N_XStep_default
            for jj = 1:1:gui.config.N_YStep_default
                if data2use(ii,jj) > crit
                    data2useHard(ii,jj) = data2use(ii,jj);
                    data2useSoft(ii,jj) = NaN;
                else
                    data2useHard(ii,jj) = NaN;
                    data2useSoft(ii,jj) = data2use(ii,jj);
                end
            end
        end
        
        gui.data.data2plot = data_binarized;
        
        if iProp == 1
            gui.data.meanE_soft = round(nanmean(nanmean(data2useSoft))*10)/10;
            gui.data.stdE_soft = round(nanstd(reshape(data2useSoft, [size(data2useSoft,1)*size(data2useSoft,2) 1]))*10)/10;
            gui.data.meanE_hard = round(nanmean(nanmean(data2useHard))*10)/10;
            gui.data.stdE_hard = round(nanstd(reshape(data2useHard, [size(data2useHard,1)*size(data2useHard,2) 1]))*10)/10;
            set(gui.handles.value_valMeanLow_E_GUI, ...
                'String', [num2str(gui.data.meanE_soft),'±',num2str(gui.data.stdE_soft)]);
            set(gui.handles.value_valMeanHigh_E_GUI, ...
                'String', [num2str(gui.data.meanE_hard),'±',num2str(gui.data.stdE_hard)]);
            gui.data.data2plot_E = data_binarized;
            str = 'elastic modulus';
        elseif iProp == 2
            gui.data.meanH_soft = round(nanmean(nanmean(data2useSoft))*10)/10;
            gui.data.stdH_soft = round(nanstd(reshape(data2useSoft, [size(data2useSoft,1)*size(data2useSoft,2) 1]))*10)/10;
            gui.data.meanH_hard = round(nanmean(nanmean(data2useHard))*10)/10;
            gui.data.stdH_hard = round(nanstd(reshape(data2useHard, [size(data2useHard,1)*size(data2useHard,2) 1]))*10)/10;
            set(gui.handles.value_valMeanLow_H_GUI, ...
                'String', [num2str(gui.data.meanH_soft),'±',num2str(gui.data.stdH_soft)]);
            set(gui.handles.value_valMeanHigh_H_GUI, ...
                'String', [num2str(gui.data.meanH_hard),'±',num2str(gui.data.stdH_hard)]);
            str = 'hardness';
        end
        
        data2plot = gui.data.data2plot;
        if ~plotMatch
            fracBW = sum(sum(data2plot))/(size(data2plot,1)*...
                size(data2plot,2)*255);
            display(['Fraction of matrix (', str, ' map) :']);
            disp(1-fracBW);
            display(['Fraction of particles (', str, ' map) :']);
            disp(fracBW);
        end
        guidata(gcf, gui);
        
        if gui.config.saveFlagBin == 0 && ~plotMatch
            % Binarized map
            if config.flag_data && iProp == 1
                set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_1);
                gui.legend = 'elastic modulus';
                guidata(gcf, gui);
                TriDiMap_mapping_plotting;
            end
            if config.flag_data && iProp == 2
                set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_2);
                gui.legend = 'hardness';
                guidata(gcf, gui);
                TriDiMap_mapping_plotting;
            end
        end
    end
    
    %% Image
    if config.flag_image && ~plotMatch
        gui.image.image2plot = gui.image.image2use;
    end
    if config.flag_data && config.flag_image
        if ~plotMatch
            data2use = gui.image.image2use;
            indI = find(data2use == 0);
            fractionMin = length(indI)/(length(data2use)^2);
            fractionMax = 1 - fractionMin;
            set(gui.handles.value_ratioLow_I_GUI, 'string', ...
                num2str(round(fractionMin*1000)/10));
            set(gui.handles.value_ratioHigh_I_GUI, 'string', ...
                num2str(round(fractionMax*1000)/10));
        end
        set(gui.handles.optCritVal_GUI, 'Visible', 'on');
        set(gui.handles.plotAllCritVal_GUI, 'Visible', 'on');
        set(gui.handles.title_numThres_GUI, 'Visible', 'on');
        set(gui.handles.value_numThres_GUI, 'Visible', 'on');
    end
    
    %% Plot binarized map, image and difference map
    guidata(gcf, gui);
    
    if gui.config.saveFlagBin == 0 && ~plotMatch
        % Binarized image
        if config.flag_image
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_3);
            TriDiMap_image_plotting;
        end
        % Difference map
        if config.flag_data && config.flag_image
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_4);
            TriDiMap_diff_plotting(1);
        end
        gui = guidata(gcf);
        if gui.config.sizeCheck
            if config.flag_data && config.flag_image
                set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_5);
                TriDiMap_diff_plotting(2);
            end
            if config.flag_data && config.flag_image
                set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_6);
                TriDiMap_diff_plotting(3);
            end
        end
        if ~config.flag_image
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_3);
            cla(gca);
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_4);
            cla(gca);
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_5);
            cla(gca);
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_6);
            cla(gca);
        end
    end
else
    errordlg('Load first indentation dataset file !');
end

if gui.config.saveFlagBin == 1
    gui.data.data2plot = gui.data.data2plot_E;
    guidata(gcf, gui);
    TriDiMap_mapping_plotting;
elseif gui.config.saveFlagBin == 2
    gui.data.data2plot = gui.data.data2plot_H;
    guidata(gcf, gui);
    TriDiMap_mapping_plotting;
elseif gui.config.saveFlagBin == 3
    TriDiMap_image_plotting;
elseif gui.config.saveFlagBin == 4
    TriDiMap_diff_plotting(1);
elseif gui.config.saveFlagBin == 5
    TriDiMap_diff_plotting(2);
elseif gui.config.saveFlagBin == 6
    TriDiMap_diff_plotting(3);
end

coordSyst(gui.handles.MainWindow);
gui = guidata(gcf);
guidata(gcf, gui);
end