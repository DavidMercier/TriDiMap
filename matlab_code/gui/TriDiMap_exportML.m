function TriDiMap_exportML(filename)
gui = guidata(gcf);
if ~isfield(gui, 'ml') || ~strcmp(get(gui.handles.pb_mlExport_GUI, 'Enable'), 'on')
    errordlg('Plot valid ML clusters before exporting.', 'ML export');
    return
end
if nargin < 1
    [name, folder] = uiputfile('*.csv', 'Export ML clustering', 'tridimap_ml.csv');
    if isequal(name, 0)
        return
    end
    filename = fullfile(folder, name);
end
fid = fopen(filename, 'w');
if fid == -1
    error('TriDiMap:MLExport', 'Cannot open %s for writing.', filename);
end
cleanup = onCleanup(@() fclose(fid));
names = {'KAMM', 'KAEM', 'KAPM', 'KAMM_RATIO', 'KAMM_NORMPROD'};
values = [gui.ml.coordinates, gui.ml.key.H(:), gui.ml.key.E(:), gui.ml.result.labels(:)];
header = sprintf('X (%s),Y (%s),H (GPa),E (GPa),Phase', ...
    char(gui.config.strUnit_Length), char(gui.config.strUnit_Length));
if isfield(gui.ml.key, 'inputSource') && strcmp(gui.ml.key.inputSource, 'processed')
    header = strrep(header, '(GPa)', '(GPa; processed)');
    header = [header, ' (processed pixels)'];
end
for ii = 1:numel(names)
    if isfield(gui.ml.result.maps, names{ii})
        map = gui.ml.result.maps.(names{ii});
        values(:, end+1) = map(:);
        header = [header, ',', names{ii}];
    end
end
if ~isempty(gui.ml.result.embedding)
    embedding = NaN(numel(gui.ml.result.labels), 2);
    embedding(gui.ml.result.valid(:), :) = gui.ml.result.embedding;
    values = [values, embedding];
    header = [header, ',ISOMAP1,ISOMAP2'];
end
if isfield(gui.ml.result, 'somModel') && ~isempty(gui.ml.result.somModel)
    somCoordinates = NaN(numel(gui.ml.result.labels), 2);
    somCoordinates(gui.ml.result.valid(:), :) = ...
        gui.ml.result.somModel.positions(gui.ml.result.somModel.bmu, :);
    values = [values, somCoordinates];
    header = [header, ',SOM_column,SOM_row'];
end
fprintf(fid, '%s\n', header);
fprintf(fid, [repmat('%.17g,', 1, size(values, 2)-1), '%.17g\n'], values');
end
