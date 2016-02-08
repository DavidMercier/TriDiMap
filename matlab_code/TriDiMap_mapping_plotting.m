%% Copyright 2014 MERCIER David
function TriDiMap_mapping_plotting(x_step, y_step, Nr, Nc, expValues, expProp, ...
    normStep, interpolFac, cmin, cmax, scaleAxis, varargin)
%% Function to plot a 3D map of elastic/plastic properties in function of X/Y coordinates
% x_step and y_step : Steps between indents in X and Y axis in microns.
% Nr and Nc : Number of points used to smooth respectively rows and columns
% expValues : Values of experimental properties obtained by indentation in GPa.
% expProp : 1 = Elastic (Young's modulus) or 2 = Plastic (hardness) properties
% normStep : Boolean to set step of normalization (0 = no normalization and 1 = normalization)
% interpolFac : Interpolation factor to smooth data vizualization
% cmin and cmax: Limits of colorbar
% scaleAxis: Boolean to set colorbar

if nargin < 11
    scaleAxis = 0;
end

if nargin < 10
    cmin = 0;
end

if nargin < 9
    cmax = 200;
end

if nargin < 8
    %interpolFac = 0; % for no interpolation
    interpolFac = 2;
end

if nargin < 7
    normStep = 0;
end

if nargin < 6
    expProp = 1;
end

if nargin < 5
    %expValues = randi(101,101);
    expValues = peaks(51);
end

if nargin < 4
    Nc = 2;
end

if nargin < 3
    Nr = 2;
end

if nargin < 2
    y_step = 12; % in microns
end

if nargin < 1
    x_step = 8; % in microns
end

%% Interpolation - Definition of pixels coordinates
expValues_interp = interp2(expValues,interpolFac);

%% Data smoothing
expValues_interp = smooth2a(expValues_interp, Nr, Nc);

%% Grid meshing
[xData_interp, yData_interp] = ...
    meshgrid(0:x_step:(size(expValues_interp,1)-1)*x_step, ...
    0:y_step:(size(expValues_interp,2)-1)*y_step);

if interpolFac
    xData_interp = xData_interp./(2^(interpolFac));
    yData_interp = yData_interp./(2^(interpolFac));
end

%% Plots
scrsize = get(0, 'ScreenSize'); % Get screen size
WX = 0.15 * scrsize(3); % X Position (bottom)
WY = 0.10 * scrsize(4); % Y Position (left)
WW = 0.70 * scrsize(3); % Width
WH = 0.80 * scrsize(4); % Height

figure('position', [WX, WY, WW, WH]);
colormap hsv;

% Axes properties
if ~normStep
    if expProp == 1
        zString = 'Young''s modulus (GPa)';
    elseif expProp == 2
        zString = 'Hardness (GPa)';
    end
elseif normStep
    if expProp == 1
        zString = 'Normalized Young''s modulus';
    elseif expProp == 2
        zString = 'Normalized Hardness';
    end
end

%% Subplot 1
subplot(2,2,1);

% 3D plot
h(1) = surf(xData_interp, yData_interp, expValues_interp',...
    'FaceColor','interp', 'EdgeColor','none',...
    'FaceLighting','gouraud');
hold on;

% Settings
shading interp;
axis tight;
view(50,50);
camlight left;

hXLabel_1 = xlabel('X coordinates ($\mu$m)');
hYLabel_1 = ylabel('Y coordinates ($\mu$m)');
hZLabel_1 = zlabel(zString);
hTitle_1 = title(['3D map of ', zString], 'FontSize', 18);

set([hXLabel_1, hYLabel_1, hZLabel_1, hTitle_1], ...
    'Color', [0,0,0], 'FontSize', 14, ...
    'Interpreter', 'Latex');

colormap('jet');
if scaleAxis
    caxis([cmin, cmax]);
end
hcb1 = colorbar;
ylabel(hcb1, zString, 'Interpreter', 'Latex');

% Latex for TickLabel not possible for Matlab2014a...
% set(colorbar_handle,'TickLabelInterpreter', 'Latex');

%% Subplot 2
subplot(2,2,3);
h(2) = surf(xData_interp, yData_interp, expValues_interp',...
    'FaceColor','interp',...
    'EdgeColor','none',...
    'FaceLighting','gouraud');

axis equal;
shading interp;
view(0,90);

hXLabel_2 = xlabel('X coordinates ($\mu$m)');
hYLabel_2 = ylabel('Y coordinates ($\mu$m)');
hZLabel_2 = zlabel(zString);
hTitle_2 = title(['Mapping of ', zString], 'FontSize', 18);

set([hXLabel_2, hYLabel_2, hZLabel_2, hTitle_2], ...
    'Color', [0,0,0], 'FontSize', 14, 'Interpreter', 'Latex');

colormap('jet');
if scaleAxis
    caxis([cmin, cmax]);
end
hcb2 = colorbar;
ylabel(hcb2, zString, 'Interpreter', 'Latex');

%% Subplot 3
subplot(2,2,[2 4]);

% 3D plot
h(3) = surf(xData_interp, yData_interp, expValues_interp',...
    'FaceColor','interp', 'EdgeColor','none',...
    'FaceLighting','gouraud');
hold on;

% 3D surface plot
minZ = min(min(expValues_interp));
maxZ = max(max(expValues_interp));
Z_positionning = minZ - (maxZ - minZ)/2;

h(4) = pcolor(xData_interp, yData_interp, expValues_interp');
set(h(4), 'ZData', Z_positionning + 0*expValues_interp);
set(h(4), 'FaceColor', 'interp', 'EdgeColor', 'interp');
hold off;

% Settings
shading interp;
axis tight;
view(30,15);
camlight left;

hXLabel_1 = xlabel('X coordinates ($\mu$m)');
hYLabel_1 = ylabel('Y coordinates ($\mu$m)');
hZLabel_1 = zlabel(zString);
hTitle_1 = title(['3D map + surface plot of ', zString], 'FontSize', 18);

set([hXLabel_1, hYLabel_1, hZLabel_1, hTitle_1], ...
    'Color', [0,0,0], 'FontSize', 14, ...
    'Interpreter', 'Latex');

colormap('jet'); 
if scaleAxis
    caxis([cmin, cmax]);
end
hcb3 = colorbar;
ylabel(hcb3, zString, 'Interpreter', 'Latex');

end