%% Copyright 2014 MERCIER David
function [sliceData, sheets] = TriDiMap_readSliceWorkbook(filename, endSegment)
% Read curves in indentation order; retain missing curves as NaN positions.
if exist('sheetnames', 'file') == 2
    sheets = cellstr(sheetnames(filename));
else
    [status, sheets] = xlsfinfo(filename);
    if isempty(status)
        error('TriDiMap:InvalidSliceData', 'The spreadsheet has no readable sheets.');
    end
end
if isempty(sheets)
    error('TriDiMap:InvalidSliceData', 'The spreadsheet has no readable sheets.');
end

rawData = cell(numel(sheets), 1);
textData = cell(numel(sheets), 1);
isTest = false(numel(sheets), 1);
segments = {};
if nargin < 2
    progress = waitbar(0, 'Reading indentation sheets...');
    closeProgress = onCleanup(@() delete(progress));
end
for ii = 1:numel(sheets)
    if nargin < 2
        waitbar(ii / numel(sheets), progress);
    end
    [rawData{ii}, textData{ii}] = TriDiMap_readMeanSheet(filename, sheets{ii});
    txt = textData{ii};
    hasHeader = ~isempty(txt) && ...
        any(strcmpi(txt(1:min(2, size(txt, 1)), 1), 'Segment'));
    isTest(ii) = hasHeader || ~isempty(regexpi(sheets{ii}, '^Test\s+\d+(\s+.*)?$', 'once'));
    if hasHeader && isempty(segments)
        column = txt(:, 1);
        segments = column(~cellfun('isempty', column) & ~strcmpi(column, 'Segment'));
    end
end
if nargin < 2
    clear closeProgress
end
if isempty(segments) || ~any(isTest)
    error('TriDiMap:InvalidSliceData', 'No indentation segment was found in the spreadsheet.');
end

sliceData = [];
if nargin < 2
    [selection, accepted] = listdlg('PromptString', 'Select an end segment:', ...
        'SelectionMode', 'single', 'ListString', segments);
    if ~accepted
        return
    end
    endSegment = segments{selection};
end

indices = find(isTest);
testNumbers = NaN(size(indices));
for ii = 1:numel(indices)
    token = regexpi(sheets{indices(ii)}, '^Test\s+(\d+)(\s+.*)?$', 'tokens', 'once');
    if ~isempty(token)
        testNumbers(ii) = str2double(token{1});
    end
end
if all(~isnan(testNumbers))
    [sortedNumbers, order] = sort(testNumbers);
    if ~isequal(sortedNumbers(:), (1:numel(indices))')
        error('TriDiMap:InvalidSliceData', ...
            'Numbered test sheets must contain each test from 1 without gaps or duplicates.');
    end
    indices = indices(order);
end

emptyCurve = struct('data_h', NaN, 'data_L', NaN, 'data_H', NaN, 'data_E', NaN);
sliceData = repmat(emptyCurve, 1, numel(indices));
missing = {};
for ii = 1:numel(indices)
    sheetIndex = indices(ii);
    txt = textData{sheetIndex};
    numeric = rawData{sheetIndex};
    marker = [];
    if ~isempty(txt)
        marker = find(strcmp(txt(:, 1), endSegment), 1);
    end
    lastRow = marker - 2 - strcmp(endSegment, 'END');
    if isempty(lastRow) || lastRow < 1 || isempty(numeric) || size(numeric, 2) < 6
        missing{end+1} = sheets{sheetIndex}; %#ok<AGROW>
        continue
    end
    lastRow = min(lastRow, size(numeric, 1));
    sliceData(ii).data_h = numeric(1:lastRow, 1);
    sliceData(ii).data_L = numeric(1:lastRow, 2);
    sliceData(ii).data_H = numeric(1:lastRow, 5);
    sliceData(ii).data_E = numeric(1:lastRow, 6);
end
if numel(missing) == numel(indices)
    error('TriDiMap:InvalidSliceData', 'The selected segment has no usable indentation curves.');
end
if ~isempty(missing)
    warning('TriDiMap:MissingSliceSegment', ...
        'Missing or invalid segment "%s" in sheets: %s. Their grid positions remain NaN.', ...
        endSegment, strjoin(missing, ', '));
end
end
