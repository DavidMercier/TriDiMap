function data = TriDiMap_readIrregularData(filename)
[~, ~, raw] = TriDiMap_readMeanSheet(filename);
headers = {'X (um)', 'Y (um)', 'Modulus (GPa)', 'Hardness (GPa)'};
if size(raw, 2) == 4 && strcmp(raw{1, 3}, 'Reduced modulus (GPa)')
    headers{3} = 'Reduced modulus (GPa)';
end
if size(raw, 1) < 2 || size(raw, 2) ~= 4 || ~isequal(raw(1, :), headers)
    error('TriDiMap:InvalidXYHeaders', ...
        'Expected X (um), Y (um), Modulus (GPa), Hardness (GPa) in the first row.');
end
cells = raw(2:end, :);
if ~all(cellfun(@(v) isnumeric(v) && isreal(v) && isscalar(v), cells(:)))
    error('TriDiMap:InvalidXYValues', 'XY measurements must be numeric; use NaN for missing properties.');
end
values = cell2mat(cells);
if any(any(~isfinite(values(:, 1:2)))) || any(any(isinf(values(:, 3:4)))) || ...
        any(all(isnan(values(:, 3:4)), 1))
    error('TriDiMap:InvalidXYValues', ...
        'Coordinates must be finite and each property must contain finite measurements (or NaN, not Inf).');
end
if size(unique(values(:, 1:2), 'rows'), 1) ~= size(values, 1)
    error('TriDiMap:DuplicateXY', 'Each indent must have a unique XY coordinate pair.');
end
data.coordinates = values(:, 1:2);
data.expValues.YM = values(:, 3);
data.expValues.H = values(:, 4);
data.expValues_mat = data.expValues;
if strcmp(headers{3}, 'Reduced modulus (GPa)')
    data.modulusIsReduced = true;
end
end
