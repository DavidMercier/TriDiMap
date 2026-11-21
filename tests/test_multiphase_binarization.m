function test_multiphase_binarization
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(fullfile(root, 'matlab_code', 'module_binarization'));

for phaseCount = 3:4
    phaseSize = 12;
    image = zeros(phaseSize, phaseSize*phaseCount);
    property = zeros(size(image));
    for phase = 1:phaseCount
        columns = (phase-1)*phaseSize + (1:phaseSize);
        image(:, columns) = 20 + 70*(phase-1) + repmat([-2, 0, 2], phaseSize, 4);
        property(:, columns) = 10 + 20*(phase-1) + repmat([-1, 0, 1], phaseSize, 4);
    end

    [semLabels, semThresholds, fractions] = TriDiMap_multiOtsu(image, phaseCount);
    assert(numel(semThresholds) == phaseCount-1);
    assert(isequal(unique(semLabels), (1:phaseCount)'));
    assert(max(abs(fractions - 1/phaseCount)) < 0.02);

    [propertyLabels, propertyThresholds, propertyFractions] = ...
        TriDiMap_matchPhaseFractions(property, fractions);
    assert(numel(propertyThresholds) == phaseCount-1);
    assert(isequal(unique(propertyLabels), (1:phaseCount)'));
    assert(max(abs(propertyFractions - fractions)) < 0.02);
    [manualLabels, manualThresholds] = ...
        TriDiMap_matchPhaseFractions(property, fractions, propertyThresholds);
    assert(isequal(manualLabels, propertyLabels));
    assert(isequal(manualThresholds, propertyThresholds));

    [confusion, metrics, mismatch] = ...
        TriDiMap_comparePhases(semLabels, propertyLabels, phaseCount);
    counts = accumarray(semLabels(:), 1, [phaseCount, 1]);
    assert(isequal(confusion, diag(counts)));
    assert(metrics.accuracy == 1);
    assert(all(metrics.recall == 1) && all(metrics.iou == 1));
    assert(~any(mismatch(:)));

    rgbImage = repmat(image, [1, 1, 3]);
    rgbLabels = TriDiMap_multiOtsu(rgbImage, phaseCount);
    assert(isequal(rgbLabels, semLabels));
end

[~, ~, invalidMismatch] = TriDiMap_comparePhases([1, 2; 3, 0], ...
    [1, 3; NaN, 0], 3);
assert(invalidMismatch(1, 1) == 0);
assert(invalidMismatch(1, 2) == 1);
assert(isnan(invalidMismatch(2, 1)) && isnan(invalidMismatch(2, 2)));

try
    TriDiMap_matchPhaseFractions([1, 1, 2, 2], [0.25; 0.25; 0.5]);
    error('TriDiMap:MissingError', 'Expected rejection of an unsplittable phase map.');
catch exception
    assert(strcmp(exception.identifier, 'TriDiMap:MultiPhaseThresholds'));
end
disp('Multi-phase binarization tests passed.');
end
