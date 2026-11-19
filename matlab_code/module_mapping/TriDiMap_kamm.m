function maps = TriDiMap_kamm(E, H, order)
validateattributes(E, {'numeric'}, {'real', 'nonempty', '2d'});
validateattributes(H, {'numeric'}, {'real', 'size', size(E)});
if ~isscalar(order) || ~ismember(order, [1, 2])
    error('TriDiMap:MLInput', 'KAMM order must be 1 or 2.');
end
E = double(E);
H = double(H);
valid = isfinite(E) & isfinite(H) & E > 0 & H > 0;
if any(~valid(:))
    warning('TriDiMap:KAMMInvalidPairs', ...
        'Leaving %d nonfinite/nonpositive E-H positions unassigned.', sum(~valid(:)));
end
if ~any(valid(:))
    error('TriDiMap:MLInput', 'KAMM requires positive finite E-H pairs.');
end
if any(~isfinite(E(valid).*H(valid)))
    error('TriDiMap:MLInput', 'E*H overflows; check the input values and GPa units.');
end
scaleE = max(std(E(valid), 1), 1e-12);
scaleH = max(std(H(valid), 1), 1e-12);
names = {'KAMM', 'KAEM', 'KAPM', 'KAMM_RATIO', 'KAMM_NORMPROD'};
totals = zeros([size(E), 5]);
count = double(valid); % The supplied KAMM definition includes the centre.
for di = -order:order
    for dj = -order:order
        if abs(di) + abs(dj) ~= order
            continue
        end
        rows = max(1, 1-di):min(size(E, 1), size(E, 1)-di);
        cols = max(1, 1-dj):min(size(E, 2), size(E, 2)-dj);
        pair = valid(rows, cols) & valid(rows+di, cols+dj);
        deltaE = E(rows, cols) - E(rows+di, cols+dj);
        deltaH = H(rows, cols) - H(rows+di, cols+dj);
        values = cat(3, abs(E(rows, cols).*H(rows, cols) - E(rows+di, cols+dj).*H(rows+di, cols+dj)), ...
            abs(deltaE), abs(deltaH), abs(deltaE./(deltaH + 1e-6)), ...
            (deltaE/scaleE).*(deltaH/scaleH));
        values(repmat(~pair, [1, 1, 5])) = 0;
        totals(rows, cols, :) = totals(rows, cols, :) + values;
        count(rows, cols) = count(rows, cols) + pair;
    end
end
for ii = 1:numel(names)
    map = totals(:, :, ii)./count;
    map(~valid) = NaN;
    maps.(names{ii}) = map;
end
maps.neighbourCount = count;
end
