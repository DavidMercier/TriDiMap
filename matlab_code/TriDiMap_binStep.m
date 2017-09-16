%% Copyright 2014 MERCIER David
function [data_binarized, fractionMin, fractionMax] = ...
    TriDiMap_binStep(data2use, plotMatch, iProp)
%% Function to run the binarization
gui = guidata(gcf);
config = gui.config;

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

guidata(gcf, gui);

end