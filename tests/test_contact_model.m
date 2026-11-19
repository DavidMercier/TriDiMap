function test_contact_model
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'matlab_code', 'module_mapping'));

depth = [100; 200];
loadValue = [1; 2];
stiffness = [0.05; 0.1];
beta = 1.034;
[modulus, hardness] = TriDiMap_contactModel(depth, loadValue, stiffness, ...
    'Oliver-Pharr', 0.75, 1.2, 0, beta, 24.56);
area = 24.56 .* [85; 185].^2;
assert(max(abs(hardness - 1e6 .* loadValue ./ area)) < 1e-10);
assert(max(abs(modulus - 1e6 .* sqrt(pi ./ area) .* stiffness ./ (2 * beta))) < 1e-10);
assert(abs(hardness(1) - 5.63551728413151) < 1e-10);
assert(abs(modulus(1) - 101.73287063255) < 1e-10);

[modulus, hardness] = TriDiMap_contactModel(depth, loadValue, stiffness, ...
    'Loubet', 0.75, 1.2, 5, beta, [24.56, 10, 2]);
hc = 1.2 .* [85; 185];
area = 24.56 .* hc.^2 + 10 .* hc + 2 .* sqrt(hc);
assert(max(abs(hardness - 1e6 .* loadValue ./ area)) < 1e-10);
assert(max(abs(modulus - 1e6 .* sqrt(pi ./ area) .* stiffness ./ (2 * beta))) < 1e-10);
assert(abs(hardness(1) - 3.89768667564586) < 1e-10);

assertFailure(@() TriDiMap_contactModel(100, 1, 0, 'Loubet', 0.75, 1.2, 0, beta, 24.56), 'TriDiMap:InvalidMeasurements');
assertFailure(@() TriDiMap_contactModel(10, 1, 0.05, 'Oliver-Pharr', 0.75, 1.2, 0, beta, 24.56), 'TriDiMap:InvalidContactDepth');
assertFailure(@() TriDiMap_contactModel(100, 1, 0.05, 'Loubet', 0.75, 1.2, 0, beta, -1), 'TriDiMap:InvalidArea');
assertFailure(@() TriDiMap_contactModel(100, 1, 0.05, 'other', 0.75, 1.2, 0, beta, 24.56), 'TriDiMap:InvalidModel');
assertFailure(@() TriDiMap_contactModel([100; 200], 1, 0.05, 'Loubet', 0.75, 1.2, 0, beta, 24.56), 'TriDiMap:InvalidMeasurements');
assertFailure(@() TriDiMap_contactModel(100, NaN, 0.05, 'Loubet', 0.75, 1.2, 0, beta, 24.56), 'TriDiMap:InvalidMeasurements');
assertFailure(@() TriDiMap_contactModel(100, 1, 0.05, 'Loubet', 0.75, 1.2, 0, beta, [24.56, NaN]), 'TriDiMap:InvalidCalibration');
disp('Contact model tests passed.');
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
