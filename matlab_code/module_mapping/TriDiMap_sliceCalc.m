%% Copyright 2014 MERCIER David
function TriDiMap_sliceCalc(gui)
%% Function for slices calculations

config = gui.config;

if config.SliceFlagData == 0
    TriDiMap_loadingAllTests;
end
gui = guidata(gcf);

if gui.config.SliceFlagData
    max_h = zeros(length(gui.slice_data),1);
    for ii = 1:length(gui.slice_data)
        %gui.slice_data(ii).data_h(isinf(gui.slice_data(ii).data_h)) = NaN;
        gui.slice_data(ii).data_h(gui.slice_data(ii).data_h > 1e6) = NaN;
        gui.slice_data(ii).data_L(gui.slice_data(ii).data_L > 1e6) = NaN;
        gui.slice_data(ii).data_E(gui.slice_data(ii).data_E > 1e6) = NaN;
        gui.slice_data(ii).data_H(gui.slice_data(ii).data_H > 1e6) = NaN;
        max_h(ii) = max(gui.slice_data(ii).data_h);
    end
    max_z = gui.config.sliceDepthMax;
    min_z = gui.config.sliceDepthMin;
    if max_z < min_z
        warning('Maximum final depth founded lower than minimum depth!');
        max_z = nanmaxn(max_h);
        if max_z < min_z
            warning('Maximum final depth founded lower than minimum depth!');
            max_z = nanmeann(max_h);
            if max_z < min_z
                warning('Mean final depth founded lower than minimum depth!');
                max_z = nanmin(max_h);
            end
        end
    end
    sliceNum = gui.config.sliceNum;
    IndSlice = struct();
    
    for ii = 1:length(gui.slice_data)
        IndSlice(1,ii).Val = find(gui.slice_data(ii).data_h > 0.95*min_z ...
            & gui.slice_data(ii).data_h < 1.05*min_z);
        for jj = 2:sliceNum-1
            IndSlice(jj,ii).Val = find(gui.slice_data(ii).data_h > ...
                (0.95*((jj-1)/(sliceNum-1))*(max_z-min_z))+min_z ...
                & gui.slice_data(ii).data_h < ...
                (1.05*((jj-1)/(sliceNum-1))*(max_z-min_z))+min_z);
        end
        IndSlice(sliceNum,ii).Val = find(gui.slice_data(ii).data_h > (0.95*max_z) ...
            & gui.slice_data(ii).data_h < 1.05*max_z);
    end
    
    slicePix = zeros(sliceNum,length(gui.slice_data));
    if config.property == 1
        
        for ii = 1:length(gui.slice_data)
            for jj = 1:sliceNum
                slicePix(jj,ii) = ...
                    nanmean(gui.slice_data(ii).data_E(IndSlice(jj,ii).Val));
            end
        end
    elseif config.property == 2
        for ii = 1:length(gui.slice_data)
            for jj = 1:sliceNum
                slicePix(jj,ii) = ...
                    nanmean(gui.slice_data(ii).data_H(IndSlice(jj,ii).Val));
            end
        end
    end
    
    % Reshape data matrices for each slice
    NX = config.N_XStep;
    NY = config.N_YStep;
    slice_data_mat = zeros(NX,NY,sliceNum);
    try
        for ii = 1:sliceNum
            slice_data_mat(:,:,ii) = reshape(slicePix(ii,:),[NX,NY]);
            % Flip even columns to respect nanoindentation pattern
            for evenIndex = 2:2:NY
                slice_data_mat(:,evenIndex,ii) = ...
                    flipud(slice_data_mat(:,evenIndex,ii));
            end
        end
        config.flagValid = 1;
    catch
        slice_data_mat = 0;
        errordlg('Wrong inputs for number of indents along X or/and Y axis !');
        config.flagValid = 0;
    end
    % Cleaning
    for ii = 1:sliceNum
        [slice_data_mat(:,:,ii), ratioNan(ii)] = ...
            TriDiMap_cleaningData(slice_data_mat(:,:,ii)); % Fill empty and NaN pixels
    end
    meanRatioNaN = mean(ratioNan(:));
    set(gui.handles.value_NaNratio_GUI, 'String', num2str(meanRatioNaN));
    gui.slice_data_mat.slice_data_mat = slice_data_mat;
    guidata(gcf, gui);
    % Cropping
    gui.slice_data_mat.Cropped = [];
    for ii = 1:sliceNum
        [gui.slice_data_mat.Cropped(:,:,ii), config.flagCrop] = ...
            TriDiMap_cropping(slice_data_mat(:,:,ii));
    end
    guidata(gcf, gui);
    % Interpolating, smoothing and binarizing steps of dataset
    gui.slice_data_mat.Interp = [];
    gui.slice_data_mat.Smoothed = [];
    gui.slice_data_mat.InterSmoothed = [];
    if config.noNan
        for ii = 1:sliceNum
            [gui.slice_data_mat.Interp(:,:,ii), ...
                gui.slice_data_mat.Smoothed(:,:,ii), ...
                gui.slice_data_mat.InterSmoothed(:,:,ii)] = ...
                TriDiMap_interpolation_smoothing(...
                gui.slice_data_mat.Cropped(:,:,ii), ...
                config.interpBool, config.interpFact, ...
                config.smoothBool, config.smoothFact);
        end
    else
        gui.slice_data_mat.Interp = gui.slice_data_mat.Cropped;
        gui.slice_data_mat.Smoothed = gui.slice_data_mat.Cropped;
        gui.slice_data_mat.InterSmoothed = gui.slice_data_mat.Cropped;
    end
    gui.data.data2plot = gui.slice_data_mat.InterSmoothed;
    guidata(gcf, gui);
    % Grid meshing
    TriDiMap_meshingGrid;
    gui = guidata(gcf);
    
    gui.config.legendSlice = strcat('Indentation depth (nm)');
    gui.config.sliceNum = sliceNum;
    guidata(gcf, gui);
    TriDiMap_plot;
    hold on;
    gui = guidata(gcf);
    guidata(gcf, gui);
else
    display('No slice data loaded!');
end

end
