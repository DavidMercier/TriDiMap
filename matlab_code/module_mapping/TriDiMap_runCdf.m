%% Copyright 2014 MERCIER David
%% Script to plot cdf
numberVal = size(data2use,1)*size(data2use,2);
data2useVect = reshape(data2use, [1,numberVal]);
indNaN = find(isnan(data2useVect));
data2useVect(indNaN) = [];
meanVect = mean(data2useVect);
stddevVect = std(data2useVect);
if gui.config.licenceStat_Flag
    %h_CDF = cdf('normal',data2useVect, meanVect, stddevVect);
    Yfit_CDF = normcdf(data2useVect, meanVect, stddevVect);
    h_CDF = cdfplot(data2useVect);
else
    Yfit_CDF = cdfGaussian(data2useVect, meanVect, stddevVect);
    h_CDF = cdf_plot(data2useVect); % Third party code
end
%h_CDF_fit = plot(sort(data2useVect), sort(Yfit_CDF));
xdataCDF = get(h_CDF,'XData');
xdataCDF(1) = 0;
xdataCDF(end) = xdataCDF(end-1);
ydataCDF = get(h_CDF,'YData');
hold on
%     x = round(min(data2useVect)*10)/10:0.1:round(max(data2useVect)*10)/10;
%     f = evcdf(x,round(mean(data2useVect)*10)/10,20);
%     plot(x,f,'-r', 'LineWidth', LWval)
if config.property < 8
    delete(findall(findall(gcf,'Type','axe'),'Type','text'));
end
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
        ylabel('Densité de probabiilité et Fonction de distribution cumulative');
    end
end
set(h_CDF, 'LineStyle', '-', 'Color', 'k' , 'LineWidth', 2);
if get (gui.handles.cb_WeibullFit_GUI, 'Value')
    % Fit Weibull
    OPTIONS = algoMinimization;
    gui.cumulativeFunction = ...
        TriDiMap_Weibull_cdf(OPTIONS, xdataCDF, ydataCDF);
    plot(xdataCDF, gui.cumulativeFunction.ydata_cdf_Fit, '-r', ...
        'LineWidth', LWval);
    gui.results.xdataCDF = xdataCDF;
    gui.results.ydataCDF = ydataCDF;
    m_Weibull = gui.cumulativeFunction.coefEsts(1);
    meanPAram = gui.cumulativeFunction.coefEsts(2);
    str_title = ['Mean critical parameter = ', ...
        num2str(meanPAram), ...
        ' / Weibull modulus = ', num2str(m_Weibull)];
    title(str_title);
end