function test_java_icon_tridimap
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'matlab_code', 'util'));
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
java_icon_tridimap(fig);
assert(ishandle(fig));
disp('Figure icon compatibility test passed.');
end
