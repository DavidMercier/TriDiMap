function make_synthetic_3phases
%% Generate a synthetic 3-phase nanoindentation map and SEM-like images
% Matrix (phase 1) with two kinds of embedded particles (phases 2 and 3).
% Outputs (overwritten on each run, deterministic):
%   data_indentation/Synthetic_3phases_25x25.xlsx  ('other' format, Results sheet)
%   data_indentation/Synthetic_3phases_25x25.csv   (X, Y, E, H, phase per indent)
%   data_image/Synthetic_3phases_25x25/SEM_raw_250x250.png
%   data_image/Synthetic_3phases_25x25/SEM_pixelated_25x25.png
% In the BINARIZATION GUI: file type 'other', 25 x 25 indents, load the
% spreadsheet and SEM_pixelated_25x25.png, then set K = 3.

imageFolder = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(imageFolder));
dataFolder = fullfile(root, 'data_indentation');
name = 'Synthetic_3phases_25x25';

% third_party_codes shadows table.m, used internally by writecell/writetable
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
entries = strsplit(originalPath, pathsep);
thirdParty = entries(contains(entries, 'third_party_codes'));
if ~isempty(thirdParty)
    rmpath(thirdParty{:});
end

nGrid = 25;
upscale = 10;
step = 2; % um between indents
nPixel = nGrid * upscale;

% Phase properties: matrix, particle type A, particle type B
E = [70, 200, 410];    % GPa
H = [1.2, 9, 28];      % GPa
grayLevel = [70, 145, 225]; % SEM grayscale levels

% Particles: [x_center, y_center, radius] in raw image pixels
particlesA = [70, 75, 42; 185, 190, 48];
particlesB = [190, 65, 32; 65, 185, 36];

[xPix, yPix] = meshgrid(1:nPixel, 1:nPixel);
phaseRaw = ones(nPixel);
for p = 1:size(particlesA, 1)
    phaseRaw(hypot(xPix-particlesA(p,1), yPix-particlesA(p,2)) <= particlesA(p,3)) = 2;
end
for p = 1:size(particlesB, 1)
    phaseRaw(hypot(xPix-particlesB(p,1), yPix-particlesB(p,2)) <= particlesB(p,3)) = 3;
end

rngState = rng;
restoreRng = onCleanup(@() rng(rngState));
rng(12, 'twister');

% SEM-like raw image with noise and slight blur at interfaces
semRaw = grayLevel(phaseRaw);
semRaw = conv2(padEdges(semRaw), ones(3) / 9, 'valid');
semRaw = uint8(min(max(semRaw + 8*randn(nPixel), 0), 255));

% Phase volume fraction under each indent (block of upscale x upscale pixels)
fractions = zeros(nGrid, nGrid, 3);
for k = 1:3
    fractions(:, :, k) = blockMean(double(phaseRaw == k), upscale);
end
semPixelated = uint8(round(blockMean(double(semRaw), upscale)));

% Indent properties: rule of mixtures plus 4 % measurement scatter
eImage = zeros(nGrid);
hImage = zeros(nGrid);
for k = 1:3
    eImage = eImage + fractions(:, :, k) * E(k);
    hImage = hImage + fractions(:, :, k) * H(k);
end
eImage = eImage .* (1 + 0.04*randn(nGrid));
hImage = hImage .* (1 + 0.04*randn(nGrid));
[~, phaseImage] = max(fractions, [], 3);

% TriDiMap compares the SEM image with rot90(map): store maps accordingly
eMap = rot90(eImage, -1);
hMap = rot90(hImage, -1);
phaseMap = rot90(phaseImage, -1);
[xMap, yMap] = ndgrid((0:nGrid-1)*step, (0:nGrid-1)*step);

% Serpentine indentation order: TriDiMap flips even columns on import
for column = 2:2:nGrid
    eMap(:, column) = flipud(eMap(:, column));
    hMap(:, column) = flipud(hMap(:, column));
    phaseMap(:, column) = flipud(phaseMap(:, column));
    xMap(:, column) = flipud(xMap(:, column));
    yMap(:, column) = flipud(yMap(:, column));
end
eFile = round(eMap(:), 2);
hFile = round(hMap(:), 3);

xlsxFile = fullfile(dataFolder, [name, '.xlsx']);
if exist(xlsxFile, 'file')
    delete(xlsxFile);
end
writecell([{'AvgModulus', 'AvgHardness'}; num2cell([eFile, hFile])], ...
    xlsxFile, 'Sheet', 'Results');

csvTable = table(xMap(:), yMap(:), eFile, hFile, phaseMap(:), ...
    'VariableNames', {'X_um', 'Y_um', 'E_GPa', 'H_GPa', 'Phase'});
writetable(csvTable, fullfile(dataFolder, [name, '.csv']));

imwrite(semRaw, fullfile(imageFolder, 'SEM_raw_250x250.png'));
imwrite(semPixelated, fullfile(imageFolder, 'SEM_pixelated_25x25.png'));

fprintf('Synthetic 3-phase dataset written (phase fractions: %s).\n', ...
    mat2str(accumarray(phaseImage(:), 1, [3, 1])' / nGrid^2, 3));
end

function out = blockMean(in, blockSize)
n = size(in, 1) / blockSize;
out = reshape(mean(mean(reshape(in, blockSize, n, blockSize, n), 1), 3), n, n);
end

function out = padEdges(in)
out = [in(1, 1), in(1, :), in(1, end); in(:, 1), in, in(:, end); ...
    in(end, 1), in(end, :), in(end, end)];
end
