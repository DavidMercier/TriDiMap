function [modulus, hardness] = TriDiMap_contactModel(depth, loadValue, stiffness, model, epsilon, alpha, tipDefect, beta, coefficients)
% Depth in nm, load in mN, stiffness in mN/nm; results in GPa.
if ~isnumeric(depth) || ~isnumeric(loadValue) || ~isnumeric(stiffness) || ...
        ~isequal(size(depth), size(loadValue), size(stiffness)) || isempty(depth) || ...
        ~isreal(depth) || ~isreal(loadValue) || ~isreal(stiffness) || ...
        any(~isfinite(depth(:))) || any(~isfinite(loadValue(:))) || ...
        any(~isfinite(stiffness(:))) || any(depth(:) <= 0) || ...
        any(loadValue(:) <= 0) || any(stiffness(:) <= 0)
    error('TriDiMap:InvalidMeasurements', ...
        'Depth, load and stiffness must be matching, finite, positive numeric arrays.');
end
if ~isscalar(epsilon) || ~isreal(epsilon) || ~isfinite(epsilon) || epsilon <= 0 || ...
        ~isscalar(alpha) || ~isreal(alpha) || ~isfinite(alpha) || alpha <= 0 || ...
        ~isscalar(tipDefect) || ~isreal(tipDefect) || ~isfinite(tipDefect) || tipDefect < 0 || ...
        ~isscalar(beta) || ~isreal(beta) || ~isfinite(beta) || beta <= 0 || ...
        ~isnumeric(coefficients) || ~isreal(coefficients) || isempty(coefficients) || ...
        ~isvector(coefficients) || numel(coefficients) > 9 || any(~isfinite(coefficients(:)))
    error('TriDiMap:InvalidCalibration', 'Invalid contact model or area calibration parameters.');
end

if strcmp(model, 'Oliver-Pharr')
    contactDepth = depth - epsilon .* loadValue ./ stiffness;
elseif strcmp(model, 'Loubet')
    contactDepth = alpha .* (depth - loadValue ./ stiffness + tipDefect);
else
    error('TriDiMap:InvalidModel', 'Select Oliver-Pharr or Loubet.');
end
if any(~isfinite(contactDepth(:))) || any(contactDepth(:) <= 0)
    error('TriDiMap:InvalidContactDepth', 'The calculated contact depth must be positive and finite for every indent.');
end

area = coefficients(1) .* contactDepth.^2;
for ii = 2:numel(coefficients)
    area = area + coefficients(ii) .* contactDepth.^(1 / 2^(ii-2));
end
if any(~isfinite(area(:))) || any(area(:) <= 0)
    error('TriDiMap:InvalidArea', 'The calibrated contact area must be positive and finite for every indent.');
end
hardness = 1e6 .* loadValue ./ area;
modulus = 1e6 .* sqrt(pi ./ area) .* stiffness ./ (2 * beta);
if any(~isfinite(hardness(:))) || any(~isfinite(modulus(:)))
    error('TriDiMap:InvalidResult', 'The calculated mechanical properties must be finite.');
end
end
