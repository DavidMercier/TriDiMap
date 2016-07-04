%% Copyright 2014 MERCIER David
function TriDiMap_mapping_plotting(x_step, y_step, smoothVal, expValues, expProp, ...
    normStep, interpol, interpolFac, cmin, cmax, scaleAxis, TriDiView, FontSizeVal, ...
    Markers, binarizedGrid, varargin)
%% Function to plot a 3D map of elastic/plastic properties in function of X/Y coordinates
% x_step and y_step : Steps between indents in X and Y axis in microns.
% smooth : Number of points used to smooth respectively rows and columns (Nc and Nr)
% expValues : Values of experimental properties obtained by indentation in GPa.
% expProp : 1 = Elastic (Young's modulus) or 2 = Plastic (hardness) properties
% normStep : Boolean to set step of normalization (0 = no normalization and 1 = normalization)
% interpolFac : Interpolation factor to smooth data vizualization
% cmin and cmax: Limits of colorbar
% scaleAxis: Boolean to set colorbar
% TriDiView: Boolean to set plots
% FontSizeVal: Size of the font (legend, axes labels...)
% Markers: Boolean to plot markers
% binarizedGrid: Boolean to binarize values of the grid

if nargin < 15
    binarizedGrid = 1;
end

if nargin < 14
    Markers = 1;
end

if nargin < 13
    FontSizeVal = 14;
end

if nargin < 12
    TriDiView = 0;
end

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
    interpol = 1;
end

if nargin < 6
    normStep = 0;
end

if nargin < 5
    expProp = 1;
end

if nargin < 4
    %expValues = randi(101,101);
    expValues = peaks(51);
end

if nargin < 3
    smoothVal = 2;
end

if nargin < 2
    y_step = 12; % in microns
end

if nargin < 1
    x_step = 8; % in microns
end

%% Initialization of variables
maxPlots = 5;
h(1:maxPlots) = NaN;
hXLabel(1:maxPlots) = NaN;
hYLabel(1:maxPlots) = NaN;
hZLabel(1:maxPlots) = NaN;
hTitle(1:maxPlots) = NaN;

%% Interpolation - Definition of pixels coordinates
if ~interpol
    interpolFac = 0;
end
expValuesInterp = interp2(expValues,interpolFac);
maxValInterpol = max(max(expValuesInterp));
minValInterpol = min(min(expValuesInterp));
meanValInterpol = mean(mean(expValuesInterp));

%% Data smoothing
expValuesSmoothed = smooth2a(expValuesInterp, smoothVal, smoothVal);
maxValSmoothed = max(max(expValuesSmoothed));
minValSmoothed = min(min(expValuesSmoothed));
meanValSmoothed = mean(mean(expValuesSmoothed));

%% Correction of loss after smoothing step
deltaMax = (maxValInterpol - maxValSmoothed);
deltaMin = (minValInterpol - minValSmoothed);
expValuesInterpSmoothed = zeros(length(expValuesInterp));

for ii=1:length(expValuesInterp)
    for jj=1:length(expValuesInterp)
        if binarizedGrid == 0
            if expValuesInterp(ii,jj) < meanValInterpol
                expValuesInterpSmoothed(ii,jj) = ...
                    expValuesSmoothed(ii,jj) - ...
                    ((expValuesSmoothed(ii,jj) - expValuesInterp(ii,jj)) / ...
                    (expValuesInterp(ii,jj)/minValInterpol));
                
            elseif expValuesInterp(ii,jj) > meanValInterpol
                expValuesInterpSmoothed(ii,jj) = ...
                    expValuesSmoothed(ii,jj) + ...
                    ((expValuesInterp(ii,jj) - expValuesSmoothed(ii,jj)) * ...
                    (expValuesInterp(ii,jj)/maxValInterpol));
            else
                expValuesInterpSmoothed(ii,jj) = expValuesSmoothed(ii,jj);
            end
            
        elseif binarizedGrid == 1
            if expValuesInterp(ii,jj) < meanValInterpol
                expValuesInterpSmoothed(ii,jj) = ...
                    expValuesSmoothed(ii,jj) + deltaMin;
                
                %                 expValuesInterpSmoothed(ii,jj) = ...
                %                      expValuesSmoothed(ii,jj) + ...
                %                     (expValuesInterp(ii,jj) - expValuesSmoothed(ii,jj));
                % ==> Residual map equals zero
                
            elseif expValuesInterp(ii,jj) > meanValInterpol
                expValuesInterpSmoothed(ii,jj) = ...
                    expValuesSmoothed(ii,jj) + deltaMax;
                
            else
                expValuesInterpSmoothed(ii,jj) = expValuesSmoothed(ii,jj);
            end
            
        elseif binarizedGrid == 2
            if expValuesInterp(ii,jj) < meanValInterpol
                expValuesInterpSmoothed(ii,jj) = minValInterpol;
                
            elseif expValuesInterp(ii,jj) >= meanValInterpol
                expValuesInterpSmoothed(ii,jj) = maxValInterpol;
            end
        end
    end
end

%% Grid meshing
[xData_markers, yData_markers] = ...
    meshgrid(0:x_step:(size(expValues,1)-1)*x_step, ...
    0:y_step:(size(expValues,2)-1)*y_step);

[xData_interp, yData_interp] = ...
    meshgrid(0:x_step:(size(expValuesInterpSmoothed,1)-1)*x_step, ...
    0:y_step:(size(expValuesInterpSmoothed,2)-1)*y_step);

if interpol
    xData_interp = xData_interp./(2^(interpolFac));
    yData_interp = yData_interp./(2^(interpolFac));
end

%% Plots properties
scrsize = get(0, 'ScreenSize'); % Get screen size
WX = 0.15 * scrsize(3); % X Position (bottom)
WY = 0.10 * scrsize(4); % Y Position (left)
WW = 0.70 * scrsize(3); % Width
WH = 0.80 * scrsize(4); % Height

f(1) = figure('position', [WX, WY, WW, WH]);
colormap hsv;

if ~normStep
    if expProp == 1
        zString = 'Elastic modulus (GPa)';
    elseif expProp == 2
        zString = 'Hardness (GPa)';
    end
elseif normStep
    if expProp == 1
        zString = 'Normalized elastic modulus';
    elseif expProp == 2
        zString = 'Normalized hardness';
    end
end

%% 3 maps
if TriDiView
    %% Subplot 1
    subplot(2,2,1);
    
    % 3D plot
    h(1) = surf(xData_interp, yData_interp, expValuesInterpSmoothed',...
        'FaceColor','interp', 'EdgeColor','none',...
        'FaceLighting','gouraud');
    hold on;
    
    % To see point markers
    % plot3(xData_interp, yData_interp, expValues_interp', '.','MarkerSize',15)
    
    % Settings
    shading interp;
    axis tight;
    view(50,50);
    camlight left;
    
    hXLabel(1) = xlabel('X coordinates ($\mu$m)');
    hYLabel(1) = ylabel('Y coordinates ($\mu$m)');
    hZLabel(1) = zlabel(zString);
    hTitle(1) = title(['3D map of ', zString]);
    set([hXLabel(1), hYLabel(1), hZLabel(1), hTitle(1)], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    % Not working in a loop with handles of all labels... !
    
    colormap('jet');
    if scaleAxis
        caxis([cmin, cmax]);
    end
    hcb1 = colorbar;
    ylabel(hcb1, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
    % Latex for TickLabel not possible for Matlab2014a...
    % set(colorbar_handle,'TickLabelInterpreter', 'Latex');
    
    %% Subplot 2
    subplot(2,2,3);
    h(2) = surf(xData_interp, yData_interp, expValuesInterpSmoothed',...
        'FaceColor','interp',...
        'EdgeColor','none',...
        'FaceLighting','gouraud');
    
    axis equal;
    shading interp;
    view(0,90);
    
    hXLabel(2) = xlabel('X coordinates ($\mu$m)');
    hYLabel(2) = ylabel('Y coordinates ($\mu$m)');
    hZLabel(2) = zlabel(zString);
    hTitle(2) = title(['Mapping of ', zString]);
    set([hXLabel(2), hYLabel(2), hZLabel(2), hTitle(2)], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    
    colormap('jet');
    if scaleAxis
        caxis([cmin, cmax]);
    end
    hcb2 = colorbar;
    ylabel(hcb2, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
    %% Subplot 3
    subplot(2,2,[2 4]);
    
    % 3D plot
    h(3) = surf(xData_interp, yData_interp, expValuesInterpSmoothed',...
        'FaceColor','interp', 'EdgeColor','none',...
        'FaceLighting','gouraud');
    hold on;
    
    % 3D surface plot
    minZ = min(min(expValuesInterpSmoothed));
    maxZ = max(max(expValuesInterpSmoothed));
    Z_positionning = minZ - (maxZ - minZ)/2;
    
    hpcolor = pcolor(xData_interp, yData_interp, expValuesInterpSmoothed');
    set(hpcolor, 'ZData', Z_positionning + 0*expValuesInterpSmoothed);
    set(hpcolor, 'FaceColor', 'interp', 'EdgeColor', 'interp');
    hold off;
    
    % Settings
    shading interp;
    axis tight;
    view(30,15);
    camlight left;
    
    hXLabel(3) = xlabel('X coordinates ($\mu$m)');
    hYLabel(3) = ylabel('Y coordinates ($\mu$m)');
    hZLabel(3) = zlabel(zString);
    hTitle(3) = title(['3D map + surface plot of ', zString]);
    set([hXLabel(3), hYLabel(3), hZLabel(3), hTitle(3)], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    
    colormap('jet');
    if scaleAxis
        caxis([cmin, cmax]);
    end
    hcb3 = colorbar;
    ylabel(hcb3, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
else
    %% 1 map (with or without markers)
    h(4) = surf(xData_interp, yData_interp, expValuesInterpSmoothed',...
        'FaceColor','interp',...
        'EdgeColor','none',...
        'FaceLighting','gouraud');
    % 'Marker', '+'
    
    hold on;
    
    % Set z positions of markers
    markersVal = ones(length(expValues)) * maxValInterpol;
    
    if Markers
        plot3(xData_markers, yData_markers, markersVal,'k+');
        hold on;
    end
    
    hold off;
    
    axis equal;
    shading interp;
    view(0,90);
    
    hXLabel(4) = xlabel('X coordinates ($\mu$m)');
    hYLabel(4) = ylabel('Y coordinates ($\mu$m)');
    hZLabel(4) = zlabel(zString);
    hTitle(4) = title(['Mapping of ', zString]);
    set([hXLabel(4), hYLabel(4), hZLabel(4), hTitle(4)], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    
    colormap('jet');
    if scaleAxis
        caxis([cmin, cmax]);
    end
    hcb4 = colorbar;
    ylabel(hcb4, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
end

%% Plot residuals between interpolated data and smoothed data
residualsVal = (expValuesInterpSmoothed' - expValuesInterp'); %./expValuesInterp
zString = 'Residuals';

f(2) = figure;
h(5) = surf(xData_interp, yData_interp, residualsVal,...
    'FaceColor','interp',...
    'EdgeColor','none',...
    'FaceLighting','gouraud');

axis equal;
shading interp;
view(0,90);

hXLabel(5) = xlabel('X coordinates ($\mu$m)');
hYLabel(5) = ylabel('Y coordinates ($\mu$m)');
hZLabel(5) = zlabel(zString);
hTitle(5) = title(['Mapping of ', zString]);
set([hXLabel(5), hYLabel(5), hZLabel(5), hTitle(5)], ...
    'Color', [0,0,0], 'FontSize', FontSizeVal, ...
    'Interpreter', 'Latex');

colormap('jet');
if scaleAxis
    caxis([cmin, cmax]);
end
hcb5 = colorbar;
ylabel(hcb5, [zString, ' ($\%$)'], ...
    'Interpreter', 'Latex', ...
    'FontSize', FontSizeVal);

end