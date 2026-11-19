function phases = TriDiMap_phaseDensity(points, labels)
validateattributes(points, {'numeric'}, {'real', '2d', 'size', [NaN, 2]});
validateattributes(labels, {'numeric'}, {'real', 'vector', 'numel', size(points, 1)});
labels = labels(:);
if any(~isfinite(labels) | labels < 0 | labels ~= fix(labels))
    error('TriDiMap:InvalidPhaseLabels', 'Phase labels must be nonnegative finite integers.');
end
points = double(points);
finite = all(isfinite(points), 2);
if any(~finite)
    warning('TriDiMap:NonfinitePhaseDensityPoints', ...
        'Excluding %d nonfinite E-H pairs from the joint density estimate.', sum(~finite));
end
if any(finite & labels == 0)
    warning('TriDiMap:UnassignedPhaseDensityPoints', ...
        'Excluding %d finite E-H pairs without a phase assignment.', sum(finite & labels == 0));
end
valid = finite & labels > 0;
total = sum(valid);
ids = unique(labels(valid));
phases = struct('id', {}, 'count', {}, 'weight', {}, 'mean', {}, ...
    'covariance', {}, 'H', {}, 'E', {}, 'pdf', {});
for ii = 1:numel(ids)
    cluster = points(valid & labels == ids(ii), :);
    count = size(cluster, 1);
    scales = std(cluster, 1, 1);
    if count < 3 || any(~isfinite(scales) | scales <= 0)
        warning('TriDiMap:DegeneratePhaseDensity', ...
            'Phase %d needs at least three non-collinear finite E-H pairs; its density is omitted.', ids(ii));
        continue
    end
    center = mean(cluster, 1);
    standardized = bsxfun(@rdivide, bsxfun(@minus, cluster, center), scales);
    correlation = cov(standardized, 1);
    [factor, status] = chol(correlation);
    if status ~= 0 || rcond(correlation) < 1e-12
        warning('TriDiMap:DegeneratePhaseDensity', ...
            'Phase %d has a singular or nearly singular covariance; its density is omitted.', ids(ii));
        continue
    end
    [h, e] = meshgrid(center(1) + scales(1)*linspace(-4, 4, 121), ...
        center(2) + scales(2)*linspace(-4, 4, 121));
    offsets = bsxfun(@rdivide, bsxfun(@minus, [h(:), e(:)], center), scales);
    whitened = offsets / factor;
    weight = count / total;
    logDensity = log(weight) - log(2*pi) - sum(log(scales)) - ...
        sum(log(diag(factor))) - 0.5*sum(whitened.^2, 2);
    density = reshape(exp(logDensity), size(h));
    if any(~isfinite(density(:)))
        error('TriDiMap:InvalidPhaseDensity', 'Phase %d has an unrepresentable probability density.', ids(ii));
    end
    phase = struct('id', ids(ii), 'count', count, 'weight', weight, 'mean', center, ...
        'covariance', diag(scales)*correlation*diag(scales), ...
        'H', h, 'E', e, 'pdf', density);
    phases(end+1) = phase;
end
if isempty(phases)
    error('TriDiMap:NoPhaseDensity', ...
        'No phase has enough non-collinear finite E-H pairs to estimate a joint Gaussian density.');
end
end
