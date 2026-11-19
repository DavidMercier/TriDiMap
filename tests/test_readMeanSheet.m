function test_readMeanSheet
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'matlab_code', 'loading_data'));
filename = [tempname, '.xlsx'];
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
paths = strsplit(originalPath, pathsep);
thirdPartyRoot = fullfile(root, 'third_party_codes');
% Legacy bundled utilities interfere with MATLAB's spreadsheet writer.
path(strjoin(paths(~strncmp(paths, thirdPartyRoot, length(thirdPartyRoot))), pathsep));
writecell({'Test', 'Avg Modulus', 'Avg Hardness'; ...
    '', 'GPa', 'GPa'; 'T1', 100, 5; 'T2', 200, NaN}, ...
    filename, 'Sheet', 'Results');
cleanup = onCleanup(@() delete(filename));
measurements = {'Depth (nm)', 'Load (mN)', 'Stiffness (mN/nm)'; ...
    100, 1, 0.05; 200, 2, 0.1};
writecell(measurements, filename, 'Sheet', 'Measurements');
clear restorePath
[data, text, raw] = TriDiMap_readMeanSheet(filename, 'Results');
assert(isequaln(data, [100, 5; 200, NaN]));
assert(isequal(text(1, :), {'Test', 'Avg Modulus', 'Avg Hardness'}));
assert(isempty(text{3, 2}));
assert(isequal(raw{3, 2}, 100));
assert(isnan(raw{4, 3}));
[firstSheet, ~, ~] = TriDiMap_readMeanSheet(filename);
assert(isequaln(firstSheet, data));
[~, ~, rawMeasurements] = TriDiMap_readMeanSheet(filename, 'Measurements');
assert(isequal(rawMeasurements, measurements));
try
    TriDiMap_readMeanSheet(filename, 'Absent');
catch
    disp('Mean-sheet reader tests passed.');
    return
end
error('TriDiMap:MissingError', 'A missing sheet must produce an import error.');
end
