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

%% Plot of main experimental cdf
if gui.config.licenceStat_Flag
    h_CDF = cdfplot(data2useVect);
else
    h_CDF = cdf_plot(data2useVect); % Third party code
end
hold on;
set(h_CDF, 'LineStyle', '-', 'Color', 'k' , 'LineWidth', LWval);

%% Plot of Gaussian fit
if get(gui.handles.cb_GaussianFit_GUI, 'Value')
    if gui.config.licenceStat_Flag
        %Yfit_CDF = cdf('normal',data2useVect, meanVect, stddevVect);
        Yfit_CDF = normcdf(data2useVect, meanVect, stddevVect);
    else
        Yfit_CDF = cdfGaussian(data2useVect, meanVect, stddevVect);
    end
    h_CDF_fit = plot(sort(data2useVect), sort(Yfit_CDF));
    set(h_CDF_fit, 'LineStyle', '-.', 'Color', 'k', 'LineWidth', LWval);
end
hold on;

%% Plot of Weibull fit
if get(gui.handles.cb_WeibullFit_GUI, 'Value')
    xdataCDF = get(h_CDF,'XData');
    xdataCDF(1) = 0;
    xdataCDF(end) = xdataCDF(end-1);
    ydataCDF = get(h_CDF,'YData');
    %     x = round(min(data2useVect)*10)/10:0.1:round(max(data2useVect)*10)/10;
    %     f = evcdf(x,round(mean(data2useVect)*10)/10,20);
    %     plot(x,f,'-r', 'LineWidth', LWval)
    
    % Fit Weibull
    OPTIONS = algoMinimization;
    gui.cumulativeFunction = ...
        TriDiMap_Weibull_cdf(OPTIONS, xdataCDF, ydataCDF);
    h_Weibull = plot(xdataCDF, gui.cumulativeFunction.ydata_cdf_Fit, '--k', ...
        'LineWidth', LWval);
    if gui.config.property == 4
        gui.resultsCDF.E.xdataCDF = xdataCDF;
        gui.resultsCDF.E.ydataCDF = ydataCDF;
    elseif gui.config.property == 5
        gui.resultsCDF.H.xdataCDF = xdataCDF;
        gui.resultsCDF.H.ydataCDF = ydataCDF;
    end
    
    m_Weibull = gui.cumulativeFunction.coefEsts(1);
    meanPAram = gui.cumulativeFunction.coefEsts(2);
    str_title = ['Mean critical parameter = ', ...
        num2str(meanPAram), ...
        ' / Weibull modulus = ', num2str(m_Weibull)];
    title(str_title);
    hold on
end

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

%% Legend for basic fitting
if get(gui.handles.cb_GaussianFit_GUI, 'Value') && ~get(gui.handles.cb_WeibullFit_GUI, 'Value')
    legend([h_CDF, h_CDF_fit], 'Experimental data', 'Gaussian fit');
elseif get(gui.handles.cb_WeibullFit_GUI, 'Value') && ~get(gui.handles.cb_GaussianFit_GUI, 'Value')
    legend([h_CDF, h_Weibull], 'Experimental data', 'Weibull fit');
elseif get(gui.handles.cb_GaussianFit_GUI, 'Value') && get(gui.handles.cb_WeibullFit_GUI, 'Value')
    legend([h_CDF, h_CDF_fit, h_Weibull], 'Experimental data', 'Gaussian fit', 'Weibull fit');
elseif get(gui.handles.cb_CdfFromPdf_GUI, 'Value') && ...
        (~get(gui.handles.cb_WeibullFit_GUI, 'Value') && ~get(gui.handles.cb_GaussianFit_GUI, 'Value'))
    legend([h_CDF, hp_All], 'Experimental data', 'CDF fit from PDF fit');
end