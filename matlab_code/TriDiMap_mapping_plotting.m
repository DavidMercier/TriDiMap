%% Copyright 2014 MERCIER David
function TriDiMap_mapping_plotting(xData_interp, yData_interp, ...
    expValuesInterpSmoothed, expProp, normStep, cmin, cmax, ...
    scaleAxis, TriDiView, FontSizeVal, Markers, xData_markers, yData_markers, ...
    expValues, expValuesInterp, intervalScaleBar, rawData, contourPlot, ...
    legendStr, varargin)
%% Function to plot a 3D map of material properties in function of X/Y coordinates
% 1) et 2) xData_interp and yData_interp: Interpolated x and y values
% 3) expValuesInterpSmoothed: Interpolated and smoothed z values
% 4) expProp: 1 = Elastic (Young's modulus) or 2 = Plastic (hardness) properties
% 5) normStep: Variable to set step of normalization
% 6) et 7) cmin and cmax: Limits of colorbar
% 8) scaleAxis: Boolean to set colorbar
% 9) TriDiView: Boolean to set plots
% 10) FontSizeVal: Size of the font (legend, axes labels...)
% 11) Markers: Boolean to plot markers
% 12) xData_markers and yData_markers: Coordinates of markers
% 13) expValues: Raw dataset
% 14) intervalScaleBar: Number of interval on the scale bar
% 15) rawData: Boolean to plot raw dataset (no interpolation, no smoothing...)
% 16) contourPlot: Boolean to plot contour
% 17) legendStr: Strings for legend

if nargin < 17
    legendStr = {'Phase1' , 'Phase2'};
end

if nargin < 16
    rawData = 0;
end

if nargin < 15
    intervalScaleBar = 10;
end

if nargin < 14
    %expValues = randi(101,101);
    expValues = peaks(51);
end

if nargin < 13
    yData_markers = 1;
end

if nargin < 12
    xData_markers = 1;
end

if nargin < 11
    Markers = 1;
end

if nargin < 10
    FontSizeVal = 14;
end

if nargin < 9
    TriDiView = 0;
end

if nargin < 8
    scaleAxis = 0;
end

if nargin < 7
    cmax = 0;
end

if nargin < 6
    cmin = 200;
end

if nargin < 5
    normStep = 0;
end

if nargin < 4
    expProp = 1;
end

if nargin < 3
    %expValuesInterpSmoothed =
end

if nargin < 2
    %yData_interp =
end

if nargin < 1
    %xData_interp =
end

%% Initialization of variables
maxPlots = 5;
h(1:maxPlots) = NaN;
hXLabel(1:maxPlots) = NaN;
hYLabel(1:maxPlots) = NaN;
hZLabel(1:maxPlots) = NaN;
hTitle(1:maxPlots) = NaN;

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
elseif normStep > 0
    if normStep == 1
        if expProp == 1
            zString = 'Normalized elastic modulus by minimum elastic modulus value';
        elseif expProp == 2
            zString = 'Normalized hardness by minimum hardness value';
        end
    elseif normStep == 2
        if expProp == 1
            zString = 'Normalized elastic modulus by maximum elastic modulus value';
        elseif expProp == 2
            zString = 'Normalized hardness by maximum hardness value';
        end
    elseif normStep == 3
        if expProp == 1
            zString = 'Normalized elastic modulus by mean elastic modulus value';
        elseif expProp == 2
            zString = 'Normalized hardness by mean hardness value';
        end
    end
    
end

%% 3 maps
if TriDiView
    %% Subplot 1
    subplot(2,2,1);
    
    % 3D plot
    if ~rawData
        h(1) = surf(xData_interp, yData_interp, expValuesInterpSmoothed',...
            'FaceColor','interp', 'EdgeColor','none',...
            'FaceLighting','gouraud');
        shading interp;
        hold on;
    else
        h(1) = imagesc(expValuesInterpSmoothed',...
            'XData',xData_interp,'YData',yData_interp);
        set(gca,'YDir','normal');
    end
    
    % To see point markers
    % plot3(xData_interp, yData_interp, expValues_interp', '.','MarkerSize',15)
    
    % Setting
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
    
    if intervalScaleBar > 0
        if ~rawData
            colormap(['jet(',num2str(intervalScaleBar),')']);
        else
            colormap([1,1,1;0,0,0]); % Black and white
        end
    else
        colormap('jet');
        % Use flipud to reverse colormap
    end
    if scaleAxis
        caxis([cmin, cmax]);
    end
    hcb1 = colorbar;
    ylabel(hcb1, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
    % Latex for TickLabel not possible for Matlab2014a...
    % set(colorbar_handle,'TickLabelInterpreter', 'Latex');
    
    %% Subplot 2
    subplot(2,2,3);
    if ~rawData
        h(2) = surf(xData_interp, yData_interp, expValuesInterpSmoothed',...
            'FaceColor','interp',...
            'EdgeColor','none',...
            'FaceLighting','gouraud');
        shading interp;
    else
        h(2) = imagesc(expValuesInterpSmoothed',...
            'XData',xData_interp,'YData',yData_interp);
        set(gca,'YDir','normal');
    end
    
    axis equal;
    axis tight;
    view(0,90);
    
    hXLabel(2) = xlabel('X coordinates ($\mu$m)');
    hYLabel(2) = ylabel('Y coordinates ($\mu$m)');
    hZLabel(2) = zlabel(zString);
    hTitle(2) = title(['Mapping of ', zString]);
    set([hXLabel(2), hYLabel(2), hZLabel(2), hTitle(2)], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    
    if intervalScaleBar > 0
        if ~rawData
            colormap(['jet(',num2str(intervalScaleBar),')']);
        else
            colormap([1,1,1;0,0,0]); % Black and white
        end
    else
        colormap('jet');
        % Use flipud to reverse colormap
    end
    if scaleAxis
        caxis([cmin, cmax]);
    end
    hcb2 = colorbar;
    ylabel(hcb2, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
    %% Subplot 3
    subplot(2,2,[2 4]);
    
    % 3D plot
    if ~rawData
        h(3) = surf(xData_interp, yData_interp, expValuesInterpSmoothed',...
            'FaceColor','interp', 'EdgeColor','none',...
            'FaceLighting','gouraud');
        shading interp;
        hold on;
    else
        h(3) = imagesc(expValuesInterpSmoothed',...
            'XData',xData_interp,'YData',yData_interp);
        set(gca,'YDir','normal');
    end
    
    % 3D surface plot
    minZ = min(min(expValuesInterpSmoothed));
    maxZ = max(max(expValuesInterpSmoothed));
    Z_positionning = minZ - (maxZ - minZ)/2;
    
    hpcolor = pcolor(xData_interp, yData_interp, expValuesInterpSmoothed');
    set(hpcolor, 'ZData', Z_positionning + 0*expValuesInterpSmoothed);
    set(hpcolor, 'FaceColor', 'interp', 'EdgeColor', 'interp');
    hold off;
    
    % Settings
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
    
    if intervalScaleBar > 0
        if ~rawData
            colormap(['jet(',num2str(intervalScaleBar),')']);
        else
            colormap([1,1,1;0,0,0]); % Black and white
        end
    else
        colormap('jet');
        % Use flipud to reverse colormap
    end
    if scaleAxis
        caxis([cmin, cmax]);
    end
    hcb3 = colorbar;
    ylabel(hcb3, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    
else
    %% 1 map (with or without markers)
    if ~rawData
        if ~contourPlot
            h(4) = surf(xData_interp, yData_interp, expValuesInterpSmoothed',...
                'FaceColor','interp',...
                'EdgeColor','none',...
                'FaceLighting','gouraud');
            % 'Marker', '+'
            shading interp;
        else
            contourf(xData_interp, yData_interp, expValuesInterpSmoothed',...
                intervalScaleBar);
        end
    else
        h(4) = imagesc(expValuesInterpSmoothed',...
            'XData',xData_interp,'YData',yData_interp);
        set(gca,'YDir','normal');
    end
    
    hold on;
    maxVal = max(max(expValuesInterpSmoothed));
    
    % Set z positions of markers
    if ~contourPlot
        markersVal = ones(length(expValues)) * maxVal;
    else
        markersVal = ones(length(expValues));
    end
    
    if Markers
        plot3(xData_markers, yData_markers, markersVal,'k+');
    end
    
    hold on;
    axis equal;
    axis tight;
    view(0,90);
    
    hXLabel(4) = xlabel('X coordinates ($\mu$m)');
    hYLabel(4) = ylabel('Y coordinates ($\mu$m)');
    hZLabel(4) = zlabel(zString);
    hTitle(4) = title(['Mapping of ', zString]);
    set([hXLabel(4), hYLabel(4), hZLabel(4), hTitle(4)], ...
        'Color', [0,0,0], 'FontSize', FontSizeVal, ...
        'Interpreter', 'Latex');
    
    if intervalScaleBar > 0
        if ~rawData
            colormap(['jet(',num2str(intervalScaleBar),')']);
        else
            cmap = [1,1,1;0,0,0];
            colormap(cmap); % Black and white
            %colormap(['jet(',num2str(intervalScaleBar),')']);
        end
    else
        colormap('jet');
        % Use flipud to reverse colormap
    end
    if scaleAxis
        caxis([cmin, cmax]);
    end
    if rawData
        %set(hcb4,'YTick',[0:maxVal:maxVal]);
        %hcb4 = colorbar;
        %ylabel(hcb4, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
        legendBinaryMap('w', 'k', 's', 's', legendStr, FontSizeVal);
        
    else
        hcb4 = colorbar;
        ylabel(hcb4, zString, 'Interpreter', 'Latex', 'FontSize', FontSizeVal);
    end
    
    set(gca, 'Fontsize', FontSizeVal);
    hold off;
    if rawData
        fracBW = sum(sum(expValuesInterpSmoothed))/(size(expValuesInterpSmoothed,1)*size(expValuesInterpSmoothed,2)*255);
        display(['Fraction of particles (', zString, ' map) :']);
        disp(fracBW);
        display(['Fraction of matrix (', zString, ' map) :']);
        disp(1-fracBW);
    end
    
end

%% Plot difference between interpolated data and smoothed data
if ~TriDiView
    if ~rawData
        differenceVal = (expValuesInterpSmoothed' - expValuesInterp'); %./expValuesInterp
        
        f(2) = figure('position', [WX, WY, WW, WH]);
        colormap hsv;
        
        h(5) = surf(xData_interp, yData_interp, differenceVal,...
            'FaceColor','interp',...
            'EdgeColor','none',...
            'FaceLighting','gouraud');
        
        axis equal;
        shading interp;
        view(0,90);
        
        hXLabel(5) = xlabel('X coordinates ($\mu$m)');
        hYLabel(5) = ylabel('Y coordinates ($\mu$m)');
        hZLabel(5) = zlabel(zString);
        hTitle(5) = title(['Mapping of difference', ...
            ' between interpolated and smoothed data']);
        set([hXLabel(5), hYLabel(5), hZLabel(5), hTitle(5)], ...
            'Color', [0,0,0], 'FontSize', FontSizeVal, ...
            'Interpreter', 'Latex');
        
        colormap('jet'); % Use flipud to reverse colormap
        hcb5 = colorbar;
        ylabel(hcb5, 'Difference (GPa)', ...
            'Interpreter', 'Latex', ...
            'FontSize', FontSizeVal);
    end
end

end