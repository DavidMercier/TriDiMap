%% Copyright 2014 MERCIER David
%% Function to plot pdf
if config.flag_data
    % Histograms plot
    numberVal = size(data2use,1)*size(data2use,2);
    data2useVect = reshape(data2use, [1,numberVal]);
    indNaN = find(isnan(data2useVect));
    data2useVect(indNaN) = [];
    if gui.config.autobinSize
        iqr_value = iqrVal(data2useVect);
        gui.config.binSize = round(2*iqr_value/(length(data2useVect))^(1/3)); %iqr(data2use)
        set(gui.handles.value_BinSizeHist_GUI, ...
            'String', num2str(round(100*gui.config.binSize)/100));
    end
    if gui.config.binSize == 0
        gui.config.binSize = 0.01; % To avoir zero nonsense value
        set(gui.handles.value_BinSizeHist_GUI, ...
            'String', num2str(round(100*gui.config.binSize)/100));
    end
    binsize = gui.config.binSize;
    minbin = gui.config.MinHistVal;
    maxbin = gui.config.MaxHistVal;
    CatBin = minbin:binsize:maxbin;
    Hist_i = histcounts(data2useVect,CatBin); % previously histc (not recommended)
    CatBin(1)=[]; %Because size(CatBin) = size(Prop_pdf)+1;
    Prop_pdf = Hist_i/numberVal; % length(data2useVect) without NaN can be used to have a total probability of 1
    SumProp_pdf = sum(Prop_pdf);
    SumTot = SumProp_pdf .* binsize;
    %if  gui.config.licenceStat_Flag
    plotError = get(gui.handles.cb_plotErrorPDF_GUI, 'Value');
    missingErrorFit = false;
    if plotError
        pdfProperty = 'E';
        if ismember(config.property, [5, 9])
            pdfProperty = 'H';
        end
        hasErrorFit = isfield(gui, 'resultsPDF') && ...
            isfield(gui.resultsPDF, pdfProperty) && ...
            isfield(gui.resultsPDF.(pdfProperty), 'GaussianFit') && ...
            isfield(gui.resultsPDF.(pdfProperty), 'hist_xy') && ...
            isfield(gui.resultsPDF.(pdfProperty), 'hist_val');
        if hasErrorFit
            errorFitResults = gui.resultsPDF.(pdfProperty);
            hasErrorFit = numel(errorFitResults.GaussianFit) == numel(Prop_pdf) && ...
                all(isfinite(errorFitResults.GaussianFit(:))) && ...
                isequal(errorFitResults.hist_xy, [CatBin' Prop_pdf']) && ...
                isequal(errorFitResults.hist_val(:), data2useVect(:));
        end
        if ~hasErrorFit
            missingErrorFit = true;
            plotError = false;
            set(gui.handles.cb_plotErrorPDF_GUI, 'Value', 0);
            plotFigure = gcf;
            errordlg('Run PDF deconvolution for the selected property and current data/histogram settings before plotting its error.', ...
                'PDF fit error');
            set(0, 'CurrentFigure', plotFigure);
        end
    end
    if ~plotError
        if ~get(gui.handles.cb_deconvolutionHist_GUI, 'Value') || missingErrorFit
            bar(CatBin,Prop_pdf,'FaceColor',[0.5 0.5 0.5],'EdgeColor','none', ...
                'LineWidth', LWval);
            set(gcf, 'renderer', 'opengl');
            xlim([0 maxbin]); ylim(TriDiMap_pdfYLimits(Prop_pdf));
            if config.property == 4
                if ~config.FrenchLeg
                    xlabel(strcat('Elastic modulus (',strUnit_Property, ')'));
                else
                    xlabel(strcat('Module d''\''elasticit\''e (',strUnit_Property, ')'));
                end
            elseif config.property == 5
                xlabel(strcat('Hardness (',strUnit_Property, ')'));
            end
            if ~config.FrenchLeg
                ylabel('Frequency density');
            else
                ylabel('Densité de probabilité');
            end
            gui.config.flag_fit = 0;
        else
            exphist = [CatBin' Prop_pdf'];
            M = str2num(get(gui.handles.value_PhNumHist_GUI, 'String'));
            maxiter = str2num(get(gui.handles.value_IterMaxHist_GUI, 'String'));
            limit = str2num(get(gui.handles.value_PrecHist_GUI, 'String'));
            try
                [resultsPDF.GaussianAllFit, resultsPDF.GaussianFit, ...
                    resultsPDF.pdfData.minmeanVec, ...
                    resultsPDF.pdfData.minstddev, ...
                    resultsPDF.pdfData.minf,...
                    resultsPDF.position] = ...
                    TriDiMap_runDeconvolution(data2useVect', exphist, M, ...
                    maxiter, limit, config.property, strUnit_Property, ...
                    gui.config.licenceStat_Flag);
            catch
                errordlg('Decomposition process crashed...Run it again and change inputs');
            end
            resultsPDF.hist_val = data2useVect';
            resultsPDF.hist_xy = exphist;
            resultsPDF.M = M;
            resultsPDF.maxiter = maxiter;
            resultsPDF.limit = limit;
            gui.config.flag_fit = 1;
            [resultsPDF.transitionVal, resultsPDF.yTransitionVal]...
                = findIntersection(resultsPDF.pdfData);
            if ismember(config.property, [4, 8])
                gui.resultsPDF.E = resultsPDF;
            elseif ismember(config.property, [5, 9])
                gui.resultsPDF.H = resultsPDF;
            end
            %save('Blabla.txt', 'variableName', '-ASCII','-append'); % No struct variable in the variable name...
        end
        hold on;
    else
        occupiedBins = Prop_pdf(:) > 0;
        errorFit = NaN(numel(Prop_pdf), 1);
        fittedPDF = errorFitResults.GaussianFit(:);
        measuredPDF = Prop_pdf(:);
        errorFit(occupiedBins) = ...
            (measuredPDF(occupiedBins) - fittedPDF(occupiedBins))./measuredPDF(occupiedBins);
        if any(~occupiedBins)
            warning('TriDiMap:EmptyPDFErrorBins', ...
                'Relative PDF error is undefined for empty histogram bins; those bins are omitted.');
        end
        gui.resultsPDF.(pdfProperty).errorFit = errorFit;
        plot(CatBin, errorFit, '+r','LineWidth',2);
        xlim([0 maxbin]);
        maxError = max(abs(errorFit(occupiedBins)));
        if isempty(maxError) || maxError == 0
            maxError = 1;
        end
        ylim([-maxError maxError]);
        if config.property == 4
            if ~config.FrenchLeg
                xlabel(strcat('Elastic modulus (',strUnit_Property, ')'));
            else
                xlabel(strcat('Module d''\''elasticit\''e (',strUnit_Property, ')'));
            end
        elseif config.property == 5
            if ~config.FrenchLeg
                xlabel(strcat('Hardness (',strUnit_Property, ')'));
            else
                xlabel(strcat({'Duret\''e ('},config.strUnit_Property, ')'));
            end
        end
        ylabel('Error (%)');
    end
    %             else
    %                 set(gui.handles.cb_deconvolutionHist_GUI,'Value',0);
    %                 cla;
    %                 errordlg('No licence for the Statistics_Toolbox!');
    %             end
else
    errordlg(['First set indentation grid parameters and '...
        'load an Excel file to plot a property map !']);
end