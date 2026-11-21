function test_binarization_figures
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(fullfile(root, 'matlab_code', 'gui'));
addpath(fullfile(root, 'matlab_code', 'module_binarization'));

mainWindow = figure('Visible', 'off');
otherWindow = figure('Visible', 'off');
unrelated = figure('Visible', 'off');
owned = TriDiMap_binFigure(mainWindow);
set(owned, 'Visible', 'off');
otherOwned = TriDiMap_binFigure(otherWindow);
set(otherOwned, 'Visible', 'off');
cleanup = onCleanup(@() closeTestFigures([mainWindow, otherWindow, unrelated, owned, otherOwned]));

TriDiMap_closeBinFigures(mainWindow);
assert(~ishandle(owned));
assert(ishandle(otherOwned) && ishandle(unrelated));
assert(ishandle(mainWindow) && ishandle(otherWindow));
TriDiMap_closeBinFigures(mainWindow);
disp('Binarization figure cleanup tests passed.');
end

function closeTestFigures(figures)
for i = 1:numel(figures)
    if ishandle(figures(i))
        close(figures(i));
    end
end
end
