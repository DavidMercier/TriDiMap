function test_readContactMeasurements
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
paths = strsplit(originalPath, pathsep);
thirdPartyRoot = fullfile(root, 'third_party_codes');
path(strjoin(paths(~strncmp(paths, thirdPartyRoot, length(thirdPartyRoot))), pathsep));
addpath(fullfile(root, 'matlab_code', 'loading_data'));
simpleFile = [tempname, '.xlsx'];
mtsFile = [tempname, '.xlsx'];
cleanup = onCleanup(@() deleteFixtures({simpleFile, mtsFile}));

writecell({'Depth (nm)', 'Load (mN)', 'Stiffness (mN/nm)'; ...
    100, 1, 0.05; 200, 2, 0.1}, simpleFile);
[measurements, groups] = TriDiMap_readContactMeasurements(simpleFile, 2);
assert(isequal(measurements, [100, 1, 0.05; 200, 2, 0.1]));
assert(isequal(groups, [1; 2]));
assertFailure(@() TriDiMap_readContactMeasurements(simpleFile, 3), 'TriDiMap:InvalidSpreadsheet');

summary = {'Test', 'Avg Modulus [75-85 nm]', 'Avg Hardness [75-85 nm]'; ...
    '', 'GPa', 'GPa'; '2', 100, 5; '1', 200, 6; 'Average', 150, 5.5};
curveHeaders = {'Displacement Into Surface', 'Load On Sample', 'Harmonic Contact Stiffness'; ...
    'nm', 'mN', 'N/m'};
writecell(summary, mtsFile, 'Sheet', 'Results');
writecell([curveHeaders; num2cell([70, 1, 4e4; 75, 1, 4e4; ...
    85, 2, 5e4; 90, 4, 7e4; 80, 99, 1e4])], mtsFile, 'Sheet', 'Test 001');
writecell([curveHeaders; num2cell([70, 1, 4e4; 75, 2, 5e4; ...
    85, 3, 6e4; 90, 4, 7e4; 80, 99, 1e4])], mtsFile, 'Sheet', 'Test 002 Tagged');
[measurements, groups] = TriDiMap_readContactMeasurements(mtsFile, 2);
expected = [75, 2, 0.05; 85, 3, 0.06; 75, 1, 0.04; 85, 2, 0.05];
assert(isequal(size(measurements), size(expected)));
assert(max(abs(measurements(:) - expected(:))) < 1e-12);
assert(isequal(groups, [1; 1; 2; 2]));

writecell({'Avg Hardness [76-86 nm]'}, mtsFile, 'Sheet', 'Results', 'Range', 'C1');
assertFailure(@() TriDiMap_readContactMeasurements(mtsFile, 2), 'TriDiMap:InvalidDepthRange');
writecell({'Avg Hardness [75-85 nm]'}, mtsFile, 'Sheet', 'Results', 'Range', 'C1');
writecell({'Avg Modulus [175-185 nm]', 'Avg Hardness [175-185 nm]'}, ...
    mtsFile, 'Sheet', 'Results', 'Range', 'B1');
assertFailure(@() TriDiMap_readContactMeasurements(mtsFile, 2), 'TriDiMap:InvalidCurve');
writecell({'Avg Modulus [75-85 nm]', 'Avg Hardness [75-85 nm]'}, ...
    mtsFile, 'Sheet', 'Results', 'Range', 'B1');
writecell({'mN/nm'}, mtsFile, 'Sheet', 'Test 002 Tagged', 'Range', 'C2');
assertFailure(@() TriDiMap_readContactMeasurements(mtsFile, 2), 'TriDiMap:InvalidCurveUnits');
writecell({'3'}, mtsFile, 'Sheet', 'Results', 'Range', 'A3');
assertFailure(@() TriDiMap_readContactMeasurements(mtsFile, 2), 'TriDiMap:MissingTestSheet');
writecell({'2'}, mtsFile, 'Sheet', 'Results', 'Range', 'A3');
writecell({NaN}, mtsFile, 'Sheet', 'Results', 'Range', 'C3');
lastwarn('');
[measurements, groups] = TriDiMap_readContactMeasurements(mtsFile, 2);
assert(isequal(groups, [2; 2]));
assert(max(abs(measurements(:) - reshape([75, 1, 0.04; 85, 2, 0.05], [], 1))) < 1e-12);
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'TriDiMap:ExcludedMTSMeasurements'));
writecell({NaN}, mtsFile, 'Sheet', 'Results', 'Range', 'C4');
assertFailure(@() TriDiMap_readContactMeasurements(mtsFile, 2), 'TriDiMap:NoValidMeasurements');
disp('Contact measurement import tests passed.');
end

function assertFailure(action, identifier)
try
    action();
catch exception
    assert(strcmp(exception.identifier, identifier));
    return
end
error('TriDiMap:MissingError', 'Expected error %s.', identifier);
end

function deleteFixtures(files)
for ii = 1:numel(files)
    if exist(files{ii}, 'file')
        delete(files{ii});
    end
end
end
