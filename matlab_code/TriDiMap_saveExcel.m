%% Copyright 2014 MERCIER David
function TriDiMap_saveExcel
%% Function to plot match as a function of all threshold

g = guidata(gcf);
sz1 = size(g.data.data2plot,1);
sz2 = size(g.data.data2plot,2);
sZFac = sz1*sz2;

if g.config.flag_data
    
    maxProperty = 2;
    % Reshape matrices
    dataFlipped = zeros(size(g.data.data2plot,1),size(g.data.data2plot,2),maxProperty);
    for ii = 1:1:maxProperty
        set(g.handles.property_GUI, 'Value', ii);
        guidata(gcf, g);
        TriDiMap_runPlot;
        g = guidata(gcf);
        
        dataFlipped(:,:,ii) = g.data.data2plot;
        if mod(length(g.data.data2plot),2) == 1
            for jj = 2:2:size(g.data.data2plot,2)-1
                dataFlipped(:,jj,ii) = flipud(dataFlipped(:,jj,ii));
            end
        elseif mod(length(g.data.data2plot),2) == 0
            for jj = 2:2:size(g.data.data2plot,2)
                dataFlipped(:,jj,ii) = flipud(dataFlipped(:,jj,ii));
            end
        end
    end
    
    % Create variable to write into .xls file
    dataReshaped(:,1:maxProperty) = zeros(sZFac,maxProperty);
    meanVal = zeros(1,maxProperty);
    stdVal = zeros(1,maxProperty);
    covVal = zeros(1,maxProperty);
    allTest = 1:1:sZFac;
    testVal = cellstr(strcat('T', num2str(allTest(:))));
    for ii = 1:1:maxProperty
        dataReshaped(:,ii) = reshape(dataFlipped(:,:,ii), [sZFac,1]);
        meanVal(1,ii) = mean(dataReshaped(:,ii));
        stdVal(1,ii) = std(dataReshaped(:,ii));
        covVal(1,ii) = cov(dataReshaped(:,ii))/100;
    end
    
    col_header_1 = {'Test','Avg Modulus','Avg Hardness'};
    col_header_2 = {' ','GPa','GPa'};
    row_header(1:3,1) = {'Mean','Std. Dev.','% COV'};
    
    % Generate .xls file
    ipFacStr = [num2str(sz1),'x',num2str(sz2)];
    smFacStr = get_value_popupmenu(g.handles.pm_smoothMap_GUI, listSmooth);
    valInterp = get(g.handles.cb_interpMap_GUI, 'Value');
    valSmooth = get(g.handles.cb_smoothMap_GUI, 'Value');
    if valInterp == 1
        fileName = [g.data.filename_data,'_interp_',ipFacStr];
    elseif valSmooth == 1
        fileName = [g.data.filename_data,'_smooth_x',smFacStr];
    elseif valInterp == 1 && valSmooth == 1
        fileName = [g.data.filename_data,'_interp_',ipFacStr,'smooth_x',smFacStr];
    elseif g.config.flagZplot
        fileName = [g.data.filename_data,'_ZPlot'];
    elseif g.config.flagCrop
        fileName = [g.data.filename_data,'_crop_',ipFacStr];
    else
        fileName = [g.data.filename_data,'_NoModification'];
    end
    fileName = [fileName, '.xls'];
    
    pwd = cd(g.data.pathname_data);
    xlswrite(fileName,col_header_1,'Results','A1');
    xlswrite(fileName,col_header_2,'Results','A2');
    xlswrite(fileName,testVal,'Results','A3');
    xlswrite(fileName,dataReshaped(:,:),'Results','B3');
    xlswrite(fileName,row_header,'Results', ...
        ['A', num2str((sZFac)+3)]);
    xlswrite(fileName,meanVal(:,:),'Results', ...
        ['B', num2str((sZFac)+3)]);
    xlswrite(fileName,stdVal(:,:),'Results', ...
        ['B', num2str((sZFac)+4)]);
    xlswrite(fileName,covVal(:,:),'Results', ...
        ['B', num2str((sZFac)+5)]);
    
    Message = 'Results were exported in .xls file !';
    display(Message);
    msgbox(Message);
    
    cd(pwd);
end

end