function test_slice_import
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'matlab_code', 'loading_data'));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
paths = strsplit(originalPath, pathsep);
thirdPartyRoot = fullfile(root, 'third_party_codes');
path(strjoin(paths(~strncmp(paths, thirdPartyRoot, length(thirdPartyRoot))), pathsep));

example = fullfile(root, 'data_indentation', 'MTS_example3_5x5_testSlice.xlsx');
[curves, sheets] = TriDiMap_readSliceWorkbook(example, 'END');
assert(numel(curves) == 25);
assert(strcmp(sheets{1}, 'Results'));
[first, ~] = xlsread(example, 'Test 002');
[last, ~] = xlsread(example, 'Test 025');
assert(isnan(curves(1).data_h));
assert(isequaln(curves(2).data_h, first(:, 1)));
assert(isequaln(curves(25).data_h, last(:, 1)));

filename = [tempname, '.xlsx'];
writecell({'Test', 'Value'; '1', 42}, filename, 'Sheet', 'Results');
cleanup = onCleanup(@() delete(filename));
header = {'Segment', 'Depth', 'Load', 'Time', 'Stiffness', 'Hardness', 'Modulus'; ...
    '', 'nm', 'mN', 's', 'N/m', 'GPa', 'GPa'};
writecell([header; {'Surface Marker', 20, 2, 0, 3, 4, 5}], ...
    filename, 'Sheet', 'Test 002');
writecell([header; {'Surface Marker', 10, 1, 0, 3, 4, 5}; ...
    {'END', [], [], [], [], [], []}], filename, 'Sheet', 'Test 001');
lastwarn('');
curves = TriDiMap_readSliceWorkbook(filename, 'END');
[~, warningId] = lastwarn;
assert(strcmp(warningId, 'TriDiMap:MissingSliceSegment'));
assert(numel(curves) == 2 && curves(1).data_h == 10 && isnan(curves(2).data_h));

writecell([header; {'Surface Marker', 40, 4, 0, 3, 4, 5}; ...
    {'END', [], [], [], [], [], []}], filename, 'Sheet', 'Test 004');
try
    TriDiMap_readSliceWorkbook(filename, 'END');
    error('TriDiMap:MissingError', 'A gap in test numbers must be rejected.');
catch exception
    assert(strcmp(exception.identifier, 'TriDiMap:InvalidSliceData'));
end
disp('Slice import tests passed.');
end
