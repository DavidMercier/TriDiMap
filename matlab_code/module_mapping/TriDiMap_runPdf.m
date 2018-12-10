%% Copyright 2014 MERCIER David
%% Function to plot pdf
if config.flag_data
    % Histograms plot
    numberVal = size(data2use,1)*size(data2use,2);
    data2useVect = reshape(data2use, [1,numberVal]);
    indNaN = find(isnan(data2useVect));
    data2useVect(indNaN) = [];
    if ~gui.config.autobinSize
        binsize = gui.config.binSize;
    else
        iqr_value = iqrVal(data2useVect);
        binsize = round(2*iqr_value/(length(data2useVect))^(1/3)); %iqr(data2use)
        set(gui.handles.value_BinSizeHist_GUI, ...
            'String', num2str(round(100*binsize)/100));
        gui.config.binSize = binsize;
    end
    minbin = gui.config.MinHistVal;
    maxbin = gui.config.MaxHistVal;
    CatBin = minbin:binsize:maxbin;
    Hist_i = histc(data2useVect,CatBin);
    Prop_pdf = Hist_i/numberVal; % length(data2useVect) without NaN can be used to have a total probability of 1
    % Problem sometimes when bin too small and not enough data
    Prop_pdf = Prop_pdf/binsize; % probability density function (property must be divided by the number of values and binsize)
    indFactor = 10;
    while max(Prop_pdf) > 1
        Prop_pdf = Prop_pdf/binsize;
        Prop_pdf = Prop_pdf/(indFactor*binsize);
        indFactor = indFactor * 2;
    end
    SumProp_pdf = sum(Prop_pdf);
    SumTot = SumProp_pdf .* binsize;
    %if  gui.config.licenceStat_Flag
    if ~get(gui.handles.cb_plotErrorPDF_GUI, 'Value')
        if ~get(gui.handles.cb_deconvolutionHist_GUI, 'Value')
            bar(CatBin,Prop_pdf,'FaceColor',[0.5 0.5 0.5],'EdgeColor','none', ...
                'LineWidth', LWval);
            set(gcf, 'renderer', 'opengl');
            xlim([0 maxbin]); ylim([0 1]);
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
            if ~config.FrenchLeg
                ylabel('Frequency density');
            else
                ylabel('Densité de probabiilité');
            end
            gui.config.flag_fit = 0;
        else
            exphist = [CatBin' Prop_pdf'];
            M = str2num(get(gui.handles.value_PhNumHist_GUI, 'String'));
            maxiter = str2num(get(gui.handles.value_IterMaxHist_GUI, 'String'));
            limit = str2num(get(gui.handles.value_PrecHist_GUI, 'String'));
            [gui.results.GaussianAllFit, gui.results.GaussianFit] = ...
                TriDiMap_runDeconvolution(data2useVect', exphist, M, ...
                maxiter, limit, config.property, strUnit_Property, ...
                gui.config.licenceStat_Flag);
            gui.results.hist_val = data2useVect';
            gui.results.hist_xy = exphist;
            gui.results.M = M;
            gui.results.maxiter = maxiter;
            gui.results.limit = limit;
            gui.config.flag_fit = 1;
            %save('Blabla.txt', 'variableName', '-ASCII','-append'); % No struct variable in the variable name...
        end
        hold on;
    else
        if gui.config.flag_fit
            gui.results.errorFit = ...
                (Prop_pdf' - gui.results.GaussianFit')./Prop_pdf';
            gui.results.errorFit(gui.results.errorFit==-Inf) = 0;
            gui.results.errorFit(gui.results.errorFit==+Inf) = 0;
            plot(gui.results.errorFit, '+r','LineWidth',2);
            xlim([0 maxbin]);
            ylim([-max(abs(gui.results.errorFit)) ...
                max(abs(gui.results.errorFit))]);
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
        else
            set(gui.handles.cb_plotErrorPDF_GUI,'Value',0);
            TriDiMap_runPlot;
            errordlg('First run deconvolution process!');
        end
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