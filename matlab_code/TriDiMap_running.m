%% Copyright 2014 MERCIER David
function TriDiMap_running(normalizationStep, varargin)
%% Function to load 3D map of elastic/plastic properties from indentation tests

if nargin < 1
    normalizationStep = 1; % in microns
end

tridimMap_loading;

expValues_mat = reshape(expValues_vec,[5,10]);

%fliplr
%flipub
Hmat(:,10) = flipud(Hmat(:,10));
% faire toute les 2 colonnes...2,4,6,8,10 etc


% Normalization
if normalizationStep
    expValues_mat_average = mean(mean(expValues_mat));
    expValues_mat_norm = expValues_mat - expValues_mat_average;
    
    if normalizationStep
        tridim_mapping(x_step, y_step, expValues_mat_norm, 1, 1);
        tridim_mapping(x_step, y_step, expValues_mat_norm, 2, 1);
    else
        tridim_mapping(x_step, y_step, expValues_mat, 1, 0);
        tridim_mapping(x_step, y_step, expValues_mat, 2, 0);
    end
    
end