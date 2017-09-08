%% Copyright 2014 MERCIER David
function TriDiMap_runBin(plotMatch, varargin)
%% Function to run the binarization
if nargin < 1
    plotMatch = 0;
end

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
        % Crop data
        data2use = TriDiMap_cropping(data2use);
        if length(data2use) == 1
            config.flag_data = 0;
        end
        
        % Clean data
        if gui.config.noNan
            data2use = TriDiMap_cleaningData(data2use);
        end
        
        % Grid meshing
        x_step = gui.config.XStep;
        y_step = gui.config.YStep;
        
        if gui.config.N_XStep_default == gui.config.N_YStep_default
            gui.data.xData = 0:x_step:(size(data2use,1)-1)*x_step;
            gui.data.yData = 0:y_step:(size(data2use,2)-1)*y_step;
        elseif gui.config.N_XStep_default ~= gui.config.N_YStep_default
            gui.data.xData = 0:x_step:(size(data2use,1)-1)*x_step;
            gui.data.yData = 0:y_step:(size(data2use,2)-1)*y_step;
        end
        gui.data.xData_interp = gui.data.xData;
        gui.data.yData_interp = gui.data.yData;
        
        if iProp == 1
            str = 'elastic modulus';
            crit = gui.config.criterionBinMap_E;
        elseif iProp == 2
            str = 'hardness';
            crit = gui.config.criterionBinMap_H;
        end
        
        % Binarization
        data_binarized = zeros(gui.config.N_XStep_default, ...
            gui.config.N_YStep_default);
        for ii = 1:1:gui.config.N_XStep_default
            for jj = 1:1:gui.config.N_YStep_default
                if data2use(ii,jj) > crit
                    data_binarized(ii,jj) = 255;
                else
                    data_binarized(ii,jj) = 0;
                end
            end
        end
        
        ind = find(data2use <= crit);
        fractionMin = length(ind)/(length(data2use)^2);
        fractionMax = 1 - fractionMin;
        if ~plotMatch
            display(['Fraction of phase with lower ', str, ': ']);
            disp(fractionMin);
            display(['Fraction of phase with higher ', str, ': ']);
            disp(fractionMax);
        end
        
        if iProp == 1
            gui.data.data2plot_E = data_binarized;
            if ~plotMatch
                set(gui.handles.value_ratioLow_E_GUI, ...
                    'string', num2str(fractionMin*100));
                set(gui.handles.value_ratioHigh_E_GUI, ...
                    'string', num2str(fractionMax*100));
            end
        elseif iProp == 2
            gui.data.data2plot_H = data_binarized;
            if ~plotMatch
                set(gui.handles.value_ratioLow_H_GUI, 'string', ...
                    num2str(fractionMin*100));
                set(gui.handles.value_ratioHigh_H_GUI, 'string', ...
                    num2str(fractionMax*100));
            end
        end
        gui.data.data2plot = data_binarized;
        
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
    if ~plotMatch
        data2use = gui.image.image2use;
        indI = find(data2use == 0);
        fractionMin = length(indI)/(length(data2use)^2);
        fractionMax = 1 - fractionMin;
        set(gui.handles.value_ratioLow_I_GUI, 'string', ...
            num2str(fractionMin*100));
        set(gui.handles.value_ratioHigh_I_GUI, 'string', ...
            num2str(fractionMax*100));
    end
    
    if config.flag_data && config.flag_image
        set(gui.handles.plotAllCritVal_GUI, 'Visible', 'on');
        set(gui.handles.title_numThres_GUI, 'Visible', 'on');
        set(gui.handles.value_numThres_GUI, 'Visible', 'on');
    end
    
    %% Plot binarized map, image and difference map
    guidata(gcf, gui);
    
    if  ~plotMatch
        if gui.config.saveFlagBin == 0
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
            if config.flag_data && config.flag_image
                set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_5);
                TriDiMap_diff_plotting(2);
            end
            if config.flag_data && config.flag_image
                set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_6);
                TriDiMap_diff_plotting(3);
            end
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
guidata(gcf, gui);
end