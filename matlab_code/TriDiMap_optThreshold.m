%% Copyright 2014 MERCIER David
function TriDiMap_optThreshold
%% Function to optimize threshold for binarized images

g = guidata(gcf);

for iProp = 1:2
    if iProp == 1
        data2use = g.data.expValues_mat.YM;
        g.config.criterionBinMap_E = 0;
    elseif iProp == 2
        data2use = g.data.expValues_mat.H;
        g.config.criterionBinMap_H = 0;
    end
    
    % Initialization of ratios values
    fMinProp = 0;
    fMinIma = 1;
    
    while fMinProp/fMinIma < 1
        
        guidata(gcf, g);
        
        % Get phase ratios from the properties maps
        [dataBin, fMinProp, fMaxProp] = ...
            TriDiMap_binStep(data2use, 1, iProp);
        
        % Get phase ratio of the binarized image
        indI = find(g.image.image2use == 0);
        fMinIma = length(indI)/(length(g.image.image2use)^2);
        
        if fMinProp < fMinIma
            if iProp == 1
                g.config.criterionBinMap_E = g.config.criterionBinMap_E + ...
                    max(max(data2use))/1000;
            elseif iProp == 2
                g.config.criterionBinMap_H = g.config.criterionBinMap_H + ...
                    max(max(data2use))/1000;
            end
        end
    end
end

guidata(gcf, g);
set(g.handles.value_criterionE_GUI, 'String', ...
    num2str(g.config.criterionBinMap_E));
set(g.handles.value_criterionH_GUI, 'String', ...
    num2str(g.config.criterionBinMap_H));

TriDiMap_runBin;

end