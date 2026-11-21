function [confusion, metrics, mismatch] = ...
    TriDiMap_comparePhases(reference, prediction, phaseCount)
if ~ismatrix(reference) || ~ismatrix(prediction) || ...
        ~isequal(size(reference), size(prediction))
    error('TriDiMap:MultiPhaseCompare', 'SEM and property phase maps must have equal dimensions.');
end
valid = reference >= 1 & reference <= phaseCount & ...
    prediction >= 1 & prediction <= phaseCount;
if ~any(valid(:))
    error('TriDiMap:MultiPhaseCompare', 'The phase maps contain no comparable assigned pixels.');
end
confusion = accumarray([reference(valid), prediction(valid)], 1, ...
    [phaseCount, phaseCount]);
truePositive = diag(confusion);
referenceCount = sum(confusion, 2);
predictionCount = sum(confusion, 1)';
metrics.recall = truePositive ./ referenceCount;
metrics.precision = truePositive ./ predictionCount;
metrics.iou = truePositive ./ (referenceCount + predictionCount - truePositive);
metrics.accuracy = sum(truePositive) / sum(confusion(:));
mismatch = NaN(size(reference));
mismatch(valid) = prediction(valid) ~= reference(valid);
end
