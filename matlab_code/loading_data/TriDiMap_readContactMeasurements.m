function [measurements, indentIndex] = TriDiMap_readContactMeasurements(filename, count)
[~, ~, raw] = TriDiMap_readMeanSheet(filename);
if isempty(raw)
    error('TriDiMap:InvalidSpreadsheet', 'The first worksheet is empty.');
end
headers = {'Depth (nm)', 'Load (mN)', 'Stiffness (mN/nm)'};
if size(raw, 2) == 3 && isequal(raw(1, :), headers)
    if size(raw, 1) ~= count + 1 || ...
            ~all(cellfun(@isNumericScalar, reshape(raw(2:end, :), [], 1)))
        error('TriDiMap:InvalidSpreadsheet', ...
            'Expected exactly %d numeric rows, in acquisition order.', count);
    end
    measurements = cell2mat(raw(2:end, :));
    indentIndex = (1:count)';
    return
end

labels = raw(1, :);
labels(~cellfun(@ischar, labels)) = {''};
testColumn = find(strcmp(labels, 'Test'));
modulusColumn = find(strncmp(labels, 'Avg Modulus [', 13));
hardnessColumn = find(strncmp(labels, 'Avg Hardness [', 14));
if size(raw, 1) < 3 || numel(testColumn) ~= 1 || ...
        numel(modulusColumn) ~= 1 || numel(hardnessColumn) ~= 1
    error('TriDiMap:InvalidSpreadsheet', ...
        ['Select an MTS workbook with Results and per-test curves, or a sheet with headers ' ...
        'Depth (nm), Load (mN), Stiffness (mN/nm) and %d numeric rows.'], count);
end
pattern = '\[([0-9.]+)-([0-9.]+) nm\]$';
depthRange = regexp(labels{modulusColumn}, pattern, 'tokens', 'once');
hardnessRange = regexp(labels{hardnessColumn}, pattern, 'tokens', 'once');
if isempty(depthRange) || ~isequal(depthRange, hardnessRange)
    error('TriDiMap:InvalidDepthRange', ...
        'MTS modulus and hardness must specify the same averaging depth range in nm.');
end
depthRange = cellfun(@str2double, depthRange);
if any(~isfinite(depthRange)) || depthRange(1) <= 0 || depthRange(2) <= depthRange(1)
    error('TriDiMap:InvalidDepthRange', 'The MTS averaging depth range is invalid.');
end

testIDs = NaN(size(raw, 1) - 2, 1);
for ii = 3:size(raw, 1)
    value = raw{ii, testColumn};
    if ischar(value)
        testIDs(ii - 2) = str2double(value);
    elseif isNumericScalar(value)
        testIDs(ii - 2) = value;
    end
end
testRows = find(~isnan(testIDs)) + 2;
testIDs = testIDs(~isnan(testIDs));
if numel(testIDs) ~= count || any(~isfinite(testIDs)) || ...
        any(testIDs <= 0 | testIDs ~= fix(testIDs)) || numel(unique(testIDs)) ~= count
    error('TriDiMap:InvalidSpreadsheet', ...
        'MTS Results must contain exactly %d distinct test IDs in acquisition order.', count);
end
summaryProperties = raw(testRows, [modulusColumn, hardnessColumn]);
validIndents = all(cellfun(@(value) isNumericScalar(value) && isfinite(value), summaryProperties), 2);
if ~any(validIndents)
    error('TriDiMap:NoValidMeasurements', 'MTS Results contains no valid modulus/hardness pairs.');
end
if exist('sheetnames', 'file') == 2
    sheets = cellstr(sheetnames(filename));
else
    [~, sheets] = xlsfinfo(filename);
end
sheetIDs = NaN(size(sheets));
for ii = 1:numel(sheets)
    token = regexp(sheets{ii}, '^Test (\d+)(?: Tagged)?$', 'tokens', 'once');
    if ~isempty(token)
        sheetIDs(ii) = str2double(token{1});
    end
end
sheetIndices = zeros(count, 1);
for ii = 1:count
    if ~validIndents(ii)
        continue
    end
    match = find(sheetIDs == testIDs(ii));
    if numel(match) ~= 1
        error('TriDiMap:MissingTestSheet', ...
            'Expected exactly one curve sheet for MTS test %d.', testIDs(ii));
    end
    sheetIndices(ii) = match;
end

progress = [];
if count > 10
    progress = waitbar(0, sprintf('Reading %d MTS curves (%g-%g nm)...', count, depthRange(1), depthRange(2)), ...
        'Name', 'Contact model measurements', ...
        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(progress, 'canceling', 0);
end
cleanup = onCleanup(@() closeProgress(progress));
samples = cell(count, 1);
groups = cell(count, 1);
for ii = 1:count
    if ~isempty(progress) && (~ishandle(progress) || getappdata(progress, 'canceling'))
        error('TriDiMap:Cancelled', 'Contact model import cancelled; the map was not changed.');
    end
    if ~validIndents(ii)
        continue
    end
    [~, ~, curve] = TriDiMap_readMeanSheet(filename, sheets{sheetIndices(ii)});
    curveLabels = curve(1, :);
    curveLabels(~cellfun(@ischar, curveLabels)) = {''};
    columnNames = {'Displacement Into Surface', 'Load On Sample', 'Harmonic Contact Stiffness'};
    columns = zeros(1, 3);
    for jj = 1:3
        match = find(strcmp(curveLabels, columnNames{jj}));
        if numel(match) ~= 1
            error('TriDiMap:InvalidCurve', ...
                'MTS test %d is missing a unique %s column.', testIDs(ii), columnNames{jj});
        end
        columns(jj) = match;
    end
    if ~isequal(curve(2, columns), {'nm', 'mN', 'N/m'})
        error('TriDiMap:InvalidCurveUnits', ...
            'MTS test %d must use nm, mN and N/m for depth, load and stiffness.', testIDs(ii));
    end
    values = curve(3:end, columns);
    if ~all(cellfun(@isNumericScalar, values(:)))
        error('TriDiMap:InvalidCurve', 'MTS test %d contains nonnumeric measurements.', testIDs(ii));
    end
    values = cell2mat(values);
    finiteDepth = isfinite(values(:, 1));
    if ~any(finiteDepth)
        error('TriDiMap:InvalidCurve', 'MTS test %d has no finite depth measurements.', testIDs(ii));
    end
    % Exclude unloading, even when it passes through the averaging interval.
    peakDepth = max(values(finiteDepth, 1));
    peakIndex = find(values(:, 1) == peakDepth, 1);
    values = values(1:peakIndex, :);
    selected = values(:, 1) >= depthRange(1) & values(:, 1) <= depthRange(2);
    if ~any(selected)
        error('TriDiMap:InvalidCurve', ...
            'MTS test %d has no loading measurements between %g and %g nm.', ...
            testIDs(ii), depthRange(1), depthRange(2));
    end
    samples{ii} = values(selected, :);
    samples{ii}(:, 3) = samples{ii}(:, 3) * 1e-6;
    groups{ii} = repmat(ii, size(samples{ii}, 1), 1);
    if ~isempty(progress) && (mod(ii, 10) == 0 || ii == count)
        waitbar(ii / count, progress);
        drawnow;
    end
end
measurements = vertcat(samples{:});
indentIndex = vertcat(groups{:});
if any(~validIndents)
    warning('TriDiMap:ExcludedMTSMeasurements', ...
        'Keeping %d invalid MTS indents as NaN, as already excluded in Results.', sum(~validIndents));
end
end

function result = isNumericScalar(value)
result = isnumeric(value) && isscalar(value) && isreal(value);
end

function closeProgress(progress)
if ~isempty(progress) && ishandle(progress)
    delete(progress);
end
end
