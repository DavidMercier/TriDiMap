function [data, text, raw] = TriDiMap_readMeanSheet(filename, varargin)
if exist('readcell', 'file') ~= 2
    [data, text, raw] = xlsread(filename, varargin{:});
    return
end
if isempty(varargin)
    raw = readcell(filename);
else
    raw = readcell(filename, 'Sheet', varargin{1});
end

numericCells = cellfun(@(x) isnumeric(x) && isscalar(x), raw);
data = NaN(size(raw));
data(numericCells) = cell2mat(raw(numericCells));
numericRows = find(any(~isnan(data), 2));
numericColumns = find(any(~isnan(data), 1));
if isempty(numericRows)
    data = [];
else
    data = data(numericRows(1):numericRows(end), ...
        numericColumns(1):numericColumns(end));
end

text = raw;
text(~cellfun(@ischar, raw)) = {''};
textRows = find(any(~cellfun('isempty', text), 2));
textColumns = find(any(~cellfun('isempty', text), 1));
if isempty(textRows)
    text = {};
else
    text = text(textRows(1):textRows(end), textColumns(1):textColumns(end));
end
raw(cellfun(@(x) isa(x, 'missing'), raw)) = {NaN};
end
