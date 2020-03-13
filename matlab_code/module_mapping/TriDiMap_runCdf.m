%% Copyright 2014 MERCIER David
%% Script to plot cdf
numberVal = size(data2use,1)*size(data2use,2);
data2useVect = reshape(data2use, [1,numberVal]);
indNaN = find(isnan(data2useVect));
data2useVect(indNaN) = [];
meanVect = mean(data2useVect);
stddevVect = std(data2useVect);
flagVal = 0;

% Clear plot
if config.property < 8
    delete(findall(findall(gcf,'Type','axe'),'Type','text'));
end

Gplot = get(gui.handles.cb_GaussianPlot_GUI, 'Value');
Gfit = get(gui.handles.cb_GaussianFit_GUI, 'Value');
Wfit = get(gui.handles.cb_WeibullFit_GUI, 'Value');
AllCDF = get(gui.handles.cb_CdfFromPdf_GUI, 'Value');

%% Plot of main experimental cdf
if gui.config.licenceStat_Flag
    h_CDF = cdfplot(data2useVect);
else
    h_CDF = cdf_plot(data2useVect); % Third party code
end
hold on;
set(h_CDF, 'LineStyle', '-', 'Color', 'k' , 'LineWidth', LWval);

%% Plot of Gaussian CDF
if get(gui.handles.cb_GaussianPlot_GUI, 'Value')
    if gui.config.licenceStat_Flag
        %Yfit_CDF = cdf('normal',data2useVect, meanVect, stddevVect);
        Yfit_CDF = normcdf(data2useVect, meanVect, stddevVect);
    else
        Yfit_CDF = cdfGaussian(data2useVect, meanVect, stddevVect);
    end
    h_CDF_fit = plot(sort(data2useVect), sort(Yfit_CDF));
    set(h_CDF_fit, 'LineStyle', '-.', 'Color', 'k', 'LineWidth', LWval);
    hold on
end
hold on;

%% Fitting process set up
if get(gui.handles.cb_GaussianFit_GUI, 'Value') || ...
        get(gui.handles.cb_WeibullFit_GUI, 'Value')
    xdataCDF = get(h_CDF,'XData');
    xdataCDF(1) = 0;
    xdataCDF(end) = xdataCDF(end-1);
    ydataCDF = get(h_CDF,'YData');
    %     x = round(min(data2useVect)*10)/10:0.1:round(max(data2useVect)*10)/10;
    %     f = evcdf(x,round(mean(data2useVect)*10)/10,20);
    %     plot(x,f,'-r', 'LineWidth', LWval)
    
    OPTIONS = algoMinimization;
end

%% Plot of Gaussian CDF fit
if get(gui.handles.cb_GaussianFit_GUI, 'Value')
    gui.resultsCDF.Gaussian = ...
        TriDiMap_MinGaussian_cdf(OPTIONS, xdataCDF, ydataCDF);
    h_Gfit = plot(xdataCDF, gui.resultsCDF.Gaussian.ydata_cdf_Fit, '-ok', ...
        'LineWidth', LWval);
    [H, pValue, KSstatistic] = kstest_2s_2d([xdataCDF', ydataCDF'], ...
        [xdataCDF',gui.resultsCDF.Gaussian.ydata_cdf_Fit'])
    if gui.config.property == 4
        gui.resultsCDF.EGauss.xdataCDF = xdataCDF;
        gui.resultsCDF.EGauss.ydataCDF = ydataCDF;
    elseif gui.config.property == 5
        gui.resultsCDF.HGauss.xdataCDF = xdataCDF;
        gui.resultsCDF.HGauss.ydataCDF = ydataCDF;
    end
end
hold on;

%% Plot of Weibull fit
if get(gui.handles.cb_WeibullFit_GUI, 'Value')
    gui.resultsCDF.Weibull = ...
        TriDiMap_MinWeibull_cdf(OPTIONS, xdataCDF, ydataCDF);
    h_Wfit = plot(xdataCDF, gui.resultsCDF.Weibull.ydata_cdf_Fit, '--k', ...
        'LineWidth', LWval);
    [H, pValue, KSstatistic] = kstest_2s_2d([xdataCDF', ydataCDF'], ...
        [xdataCDF',gui.resultsCDF.Gaussian.ydata_cdf_Fit'])
    if gui.config.property == 4
        gui.resultsCDF.EWeibull.xdataCDF = xdataCDF;
        gui.resultsCDF.EWeibull.ydataCDF = ydataCDF;
    elseif gui.config.property == 5
        gui.resultsCDF.HWeibull.xdataCDF = xdataCDF;
        gui.resultsCDF.HWeibull.ydataCDF = ydataCDF;
    end
end
hold on

%% Plot of all cdf components based on pdf fitting results
if get(gui.handles.cb_CdfFromPdf_GUI, 'Value')
    if isfield(gui, 'resultsPDF')
        if gui.config.property == 6 && isfield(gui.resultsPDF, 'E')
            resultsPDF = gui.resultsPDF.E;
        elseif gui.config.property == 7 && isfield(gui.resultsPDF, 'H')
            resultsPDF = gui.resultsPDF.H;
        else
            resultsPDF.position= [0,0,0];
            resultsPDF.pdfData.minmeanVec = 0;
            resultsPDF.pdfData.minstddev = 0;
            resultsPDF.pdfData.minf = 0;
            disp('Run first deconvolution process of the probability density function');
        end
        minVal = resultsPDF.position(1);
        maxVal = resultsPDF.position(2);
        maxXPos = resultsPDF.position(3);
        maxYPos = 0.9; %gui.results.position(4);
        for ii = 1:length(resultsPDF.pdfData.minmeanVec)
            if gui.config.licenceStat_Flag
                resultsPDF.pdfData.YdataFit(:,ii) = cdf('Normal',data2useVect,...
                    resultsPDF.pdfData.minmeanVec(ii), resultsPDF.pdfData.minstddev(ii));
            else
                resultsPDF.pdfData.YdataFit(:,ii) = cdfGaussian(data2useVect,...
                    resultsPDF.pdfData.minmeanVec(ii), resultsPDF.pdfData.minstddev(ii));
            end
            hp(ii) = plot(sort(data2useVect), sort(resultsPDF.pdfData.YdataFit(:,ii)).*...
                resultsPDF.pdfData.minf(ii));
            hold on;
            t = sprintf('Phase %i\n%8.3f\n%8.3f\n%8.3f\n', ii, ...
                resultsPDF.pdfData.minmeanVec(ii), ...
                resultsPDF.pdfData.minstddev(ii), ...
                resultsPDF.pdfData.minf(ii));
            ht(ii) = text(0.025*(maxXPos)*ii*3+minVal,maxYPos,char(t));hold on;
            switch ii
                case 1
                    set(hp(ii), 'Color', 'b', 'LineWidth', LWval);
                    set(ht(ii), 'Color', 'b');
                case 2
                    set(hp(ii), 'Color', 'r', 'LineWidth', LWval);
                    set(ht(ii), 'Color', 'r');
                case 3
                    set(hp(ii), 'Color', 'g', 'LineWidth', LWval);
                    set(ht(ii), 'Color', 'g');
                case 4
                    set(hp(ii), 'Color', 'y', 'LineWidth', LWval);
                    set(ht(ii), 'Color', 'y');
                case 5
                    set(hp(ii), 'Color', 'm', 'LineWidth', LWval);
                    set(ht(ii), 'Color', 'm');
                case 6
                    set(hp(ii), 'Color', 'c', 'LineWidth', LWval);
                    set(ht(ii), 'Color', 'c');
            end
        end
        hp_All = plot(sort(data2useVect), sum(sort(resultsPDF.pdfData.YdataFit.*...
            resultsPDF.pdfData.minf),2));
        set(hp_All, 'Color', 'k', 'LineStyle', '--', 'LineWidth', LWval);
    else
        errordlg('Run first deconvolution process of the probability density function');
    end
end

%% Axis settings
%     legend('Experimental','Theoretical','Location','NW');
if config.property == 6 || config.property == 8
    if ~config.FrenchLeg
        xlabel(strcat('Elastic modulus (',strUnit_Property, ')'));
    else
        xlabel(strcat('Module d''\''elasticit\''e (',strUnit_Property, ')'));
    end
elseif config.property == 7 || config.property == 9
    if ~config.FrenchLeg
        xlabel(strcat('Hardness (',strUnit_Property, ')'));
    else
        xlabel(strcat({'Duret\''e ('},config.strUnit_Property, ')'));
    end
end
if ~config.FrenchLeg
    if config.property < 8
        ylabel('Cumulative density function');
    else
        ylabel('Frequency density and Cumulative density function');
    end
else
    if config.property < 8
        ylabel('Fonction de distribution cumulative');
    else
        ylabel('Densité de probabilité et Fonction de distribution cumulative');
    end
end

%% Title and Legend for basic fitting
if Gplot && ~Gfit && ~Wfit
    str_title = ['Mean Value = ', num2str(meanVect), ...
        ' / Standard deviation = ', num2str(stddevVect)];
elseif ~Gplot && Gfit && ~Wfit
    str_title = ['Mean parameter = ', num2str(gui.resultsCDF.Gaussian.coefEsts(1)), ...
        ' / Standard deviation = ', num2str(gui.resultsCDF.Gaussian.coefEsts(2))];
elseif ~Gplot && ~Gfit && Wfit
    str_title = ['Mean parameter = ', num2str(gui.resultsCDF.Weibull.coefEsts(2)), ...
        ' / Weibull modulus = ', num2str(gui.resultsCDF.Weibull.coefEsts(1))];
else
    str_title = [];
end
title(str_title);

if Gfit && ~Wfit
    legend([h_CDF, h_Gfit], 'Experimental data', 'Gaussian fit');
elseif ~Gfit && Wfit
    legend([h_CDF, h_Wfit], 'Experimental data', 'Weibull fit');
elseif Gfit && Wfit
    legend([h_CDF, h_Gfit, h_Wfit], 'Experimental data', 'Gaussian fit', 'Weibull fit');
elseif AllCDF && ~Gfit && ~Wfit
    legend([h_CDF, hp_All], 'Experimental data', 'CDF fit from PDF fit');
end