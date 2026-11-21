function [labels, thresholds, fractions] = TriDiMap_multiOtsu(image, phaseCount)
if ~isnumeric(image) || isempty(image) || ~isreal(image)
    error('TriDiMap:MultiPhaseImage', 'The SEM image must contain real grayscale or RGB values.');
end
if ndims(image) == 3 && size(image, 3) == 3
    image = 0.2989 * double(image(:, :, 1)) + ...
        0.5870 * double(image(:, :, 2)) + 0.1140 * double(image(:, :, 3));
elseif ~ismatrix(image)
    error('TriDiMap:MultiPhaseImage', 'The SEM image must be grayscale or RGB.');
else
    image = double(image);
end
if any(~isfinite(image(:)))
    error('TriDiMap:MultiPhaseImage', 'The SEM image must not contain nonfinite pixels.');
end
if ~isscalar(phaseCount) || phaseCount ~= fix(phaseCount) || ...
        phaseCount < 2 || phaseCount > 4
    error('TriDiMap:MultiPhaseImage', 'Choose 2, 3, or 4 SEM phases.');
end

minimum = min(image(:));
maximum = max(image(:));
if minimum == maximum
    error('TriDiMap:MultiPhaseImage', 'The SEM image has no grayscale contrast to segment.');
end
gray = round(255 * (image - minimum) / (maximum - minimum));
histogram = accumarray(gray(:) + 1, 1, [256, 1]);
if nnz(histogram) < phaseCount
    error('TriDiMap:MultiPhaseImage', ...
        'The SEM image has fewer distinct intensity levels than the requested phase count.');
end

x = (0:255)';
weightPrefix = [0; cumsum(histogram)];
meanPrefix = [0; cumsum(histogram .* x)];
secondMomentPrefix = [0; cumsum(histogram .* x.^2)];
cost = inf(256, 256);
for last = 1:256
    first = 1:last;
    weight = weightPrefix(last + 1) - weightPrefix(first);
    valid = weight > 0;
    sumValue = meanPrefix(last + 1) - meanPrefix(first);
    sumSquares = secondMomentPrefix(last + 1) - secondMomentPrefix(first);
    cost(first(valid), last) = ...
        sumSquares(valid) - sumValue(valid).^2 ./ weight(valid);
end

bestCost = inf(phaseCount, 256);
previousBin = zeros(phaseCount, 256);
bestCost(1, :) = cost(1, :);
for phase = 2:phaseCount
    for last = phase:256
        split = phase-1:last-1;
        candidate = bestCost(phase-1, split) + ...
            reshape(cost(split+1, last), 1, []);
        [minimumCost, selected] = min(candidate);
        bestCost(phase, last) = minimumCost;
        previousBin(phase, last) = split(selected);
    end
end

boundaries = zeros(phaseCount-1, 1);
last = 256;
for phase = phaseCount:-1:2
    boundaries(phase-1) = previousBin(phase, last);
    last = boundaries(phase-1);
end
thresholds = boundaries - 0.5;
labels = ones(size(gray));
for phase = 1:numel(thresholds)
    labels(gray > thresholds(phase)) = phase + 1;
end
fractions = accumarray(labels(:), 1, [phaseCount, 1]) / numel(labels);
end
