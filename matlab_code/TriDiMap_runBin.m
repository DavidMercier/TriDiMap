%% Copyright 2014 MERCIER David
function TriDiMap_runBin
%% Function to run the binarization
reset(gca);
TriDiMap_getParam;
gui = guidata(gcf);
config = gui.config;

%% Data
if config.flag_data
    if gui.config.property == 1
        data2use = gui.data.expValues_mat.YM;
    elseif gui.config.property == 2
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
    
    % Binarization
    data_binarized = zeros(gui.config.N_XStep_default, gui.config.N_YStep_default);
    for ii = 1:1:gui.config.N_XStep_default
        for jj = 1:1:gui.config.N_YStep_default
            if data2use(ii,jj) > gui.config.criterionBinMap
                data_binarized(ii,jj) = 255;
            else
                data_binarized(ii,jj) = 0;
            end
        end
    end
    
    gui.data.data2plot = data_binarized;
    
    if gui.config.property == 1
        str = 'elastic modulus';
    elseif gui.config.property == 2
        str = 'hardness';
    end
    
    ind = find(data2use <= gui.config.criterionBinMap);
    fractionMin = length(ind)/(length(data2use)^2);
    fractionMax = 1 - fractionMin;
    display(['Fraction of phase with lower ', str, ': ']);
    disp(fractionMin);
    display(['Fraction of phase with higher ', str, ': ']);
    disp(fractionMax);
    
    set(gui.handles.value_ratioLow_GUI, 'string', num2str(fractionMin*100));
    set(gui.handles.value_ratioHigh_GUI, 'string', num2str(fractionMax*100));
    
    legendStr = gui.config.legendStr;
    if gui.config.legendBinMap
        %set(hcb1,'YTick',[0:maxVal/2:maxVal]);
        legendBinaryMap('w', 'k', 's', 's', legendStr, FontSizeVal);
    end
    
    % Phase fraction calculation
    if gui.config.property == 1
        zString = 'Elastic modulus';
    elseif gui.config.property == 2
        zString = 'Hardness';
    end
    data2plot = gui.data.data2plot;
    fracBW = sum(sum(data2plot))/(size(data2plot,1)*size(data2plot,2)*255);
    display(['Fraction of matrix (', zString, ' map) :']);
    disp(1-fracBW);
    display(['Fraction of particles (', zString, ' map) :']);
    disp(fracBW);
    
    %% Image
    if config.flag_image
        gui.image.image2plot = gui.image.image2use;
    end
    
    %% Plot binarized map, image and difference map
    guidata(gcf, gui);
    
    if gui.config.saveFlagBin == 0
        % Binarized map
        if config.flag_data
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_1);
            TriDiMap_mapping_plotting;
        end
        % Binarized image
        if config.flag_image
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_2);
            TriDiMap_image_plotting;
        end
        % Difference map
        if config.flag_data && config.flag_image
            set(gcf,'CurrentAxes', gui.handles.AxisPlot_GUI_3);
            TriDiMap_diff_plotting;
        end
    end
else
    errordlg('Load first indentation dataset file !');
end

if gui.config.saveFlagBin == 1
    TriDiMap_mapping_plotting;
elseif gui.config.saveFlagBin == 2
    TriDiMap_image_plotting;
elseif gui.config.saveFlagBin == 3
    TriDiMap_diff_plotting;
end

coordSyst(gui.handles.MainWindow);
guidata(gcf, gui);
end