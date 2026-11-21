function TriDiMap_closeBinFigures(mainWindow)
figures = findall(0, 'Type', 'figure');
for i = 1:numel(figures)
    if isappdata(figures(i), 'TriDiMapBinarizationOwner') && ...
            isequal(getappdata(figures(i), 'TriDiMapBinarizationOwner'), mainWindow)
        close(figures(i));
    end
end
end
