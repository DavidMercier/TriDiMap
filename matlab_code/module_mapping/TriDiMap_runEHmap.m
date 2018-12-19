%% Copyright 2014 MERCIER David
%% Script to plot E-H map + sector
if gui.config.plotClusters == 1
    color1 = 'k+'; colorT1 = 'Black';
    color2 = 'k+'; colorT2 = 'Black';
    color3 = 'k+'; colorT3 = 'Black';
    color4 = 'k+'; colorT4 = 'Black';
elseif gui.config.plotClusters == 2
    color1 = 'k+'; colorT1 = 'Black';
    color2 = 'r*'; colorT2 = 'Red';
    color3 = 'go'; colorT3 = 'Green';
    color4 = 'bx'; colorT4 = 'Blue';
end

if gui.config.plotClusters < 3
    gui.config.flag_ClusterGauss = 0;
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
    
    if ~gui.config.plotSectMap
        if gui.config.logZ
            loglog(gui.data.dataH_Sector1, gui.data.dataE_Sector1, ...
                color1, 'Linewidth', LWval); hold on;
            loglog(gui.data.dataH_Sector2, gui.data.dataE_Sector2, ...
                color2, 'Linewidth', LWval); hold on;
            loglog(gui.data.dataH_Sector3, gui.data.dataE_Sector3, ...
                color3, 'Linewidth', LWval); hold on;
            loglog(gui.data.dataH_Sector4, gui.data.dataE_Sector4, ...
                color4, 'Linewidth', LWval); hold off;
        else
            plot(gui.data.dataH_Sector1, gui.data.dataE_Sector1, ...
                color1, 'Linewidth', LWval); hold on;
            plot(gui.data.dataH_Sector2, gui.data.dataE_Sector2, ...
                color2, 'Linewidth', LWval); hold on;
            plot(gui.data.dataH_Sector3, gui.data.dataE_Sector3, ...
                color3, 'Linewidth', LWval); hold on;
            plot(gui.data.dataH_Sector4, gui.data.dataE_Sector4, ...
                color4, 'Linewidth', LWval); hold off;
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
        
        if gui.config.plotThresLines
            xData_HThres = ones(1,2001) * gui.config.HVal_ThresLines;
            yData_HThres = 0:1:2000;
            xData_EThres = 0:1:200;
            yData_EThres = ones(1,201) * gui.config.EVal_ThresLines;
            plot(xData_HThres, yData_HThres, '-.k', 'Linewidth', LWval);
            hold on;
            plot(xData_EThres, yData_EThres, '--r', 'Linewidth', LWval);
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
elseif gui.config.plotClusters == 3
    if ~gui.config.plotSectMap
        if ~gui.config.flag_ClusterGauss
            data2use_HVec = reshape(data2use_H, size(data2use_H,1) * ...
                size(data2use_H,2), 1);
            data2use_EVec = reshape(data2use_E, size(data2use_E,1) * ...
                size(data2use_E,2), 1);
            data2use_HVec(~any(~isnan(data2use_HVec), 2),:)=0;
            data2use_EVec(~any(~isnan(data2use_EVec), 2),:)=0;
            K = gui.config.K_GMM;
            [labels, model, data] = GMMClustering(K, ...
                [data2use_HVec, data2use_EVec]);
            % Reverse labelling (1 for low values and 2 for high values)
            if K == 2
                labels = labels + 1; %label = 1 becomes 2 --> Hard phase
                labels(labels==3) = 1; % label = 2 becomes 1 --> Soft phase
            elseif K ==3
                labels(labels==1) = 4;
                labels = labels - 1;
                labels(labels==2) = 0;
                labels(labels==1) = 2;
                labels(labels==0) = 1;
            end
            %gui.data.dataE_SectorVec = data(labels,2);
            gui.data.dataH_Sector = reshape(data(labels,1),size(data2use_H,1),size(data2use_H,2));
            gui.data.dataE_Sector = reshape(data(labels,2),size(data2use_E,1),size(data2use_E,2));
            gui.data.dataHminInd = [];gui.data.dataHmaxInd = [];
            gui.data.dataHminInd = find(data(labels,1)==min(data(labels,1)));
            gui.data.dataHmaxInd = find(data(labels,1)==max(data(labels,1)));
            gui.data.dataH(1) = (round(10*min(data(labels,1))))/10;
            gui.data.dataE(1) = (round(10*data(labels(gui.data.dataHminInd(1)),2)))/10;
            gui.data.dataH(2) = (round(10*max(data(labels,1))))/10;
            gui.data.dataE(2) = (round(10*data(labels(gui.data.dataHmaxInd(1)),2)))/10;
            gui.data.dataH_SectorLabVec = labels;
            gui.data.dataH_SectorLabMat = reshape(labels,size(data2use_H,1),size(data2use_H,2));
            for evenIndex = 2:2:size(data2use_H,2)
                gui.data.dataH_Sector(:,evenIndex) = ...
                    flipud(gui.data.dataH_Sector(:,evenIndex));
                %                     gui.data.dataE_Sector(:,evenIndex) = ...
                %                         flipud(gui.data.dataE_Sector(:,evenIndex));
                gui.data.dataH_SectorLabMat(:,evenIndex) = ...
                    flipud(gui.data.dataH_SectorLabMat(:,evenIndex));
            end
            gui.data.dataH_SectorVec = data;
            gui.config.flag_ClusterGauss = 1;
        end
        colorList = [0 0 1; 1 0 0; 0 1 0]; %b r g
        if mean(gui.data.dataH_SectorVec(gui.data.dataH_SectorLabVec==1,1)) > mean(gui.data.dataH_SectorVec(gui.data.dataH_SectorLabVec==2,1))
            gui.data.dataH = fliplr(gui.data.dataH);
            gui.data.dataE = fliplr(gui.data.dataE);
        end
        cla;
        for k = 1:gui.config.K_GMM
            hPlot(k) = plot(gui.data.dataH_SectorVec(gui.data.dataH_SectorLabVec==k,1),...
                gui.data.dataH_SectorVec(gui.data.dataH_SectorLabVec==k,2),...
                '+', 'color', colorList(k,:), 'Linewidth', LWval);
            hold on;
            if get(gui.handles.cb_plotEllipse_GUI, 'Value')
                fit_ellipse(gui.data.dataH_SectorVec(gui.data.dataH_SectorLabVec==k,1),...
                    gui.data.dataH_SectorVec(gui.data.dataH_SectorLabVec==k,2), ...
                    gca, k);
                hold on;
                legCellInfo = strcat('H = ',num2str(gui.data.dataH(k)), gui.config.strUnit_Property, ...
                    ' / E = ',num2str(gui.data.dataE(k)), gui.config.strUnit_Property);
                legendInfo{k} = legCellInfo{:};
            end
        end
        if get(gui.handles.cb_plotEllipse_GUI, 'Value')
            legend(hPlot(:),legendInfo);
        end
    else
        cla;
        guidata(gcf, gui);
        TriDiMap_plot;
    end
end
if ~gui.config.plotSectMap
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
end