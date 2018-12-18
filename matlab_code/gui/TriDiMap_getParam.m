%% Copyright 2014 MERCIER David
function TriDiMap_getParam
%% Function to get parameters from the GUI
gui = guidata(gcf);
h = gui.handles;

gui.config.dataType = get(h.pm_set_file, 'Value');
gui.config.N_XStep_default = str2num(get(h.value_numXindents_GUI, 'String'));
gui.config.N_YStep_default = str2num(get(h.value_numYindents_GUI, 'String'));
gui.config.XStep = str2num(get(h.value_deltaXindents_GUI, 'String'));
gui.config.YStep = str2num(get(h.value_deltaYindents_GUI, 'String'));

gui.config.MinXCrop = str2num(get(h.value_MinXCrop_GUI, 'String'));
gui.config.MaxXCrop = str2num(get(h.value_MaxXCrop_GUI, 'String'));
gui.config.MinYCrop = str2num(get(h.value_MinYCrop_GUI, 'String'));
gui.config.MaxYCrop = str2num(get(h.value_MaxYCrop_GUI, 'String'));

gui.config.colorMap = char(get_value_popupmenu(h.colormap_GUI, listColormap));
gui.config.flipColor = get(h.cb_flipColormap_GUI, 'Value');

if strcmp(get(h.binarization_GUI, 'String'), 'BINARIZATION')
    gui.config.property = get(h.property_GUI, 'Value');
    
    if gui.config.property == 3
        gui.config.HVal_ThresLines = ...
            str2num(get(h.value_Hth_ValEH_GUI, 'String'));
        gui.config.EVal_ThresLines = ...
            str2num(get(h.value_Eth_ValEH_GUI, 'String'));
        gui.config.plotClusters = get(h.pm_sectPlot_GUI, 'Value');
        if gui.config.plotClusters == 1 || gui.config.plotClusters == 3
            set(h.pm_pixData_GUI, 'Value', 3);
            set(h.title_Hth_ValEH_GUI, 'Visible', 'off');
            set(h.value_Hth_ValEH_GUI, 'Visible', 'off');
            set(h.unit_Hth_ValEH_GUI, 'Visible', 'off');
            set(h.title_Eth_ValEH_GUI, 'Visible', 'off');
            set(h.value_Eth_ValEH_GUI, 'Visible', 'off');
            set(h.unit_Eth_ValEH_GUI, 'Visible', 'off');
            set(h.cb_thresPlot_GUI, 'Visible', 'off');
            set(h.cb_sectMVPlot_GUI, 'Visible', 'off');
            set(h.cb_plotSectMap_GUI, 'Visible', 'off');
            set(h.title_K_GMM_GUI, 'Visible', 'off');
            set(h.value_K_GMM_GUI, 'Visible', 'off');
            set(h.cb_plotEllipse_GUI, 'Visible', 'off');
            gui.config.plotThresLines = 0;
            gui.config.plotSectMap = 0;
            if gui.config.plotClusters == 3
                gui.config.K_GMM_old = gui.config.K_GMM;
                gui.config.K_GMM = str2num(get(h.value_K_GMM_GUI, 'String'));
                if gui.config.K_GMM_old ~= gui.config.K_GMM
                    gui.config.flag_ClusterGauss = 0;
                end
                set(h.title_K_GMM_GUI, 'Visible', 'on');
                set(h.value_K_GMM_GUI, 'Visible', 'on');
                set(h.cb_plotSectMap_GUI, 'Visible', 'on');
                gui.config.plotSectMap = get(h.cb_plotSectMap_GUI, 'Value');
                set(h.cb_plotEllipse_GUI, 'Visible', 'on');
                set(h.pb_diffEHmapCluster_GUI, 'Visible', 'on');
            end
        elseif gui.config.plotClusters == 2
            set(h.title_Hth_ValEH_GUI, 'Visible', 'on');
            set(h.value_Hth_ValEH_GUI, 'Visible', 'on');
            set(h.unit_Hth_ValEH_GUI, 'Visible', 'on');
            set(h.title_Eth_ValEH_GUI, 'Visible', 'on');
            set(h.value_Eth_ValEH_GUI, 'Visible', 'on');
            set(h.unit_Eth_ValEH_GUI, 'Visible', 'on');
            set(h.cb_thresPlot_GUI, 'Visible', 'on');
            set(h.cb_sectMVPlot_GUI, 'Visible', 'on');
            set(h.cb_plotSectMap_GUI, 'Visible', 'on');
            set(h.title_K_GMM_GUI, 'Visible', 'off');
            set(h.value_K_GMM_GUI, 'Visible', 'off');
            set(h.cb_plotEllipse_GUI, 'Visible', 'off');
            gui.config.plotThresLines = get(h.cb_thresPlot_GUI, 'Value');
            gui.config.plotSectMap = get(h.cb_plotSectMap_GUI, 'Value');
            set(h.pb_diffEHmapCluster_GUI, 'Visible', 'off');
        end
    elseif gui.config.property  > 3
        gui.config.binSize = str2num(get(h.value_BinSizeHist_GUI, 'String'));
        gui.config.autobinSize  = get(h.cb_autoBinSizeHist_GUI, 'Value');
        gui.config.MinHistVal = str2num(get(h.value_MinValHist_GUI, 'String'));
        gui.config.MaxHistVal = str2num(get(h.value_MaxValHist_GUI, 'String'));
        gui.config.MinCDFVal = str2num(get(h.value_MinValCDF_GUI, 'String'));
        gui.config.MaxCDFVal = str2num(get(h.value_MaxValCDF_GUI, 'String'));
        %set(h.pm_sectPlot_GUI, 'Value', 1);
        set(h.cb_plotSectMap_GUI, 'Value', 0);
        gui.config.plotSectMap = 0;
    end
    if gui.config.property < 3
        set(gui.handles.title_z_values_prop_GUI, 'Visible', 'on');
        set(gui.handles.value_z_values_GUI, 'Visible', 'on');
        set(gui.handles.unit_z_values_GUI, 'Visible', 'on');
        %set(h.pm_sectPlot_GUI, 'Value', 1);
        set(h.cb_plotSectMap_GUI, 'Value', 0);
        gui.config.plotSectMap = 0;
    else
        set(gui.handles.title_z_values_prop_GUI, 'Visible', 'off');
        set(gui.handles.value_z_values_GUI, 'Visible', 'off');
        set(gui.handles.unit_z_values_GUI, 'Visible', 'off');
    end
    gui.config.rawData = get(h.pm_pixData_GUI, 'Value');
    gui.config.shadingData = get(h.pm_surfShading_GUI, 'Value');
    gui.config.meshHidden = get(h.cb_meshOption_GUI, 'Value');
    gui.config.zAxisRatioVal = str2num(get(h.value_zAxisRatio_GUI, 'String'));
    if gui.config.rawData == 2
        gui.config.contourPlot = get(h.pm_contourPlotMap_GUI, 'Value');
        set(h.pm_contourPlotMap_GUI, 'Visible', 'on');
        if gui.config.contourPlot > 1
            set(h.cb_textContourPlotMap_GUI, 'Visible', 'on');
        else
            set(h.cb_textContourPlotMap_GUI, 'Visible', 'off');
        end
    else
        gui.config.contourPlot = 0;
        set(h.pm_contourPlotMap_GUI, 'Visible', 'off');
        set(h.cb_textContourPlotMap_GUI, 'Visible', 'off');
    end
    if gui.config.rawData == 2 || gui.config.rawData == 3
        set(h.pm_surfShading_GUI, 'Visible', 'on');
    elseif gui.config.rawData == 7
        set(h.pm_surfShading_GUI, 'Visible', 'on');
        listSurfVal = listSurf;
        set(h.pm_surfShading_GUI, 'String', listSurfVal(1:2,:));
    else
        set(h.pm_surfShading_GUI, 'Visible', 'off');
    end
    if gui.config.rawData == 6
        set(h.cb_meshOption_GUI, 'Visible', 'on');
    else
        set(h.cb_meshOption_GUI, 'Visible', 'off');
    end
    if gui.config.rawData == 1
        set(h.title_zAxisRatio_GUI, 'Visible', 'off');
        set(h.value_zAxisRatio_GUI, 'Visible', 'off');
    else
        set(h.title_zAxisRatio_GUI, 'Visible', 'on');
        set(h.value_zAxisRatio_GUI, 'Visible', 'on');
    end
    if gui.config.rawData == 8
        set(h.title_sliceNum_GUI, 'Visible', 'on');
        set(h.value_sliceNum_GUI, 'Visible', 'on');
        set(h.title_sliceDepthMin_GUI, 'Visible', 'on');
        set(h.value_sliceDepthMin_GUI, 'Visible', 'on');
        set(h.title_sliceDepthMax_GUI, 'Visible', 'on');
        set(h.value_sliceDepthMax_GUI, 'Visible', 'on');
        set(h.title_alphaMap_GUI, 'Visible', 'on');
        set(h.value_alphaMap_GUI, 'Visible', 'on');
        set(h.pb_gif_GUI, 'Visible', 'on');
    else
        set(h.title_sliceNum_GUI, 'Visible', 'off');
        set(h.value_sliceNum_GUI, 'Visible', 'off');
        set(h.title_sliceDepthMin_GUI, 'Visible', 'off');
        set(h.value_sliceDepthMin_GUI, 'Visible', 'off');
        set(h.title_sliceDepthMax_GUI, 'Visible', 'off');
        set(h.value_sliceDepthMax_GUI, 'Visible', 'off');
        set(h.title_alphaMap_GUI, 'Visible', 'off');
        set(h.value_alphaMap_GUI, 'Visible', 'off');
        set(h.pb_gif_GUI, 'Visible', 'off');
    end
    gui.config.sliceNum = str2num(get(h.value_sliceNum_GUI, 'String'));
    gui.config.sliceDepthMin = str2num(get(h.value_sliceDepthMin_GUI, 'String'));
    gui.config.sliceDepthMax = str2num(get(h.value_sliceDepthMax_GUI, 'String'));
    gui.config.alpha = str2num(get(h.value_alphaMap_GUI, 'String'));
    if gui.config.alpha > 1 || gui.config.alpha < 0
        gui.config.alpha = 0.5;
        warning('Alpha value can''t be less than 0 and higher than 1!');
        set(h.value_alphaMap_GUI, 'String', num2str(gui.config.alpha));
    end
    gui.config.noNan = get(h.cb_pixNaN_GUI, 'Value');
    if ~gui.config.noNan
        set(h.cb_interpMap_GUI, 'Value', 0);
        set(h.cb_interpMap_GUI, 'Visible', 'off');
        set(h.pm_interpMap_GUI, 'Visible', 'off');
        set(h.cb_smoothMap_GUI, 'Value', 0);
        set(h.cb_smoothMap_GUI, 'Visible', 'off');
        set(h.pm_smoothMap_GUI, 'Visible', 'off');
        gui.config.binarizedGrid = 0;
        disp('Interpolation and smoothing not active, because NaN values not removed/corrected !');
    else
        set(h.cb_interpMap_GUI, 'Visible', 'on');
        set(h.pm_interpMap_GUI, 'Visible', 'on');
        set(h.cb_smoothMap_GUI, 'Visible', 'on');
        set(h.pm_smoothMap_GUI, 'Visible', 'on');
        set(h.cb_errorMap_GUI, 'Visible', 'on');
    end
    
    gui.config.interpBool = get(h.cb_interpMap_GUI, 'Value');
    if gui.config.interpBool == 0
        gui.config.interpFactVal = 1;
    end
    gui.config.interpFactStr = get_value_popupmenu(h.pm_interpMap_GUI, listInterp);
    gui.config.interpFact = get(h.pm_interpMap_GUI, 'Value');
    if gui.config.interpBool == 1
        if gui.config.interpFact == 1
            gui.config.interpFactVal = 2;
        elseif gui.config.interpFact == 2
            gui.config.interpFactVal = 4;
        elseif gui.config.interpFact == 3
            gui.config.interpFactVal = 8;
        elseif gui.config.interpFact == 4
            gui.config.interpFactVal = 16;
        end
        set(h.pm_interpMap_GUI, 'Visible', 'on');
    else
        set(h.pm_interpMap_GUI, 'Visible', 'off');
    end
    
    gui.config.smoothBool = get(h.cb_smoothMap_GUI, 'Value');
    gui.config.smoothFactStr = get_value_popupmenu(h.pm_smoothMap_GUI, listSmooth);
    gui.config.smoothFact = get(h.pm_smoothMap_GUI, 'Value');
    if gui.config.smoothBool
        set(h.cb_errorMap_GUI, 'Visible', 'on');
        set(h.pm_smoothMap_GUI, 'Visible', 'on');
    else
        set(h.cb_errorMap_GUI, 'Visible', 'off');
        set(h.cb_errorMap_GUI, 'Value', 0);
        set(h.pm_smoothMap_GUI, 'Visible', 'off');
    end
    
    if isempty(get(h.value_MinVal_GUI, 'String'))
        gui.config.minVal = NaN;
    else
        gui.config.minVal = str2num(get(h.value_MinVal_GUI, 'String'));
    end
    if isempty(get(h.value_MaxVal_GUI, 'String'))
        gui.config.maxVal = NaN;
    else
        gui.config.maxVal = str2num(get(h.value_MaxVal_GUI, 'String'));
    end
    
    gui.config.normalizationStep = get(h.cb_normMap_GUI, 'Value');
    gui.config.normalizationStepVal = get(h.pm_normMap_GUI, 'Value');
    if gui.config.normalizationStep
        set(h.cb_autoColorbar_GUI, 'Value', 1);
        set(h.cb_transMap_GUI, 'Visible', 'off');
        set(h.value_transMap_GUI, 'Visible', 'off');
    else
        set(h.cb_transMap_GUI, 'Visible', 'on');
        set(h.value_transMap_GUI, 'Visible', 'on');
    end
    gui.config.translationStep = get(h.cb_transMap_GUI, 'Value');
    gui.config.translationStepVal = str2num(get(h.value_transMap_GUI, 'String'));
    if gui.config.translationStep
        set(h.value_transMap_GUI, 'Visible', 'on');
        set(h.unit_transMap_GUI, 'Visible', 'on');
        set(h.cb_normMap_GUI, 'Visible', 'off');
        set(h.pm_normMap_GUI, 'Visible', 'off');
    else
        set(h.value_transMap_GUI, 'Visible', 'off');
        set(h.unit_transMap_GUI, 'Visible', 'off');
        set(h.cb_normMap_GUI, 'Visible', 'on');
        set(h.pm_normMap_GUI, 'Visible', 'on');
    end
    if gui.config.normalizationStep
        set(h.pm_normMap_GUI, 'Visible', 'on');
    else
        set(h.pm_normMap_GUI, 'Visible', 'off');
    end
    gui.config.scaleAxis = get(h.cb_autoColorbar_GUI, 'Value');
    gui.config.cmin = str2num(get(h.value_colorMin_GUI, 'String'));
    gui.config.cmax = str2num(get(h.value_colorMax_GUI, 'String'));
    gui.config.intervalScaleBar = str2num(get(h.value_colorNum_GUI, 'String'));
    gui.config.logZ = get(h.cb_log_plot_GUI, 'Value');
    gui.config.grid = get(h.cb_grid_plot_GUI, 'Value');
    gui.config.Markers = get(h.cb_markers_GUI, 'Value');
    gui.config.MinMax = get(h.cb_MinMax_plot_GUI, 'Value');
    if ~strcmp(gui.config.MatlabRelease, '(R2014b)')
        gui.config.minorTicks = get(h.cb_tickColorBar_GUI, 'Value');
    else
        gui.config.minorTicks = 0;
    end
else
    gui.config.rawData = 1;
    gui.config.noNan = 1;
    gui.config.criterionBinMap_E = str2num(get(h.value_criterionE_GUI, 'string'));
    gui.config.criterionBinMap_H = str2num(get(h.value_criterionH_GUI, 'string'));
    gui.config.legendBinMap = 0;
    gui.config.legendStr = {'Ni', 'SiC'}; % {'Softest phase', 'Hardest phase'}
    gui.config.legendMatch = {'Match', 'No match'};
end

guidata(gcf, gui);

end