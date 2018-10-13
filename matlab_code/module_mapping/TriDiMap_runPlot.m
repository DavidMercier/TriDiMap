%% Copyright 2014 MERCIER David
function TriDiMap_runPlot(gifFlag, varargin)
%% Function to run the mapping
if nargin < 1
    gifFlag = 0;
end
reset(gca);
gui = guidata(gcf);
axes(gui.handles.AxisPlot_GUI);
gui.config.gifFlag = gifFlag;
guidata(gcf, gui); gui = guidata(gcf);
if ~gui.config.saveFlag
    TriDiMap_updateUnit_and_GUI;
else
    figure(gui.config.hNewFig);
end
TriDiMap_getParam;
gui = guidata(gcf);
config = gui.config;
strUnit_Property = ...
    get_value_popupmenu(gui.handles.unitProp_GUI, listUnitProperty);
guidata(gcf, gui);
if config.rawData == 8 && gui.config.property  < 3% Code for 3D slices
    TriDiMap_sliceCalc(gui);
    gui = guidata(gcf);
else
    if config.flag_data
        if config.property == 1 || config.property == 4 || config.property == 6
            if ~config.flagZplot
                data2use = gui.data.expValues_mat.YM;
            else
                data2use = gui.data3D.meanZVal_YM;
            end
        elseif config.property == 2 || config.property == 5 || config.property == 7
            if ~config.flagZplot
                data2use = gui.data.expValues_mat.H;
            else
                data2use = gui.data3D.meanZVal_H;
            end
        elseif config.property == 3
            data2use_E = gui.data.expValues_mat.YM;
            data2use_H = gui.data.expValues_mat.H;
            data2use = data2use_H;
        end
        
        % Thresholding
        if gui.config.minVal < 0
            gui.config.minVal = 0;
        end
        if config.property == 3
            if gui.config.minVal >= nanmax(data2use_H) | gui.config.minVal >= nanmax(data2use_E)
                gui.config.minVal = 0;
            end
        end
        if ~isnan(gui.config.minVal) && (gui.config.propertyOld == gui.config.property)
            if config.property ~= 3
                data2use(data2use < gui.config.minVal) = NaN;
            else
                data2use_E(data2use_E < gui.config.minVal) = NaN;
                data2use_H(data2use_H < gui.config.minVal) = NaN;
            end
        else
            if config.property ~= 3
                gui.config.minVal = round(100*(nanmin(nanmin(data2use))))/100;
            else
                gui.config.minVal = round(100*(nanmin(nanmin([data2use_E, data2use_H]))))/100;
            end
            
        end
        set(gui.handles.value_MinVal_GUI, 'String', num2str(nanmin(gui.config.minVal)));
        if gui.config.maxVal < 0 || gui.config.maxVal < gui.config.minVal
            gui.config.maxVal = gui.config.minVal + 100;
        end
        if ~isnan(gui.config.maxVal) && (gui.config.propertyOld == gui.config.property)
            if config.property ~= 3
                data2use(data2use > gui.config.maxVal) = NaN;
            else
                data2use_E(data2use_E > gui.config.maxVal) = NaN;
                data2use_H(data2use_H > gui.config.maxVal) = NaN;
            end
        else
            if config.property ~= 3
                gui.config.maxVal = round(100*(nanmax(nanmax(data2use))))/100;
            else
                gui.config.maxVal = round(100*(nanmax(nanmax([data2use_E, data2use_H]))))/100;
            end
        end
        set(gui.handles.value_MaxVal_GUI, 'String', num2str(nanmax(gui.config.maxVal)));
        if config.property ~= 3
            gui.config.meanVal = round(100*(nanmean(nanmean(data2use))))/100;
        else
            gui.config.meanVal = round(100*(nanmean(nanmean([data2use_E, data2use_H]))))/100;
        end
        set(gui.handles.value_MeanVal_GUI, 'String', num2str(nanmean(gui.config.meanVal)));
        
        % NaN values
        if config.property < 3
            [dataCleaned, ratioNan] = TriDiMap_cleaningData(data2use);
            set(gui.handles.value_NaNratio_GUI, 'String', num2str(ratioNan));
            if config.noNan
                data2use = dataCleaned;
            end
        end
        if config.property ~= 3
            %% Crop data
            [data2use, config.flagCrop] = TriDiMap_cropping(data2use);
            if length(data2use) == 1
                config.flag_data = 0;
            end
        else
            [data2use_E, config.flagCrop] = TriDiMap_cropping(data2use_E);
            [data2use_H, config.flagCrop] = TriDiMap_cropping(data2use_H);
            if length(data2use_E) == 1 && length(data2use_H) == 1
                config.flag_data = 0;
            end
        end
    end
    
    if config.property < 3
        %% Clean data
        if config.flag_data
            %% Normalization of dataset
            if config.normalizationStep && ~config.translationStep
                if config.normalizationStepVal == 1
                    data2use = data2use/(min(min(data2use)));
                elseif config.normalizationStepVal == 2
                    data2use = data2use/(nanmean(nanmean(data2use)));
                elseif config.normalizationStepVal == 3
                    data2use = data2use/(max(max(data2use)));
                end
                display('Translation not possible because normalization is active.');
            end
            
            %% Translation step
            if config.translationStep && ~config.normalizationStep
                data2use = data2use + config.translationStepVal;
                data2use((data2use)<0) = 0;
                display('Negative values for the property are replaced by 0.');
                display('Normalization not possible because translation is active.');
            end
            
            %% Interpolating, smoothing and binarizing steps of dataset
            if config.noNan
                [gui.data.expValuesInterp, gui.data.expValuesSmoothed, ...
                    gui.data.expValuesInterpSmoothed] = ...
                    TriDiMap_interpolation_smoothing(...
                    data2use, ...
                    config.interpBool, config.interpFact, ...
                    config.smoothBool, config.smoothFact);
            else
                gui.data.expValuesInterp = data2use;
                gui.data.expValuesSmoothed = data2use;
                gui.data.expValuesInterpSmoothed = data2use;
            end
            guidata(gcf, gui);
            
            %% Grid meshing
            TriDiMap_meshingGrid(data2use);
            gui = guidata(gcf);
        end
        
        %% Legend + Map
        if config.flag_data
            gui.data.data2plot = gui.data.expValuesInterpSmoothed;
            
            if ~config.normalizationStep
                if config.property == 1
                    if ~config.FrenchLeg
                        config.legend = strcat({'Elastic modulus ('},config.strUnit_Property, ')');
                    else
                        config.legend = strcat({'Module d''\''elasticit\''e ('},config.strUnit_Property, ')');
                    end
                elseif config.property == 2
                    if ~config.FrenchLeg
                        config.legend = strcat({'Hardness ('},config.strUnit_Property, ')');
                    else
                        config.legend = strcat({'Duret\''e ('},config.strUnit_Property, ')');
                    end
                elseif config.property == 3
                    config.legend = 'Phase number';
                end
                
            elseif config.normalizationStep > 0
                if config.normalizationStepVal == 1
                    if config.property == 1
                        if ~config.FrenchLeg
                            config.legend = 'Normalized elastic modulus by minimum elastic modulus value';
                        else
                            config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur minimum';
                        end
                    elseif config.property == 2
                        if ~config.FrenchLeg
                            config.legend = 'Normalized hardness by minimum hardness value';
                        else
                            config.legend = 'Duret\''e normalis\''ee par la valeur minimum';
                        end
                    end
                elseif config.normalizationStepVal == 2
                    if config.property == 1
                        if ~config.FrenchLeg
                            config.legend = 'Normalized elastic modulus by mean elastic modulus value';
                        else
                            config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur moyenne';
                        end
                    elseif config.property == 2
                        if ~config.FrenchLeg
                            config.legend = 'Normalized hardness by mean hardness value';
                        else
                            config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur moyenne';
                        end
                    end
                elseif config.normalizationStepVal == 3
                    if config.property == 1
                        if ~config.FrenchLeg
                            config.legend = 'Normalized elastic modulus by maximum elastic modulus value';
                        else
                            config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur maximum';
                        end
                    elseif config.property == 2
                        if ~config.FrenchLeg
                            config.legend = 'Normalized hardness by maximum hardness value';
                        else
                            config.legend = 'Module d''\''elasticit\''e normalis\''e par la valeur maximum';
                        end
                    end
                end
            end
            gui.config = config;
            guidata(gcf, gui);
            if get(gui.handles.cb_errorMap_GUI, 'Value')
                TriDiMap_plot_error;
            else
                TriDiMap_plot;
            end
            gui = guidata(gcf);
        else
            errordlg(['First set indentation grid parameters and load an '...
                'Excel file to plot a property map !']);
        end
    elseif config.property == 3
        if ~get(gui.handles.cb_sectPlot_GUI, 'Value')
            color1 = 'k+'; colorT1 = 'Black';
            color2 = 'k+'; colorT2 = 'Black';
            color3 = 'k+'; colorT3 = 'Black';
            color4 = 'k+'; colorT4 = 'Black';
        else
            color1 = 'k+'; colorT1 = 'Black';
            color2 = 'r*'; colorT2 = 'Red';
            color3 = 'go'; colorT3 = 'Green';
            color4 = 'bx'; colorT4 = 'Blue';
        end
        if gui.config.HVal_ThresLines <= gui.config.minVal
            gui.config.HVal_ThresLines = round(1.2*gui.config.minVal);
            set(gui.handles.value_Hth_ValEH_GUI, 'String', gui.config.HVal_ThresLines);
        end
        if gui.config.EVal_ThresLines <= gui.config.minVal
            gui.config.EVal_ThresLines = round(1.2*gui.config.minVal);
            set(gui.handles.value_Hth_ValEH_GUI, 'String', gui.config.EVal_ThresLines);
        end
        
        % Sectors definition for E-H plot
        %2|4
        %---
        %1|3
        
        gui.data.dataH_Sector = (data2use_H < gui.config.HVal_ThresLines & data2use_E < gui.config.EVal_ThresLines) + ...
            2*(data2use_H < gui.config.HVal_ThresLines & data2use_E > gui.config.EVal_ThresLines) + ...
            3*(data2use_H > gui.config.HVal_ThresLines & data2use_E < gui.config.EVal_ThresLines) + ...
            4*(data2use_H > gui.config.HVal_ThresLines & data2use_E > gui.config.EVal_ThresLines);
        
        gui.data.dataH_Sector1 = data2use_H(data2use_H < gui.config.HVal_ThresLines & data2use_E < gui.config.EVal_ThresLines);
        gui.data.dataE_Sector1 = data2use_E(data2use_H < gui.config.HVal_ThresLines & data2use_E < gui.config.EVal_ThresLines);
        gui.data.dataH_Sector2 = data2use_H(data2use_H < gui.config.HVal_ThresLines & data2use_E > gui.config.EVal_ThresLines);
        gui.data.dataE_Sector2 = data2use_E(data2use_H < gui.config.HVal_ThresLines & data2use_E > gui.config.EVal_ThresLines);
        gui.data.dataH_Sector3 = data2use_H(data2use_H > gui.config.HVal_ThresLines & data2use_E < gui.config.EVal_ThresLines);
        gui.data.dataE_Sector3 = data2use_E(data2use_H > gui.config.HVal_ThresLines & data2use_E < gui.config.EVal_ThresLines);
        gui.data.dataH_Sector4 = data2use_H(data2use_H > gui.config.HVal_ThresLines & data2use_E > gui.config.EVal_ThresLines);
        gui.data.dataE_Sector4 = data2use_E(data2use_H > gui.config.HVal_ThresLines & data2use_E > gui.config.EVal_ThresLines);
        
        if ~get(gui.handles.cb_plotSectMap_GUI, 'Value')
            if gui.config.logZ
                loglog(gui.data.dataH_Sector1, gui.data.dataE_Sector1, ...
                    color1, 'Linewidth', 1.5); hold on;
                loglog(gui.data.dataH_Sector2, gui.data.dataE_Sector2, ...
                    color2, 'Linewidth', 1.5); hold on;
                loglog(gui.data.dataH_Sector3, gui.data.dataE_Sector3, ...
                    color3, 'Linewidth', 1.5); hold on;
                loglog(gui.data.dataH_Sector4, gui.data.dataE_Sector4, ...
                    color4, 'Linewidth', 1.5); hold off;
            else
                plot(gui.data.dataH_Sector1, gui.data.dataE_Sector1, ...
                    color1, 'Linewidth', 1.5); hold on;
                plot(gui.data.dataH_Sector2, gui.data.dataE_Sector2, ...
                    color2, 'Linewidth', 1.5); hold on;
                plot(gui.data.dataH_Sector3, gui.data.dataE_Sector3, ...
                    color3, 'Linewidth', 1.5); hold on;
                plot(gui.data.dataH_Sector4, gui.data.dataE_Sector4, ...
                    color4, 'Linewidth', 1.5); hold off;
            end
            if get(gui.handles.cb_sectMVPlot_GUI, 'Value')
                meanH = round(10*nanmean(gui.data.dataH_Sector1))/10;
                meanE = round(10*nanmean(gui.data.dataE_Sector1))/10;
                x = 0.7*gui.config.HVal_ThresLines;
                y = gui.config.EVal_ThresLines;
                text(x,0.10*y,strcat('H = ',num2str(meanH), gui.config.strUnit_Property), 'Color', colorT1);
                text(x,0.05*y,strcat('E = ',num2str(meanE), gui.config.strUnit_Property), 'Color', colorT1);
                meanH = round(10*nanmean(gui.data.dataH_Sector2))/10;
                meanE = round(10*nanmean(gui.data.dataE_Sector2))/10;
                x = 0.7*gui.config.HVal_ThresLines;
                y = max(max(data2use_E));
                text(x,0.95*y,strcat('H = ',num2str(meanH), gui.config.strUnit_Property), 'Color', colorT2);
                text(x,0.90*y,strcat('E = ',num2str(meanE), gui.config.strUnit_Property), 'Color', colorT2);
                meanH = round(10*nanmean(gui.data.dataH_Sector3))/10;
                meanE = round(10*nanmean(gui.data.dataE_Sector3))/10;
                x = 1.1*gui.config.HVal_ThresLines;
                y = gui.config.EVal_ThresLines;
                text(x,0.10*y,strcat('H = ',num2str(meanH), gui.config.strUnit_Property), 'Color', colorT3);
                text(x,0.05*y,strcat('E = ',num2str(meanE), gui.config.strUnit_Property), 'Color', colorT3);
                meanH = round(10*nanmean(gui.data.dataH_Sector4))/10;
                meanE = round(10*nanmean(gui.data.dataE_Sector4))/10;
                x = 1.1*gui.config.HVal_ThresLines;
                y = max(max(data2use_E));
                text(x,0.95*y,strcat('H = ',num2str(meanH), gui.config.strUnit_Property), 'Color', colorT4);
                text(x,0.90*y,strcat('E = ',num2str(meanE), gui.config.strUnit_Property), 'Color', colorT4);
            end
            hold on;
            if ~config.FrenchLeg
                hXLabel = xlabel(strcat({'Hardness ('},gui.config.strUnit_Property, ')'));
                hYLabel = ylabel(strcat({'Elastic modulus ('},gui.config.strUnit_Property, ')'));
            else
                xlabel(strcat({'Duret''e ('},gui.config.strUnit_Property, ')'));
                hYLabel = ylabel(strcat({'Module d''\''elasticit\''e ('},gui.config.strUnit_Property, ')'));
            end
            set([hXLabel, hYLabel], ...
                'Color', [0,0,0], 'FontSize', gui.config.FontSizeVal, ...
                'Interpreter', 'Latex');
            
            if gui.config.plotThresLines
                xData_HThres = ones(1,2001) * gui.config.HVal_ThresLines;
                yData_HThres = 0:1:2000;
                xData_EThres = 0:1:200;
                yData_EThres = ones(1,201) * gui.config.EVal_ThresLines;
                plot(xData_HThres, yData_HThres, '-.k', 'Linewidth', 1.5);
                hold on;
                plot(xData_EThres, yData_EThres, '--r', 'Linewidth', 1.5);
                hold on;
                %         ellipse(gui.config.HVal_ThresLines, gui.config.EVal_ThresLines, ...
                %             0,0,0);
            end
            
            xlim([0 nanmax(nanmax(data2use_H))]);
            ylim([0 nanmax(nanmax(data2use_E))]);
            
            if gui.config.grid
                grid on;
            else
                grid off;
            end
            
        else
            cla;
            guidata(gcf, gui);
            TriDiMap_plot;
        end
        
    elseif config.property == 4 || config.property == 5
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
                binsize = 2*iqr_value/(length(data2useVect))^(1/3); %iqr(data2use)
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
                        'LineWidth', 1.5);
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
        
    elseif config.property > 5
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
        %     plot(x,f,'-r', 'LineWidth', 1.5)
        delete(findall(findall(gcf,'Type','axe'),'Type','text'));
        %     legend('Experimental','Theoretical','Location','NW');
        if config.property == 6
            if ~config.FrenchLeg
                xlabel(strcat('Elastic modulus (',strUnit_Property, ')'));
            else
                xlabel(strcat('Module d''\''elasticit\''e (',strUnit_Property, ')'));
            end
        elseif config.property == 7
            if ~config.FrenchLeg
                xlabel(strcat('Hardness (',strUnit_Property, ')'));
            else
                xlabel(strcat({'Duret\''e ('},config.strUnit_Property, ')'));
            end
        end
        if ~config.FrenchLeg
            ylabel('Cumulative density function');
        else
            ylabel('Fonction de distribution cumulative');
        end
        set(h_CDF, 'LineStyle', '-', 'Color', 'k' , 'LineWidth', 2);
        if get (gui.handles.cb_WeibullFit_GUI, 'Value')
            % Fit Weibull
            OPTIONS = algoMinimization;
            gui.cumulativeFunction = ...
                TriDiMap_Weibull_cdf(OPTIONS, xdataCDF, ydataCDF);
            plot(xdataCDF, gui.cumulativeFunction.ydata_cdf_Fit, '-r', ...
                'LineWidth', 1.5);
            gui.results.xdataCDF = xdataCDF;
            gui.results.ydataCDF = ydataCDF;
            m_Weibull = gui.cumulativeFunction.coefEsts(1);
            meanPAram = gui.cumulativeFunction.coefEsts(2);
            str_title = ['Mean critical parameter = ', ...
                num2str(meanPAram), ...
                ' / Weibull modulus = ', num2str(m_Weibull)];
            title(str_title);
        end
    end
    if config.flag_data
        if config.property < 3
            coordSyst(gui.handles.MainWindow);
        else
            if ~config.saveFlag
                set(0, 'currentfigure', gui.handles.MainWindow);
                try
                    delete(findall(gcf,'Tag','annotation'));
                catch
                end
            end
        end
    end
end

if gui.config.grid
    grid on;
else
    grid off;
end
hold off;

guidata(gcf, gui);
if gui.config.saveFlag
    TriDiMap_updateUnit_and_GUI;
end
end