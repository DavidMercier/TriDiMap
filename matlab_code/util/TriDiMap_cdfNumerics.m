function [numerics, initialized] = TriDiMap_cdfNumerics(numerics)
if nargin < 1
    numerics = struct;
end
if ~isstruct(numerics) || ~isscalar(numerics)
    error('TriDiMap:CDFNumerics', 'CDF numerical settings must be a scalar structure.');
end
defaults = struct('TolFun_value', 1e-6, 'TolX_value', 1e-6, ...
    'MaxIter_value', 400, 'Min_mGaussian', -Inf, 'Max_mGaussian', Inf, ...
    'Min_mWeibull', eps, 'Max_mWeibull', Inf);
names = fieldnames(defaults);
initialized = {};
for ii = 1:numel(names)
    name = names{ii};
    if ~isfield(numerics, name) || isempty(numerics.(name))
        numerics.(name) = defaults.(name);
        initialized{end+1} = name;
    end
end
end
