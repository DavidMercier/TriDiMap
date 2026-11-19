function test_irregular_data
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
paths = strsplit(originalPath, pathsep);
thirdPartyRoot = fullfile(root, 'third_party_codes');
path(strjoin(paths(~strncmp(paths, thirdPartyRoot, length(thirdPartyRoot))), pathsep));
addpath(fullfile(root, 'matlab_code', 'loading_data'));
example = fullfile(root, 'data_indentation', 'irregular_example.csv');
data = TriDiMap_readIrregularData(example);
assert(isequal(size(data.coordinates), [8, 2]));
assert(isequal(data.coordinates(1, :), [-2, 1]));
assert(max(abs(data.expValues.YM - (15 + 2*data.coordinates(:, 1) + 3*data.coordinates(:, 2)))) < 1e-12);
assert(isequal(data.expValues_mat, data.expValues));
file = [tempname, '.csv'];
cleanup = onCleanup(@() delete(file));
headers = {'X (um)', 'Y (um)', 'Modulus (GPa)', 'Hardness (GPa)'};
values = [0, 0, 100, 2; 0.3, 1.7, NaN, 3; -2, 4, 150, NaN];
writecell([headers; num2cell(values)], file);
missing = TriDiMap_readIrregularData(file);
assert(isequaln(missing.expValues.YM, values(:, 3)));
assert(isequaln(missing.expValues.H, values(:, 4)));
headers{3} = 'Reduced modulus (GPa)';
writecell([headers; num2cell(values)], file);
reduced = TriDiMap_readIrregularData(file);
assert(reduced.modulusIsReduced);
values(2, 1:2) = values(1, 1:2);
writecell([headers; num2cell(values)], file);
assertFailure(@() TriDiMap_readIrregularData(file), 'TriDiMap:DuplicateXY');
values(2, 1) = Inf;
writecell([headers; num2cell(values)], file);
assertFailure(@() TriDiMap_readIrregularData(file), 'TriDiMap:InvalidXYValues');
writecell({'X', 'Y', 'E', 'H'; 0, 0, 1, 2}, file);
assertFailure(@() TriDiMap_readIrregularData(file), 'TriDiMap:InvalidXYHeaders');
disp('Irregular XY import tests passed.');
end

function assertFailure(action, identifier)
try
    action();
catch exception
    assert(strcmp(exception.identifier, identifier), exception.message);
    return
end
error('TriDiMap:MissingError', 'Expected error %s.', identifier);
end
