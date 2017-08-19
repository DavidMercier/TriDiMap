%% Copyright 2014 MERCIER David
function TriDiMap_fractionData
%% Function to get fraction of each phases
gui = guidata(gcf);

dataType = gui.config.binarizedGrid;
if dataType
    if gui.config.property == 1
        criterion_YM = 250;
        %criterion_YM = mean(mean(gui.data.YM.expValuesInterpSmoothed));
        data = gui.data.YM.expValuesInterpSmoothed;
    else
        criterion_H = 7;
        %criterion_H = mean(mean(gui.data.YM.expValuesInterpSmoothed));
        data = gui.data.H.expValuesInterpSmoothed;
    end
    
    if gui.config.fracCalc == 1
        YM_binarized = zeros(gui.config.N_XStep_default, gui.config.N_YStep_default);
        H_binarized = zeros(gui.config.N_XStep_default, gui.config.N_YStep_default);
        for ii = 1:1:gui.config.N_XStep_default
            for jj = 1:1:gui.config.N_YStep_default
                if gui.data.YM.expValuesInterpSmoothed(ii,jj) > criterion_YM
                    YM_binarized(ii,jj) = 255;
                else
                    YM_binarized(ii,jj) = 0;
                end
                if gui.data.H.expValuesInterpSmoothed(ii,jj) > criterion_H
                    H_binarized(ii,jj) = 255;
                else
                    H_binarized(ii,jj) = 0;
                end
            end
        end
        if gui.config.property == 1
            gui.data.data2plot = YM_binarized;
        elseif gui.config.property == 2
            gui.data.data2plot = H_binarized;
        end
    end
    
    if dataType == 1
        str = 'elastic modulus';
    elseif dataType == 2
        str = 'hardness';
    end
    
    ind = find(data <=criterion);
    fractionMin = length(ind)/(length(data)^2);
    fractionMax = 1 - fractionMin;
    display(['Fraction of phase with lower ', str, ': ']);
    disp(fractionMin);
    display(['Fraction of phase with higher ', str, ': ']);
    disp(fractionMax);
    
    legendStr = gui.config.Legend;
    fracCalc = gui.config.fracCalc;
    
    if fracCalc
        cmap = [1,1,1;0,0,0]; % Black and white
    else
    end
    
    % From mapping plotting
    if fracCalc
        %set(hcb1,'YTick',[0:maxVal/2:maxVal]);
        legendBinaryMap('w', 'k', 's', 's', legendStr, FontSizeVal);
    end
    if rawData && fracCalc
        fracBW = sum(sum(data2plot))/(size(data2plot,1)*size(data2plot,2)*255);
        display(['Fraction of particles (', zString, ' map) :']);
        disp(fracBW);
        display(['Fraction of matrix (', zString, ' map) :']);
        disp(1-fracBW);
    end
end

end