function [labels, thresholds, fractions] = ...
    TriDiMap_matchPhaseFractions(data, targetFractions, requestedThresholds)
if nargin < 3
    requestedThresholds = [];
end
targetFractions = targetFractions(:);
phaseCount = numel(targetFractions);
if ~isnumeric(data) || ~isreal(data) || isempty(data) || ...
        any(~isfinite(targetFractions)) || any(targetFractions <= 0) || ...
        abs(sum(targetFractions)-1) > 1e-8
    error('TriDiMap:MultiPhaseThresholds', 'Invalid map data or SEM phase fractions.');
end

valid = isfinite(data);
values = data(valid);
[uniqueValues, ~, indices] = unique(values);
if numel(uniqueValues) < phaseCount
    error('TriDiMap:MultiPhaseThresholds', ...
        'The property map does not contain enough distinct values to separate all SEM phases.');
end
valueCounts = accumarray(indices, 1);
cumulativeFractions = cumsum(valueCounts) / numel(values);

if isempty(requestedThresholds)
    thresholds = zeros(phaseCount-1, 1);
    previousCut = 0;
    for phase = 1:phaseCount-1
        minimumCut = previousCut + 1;
        maximumCut = numel(uniqueValues) - (phaseCount - phase);
        candidates = minimumCut:maximumCut;
        target = sum(targetFractions(1:phase));
        deviations = abs(cumulativeFractions(candidates) - target);
        nearTarget = deviations <= 0.05;
        if any(nearTarget)
            candidates = candidates(nearTarget);
            deviations = deviations(nearTarget);
        else
            warning('TriDiMap:PhaseRatioMismatch', ...
                'No E/H threshold can match phase %d within 5%% of its SEM fraction.', phase);
        end
        valleyDensity = valueCounts(candidates) + valueCounts(candidates + 1);
        score = deviations / 0.05 + valleyDensity / numel(values);
        [~, selected] = min(score);
        previousCut = candidates(selected);
        lower = uniqueValues(previousCut);
        upper = uniqueValues(previousCut + 1);
        thresholds(phase) = lower + (upper - lower) / 2;
    end
else
    thresholds = requestedThresholds(:);
    if numel(thresholds) ~= phaseCount-1 || any(~isfinite(thresholds)) || ...
            any(diff(thresholds) <= 0)
        error('TriDiMap:MultiPhaseThresholds', ...
            'Enter exactly K-1 finite, strictly increasing property thresholds.');
    end
end

labels = zeros(size(data));
labels(valid) = 1;
for phase = 1:numel(thresholds)
    labels(valid & data > thresholds(phase)) = phase + 1;
end
fractions = accumarray(labels(valid), 1, [phaseCount, 1]) / sum(valid(:));
if any(fractions == 0)
    error('TriDiMap:MultiPhaseThresholds', ...
        'The chosen thresholds leave at least one phase empty.');
end
if any(abs(fractions-targetFractions) > 0.05)
    warning('TriDiMap:PhaseRatioMismatch', ...
        'Property-map phase fractions differ from the SEM fractions by more than 5%%.');
end
end
