%% Copyright 2014 MERCIER David
function TriDiMap_runZplot
%% Function to run the 3D plot (surface and cross-sectional maps)
gui = guidata(gcf);
prompt = {'Enter number of files to load for cross-sectional mapping'};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'5'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
gui.config.flagZplot = 1;
guidata(gcf, gui);

if ~isempty(answer) && str2num(answer{:}) > 1
    if ~isempty(answer)
        gui = guidata(gcf);
        for ii = 1:str2num(answer{:})
            % Get surface information
            TriDiMap_loadingData;
            csVal(ii) = guidata(gcf);
            pwd = cd(gui.data.pathname_data);
            %save(['cs_meanVal', num2str(ii)], 'csVal');
            cd(pwd);
        end
        
        cla;
        
        for ii = 1:str2num(answer{:})
            %load(['cs_meanVal', num2str(ii), '.mat']);
            gui.data3D.meanZVal_YM(:,ii) = nanmean(csVal(ii).data.expValues_mat.YM);
            gui.data3D.meanZVal_H(:,ii) = nanmean(csVal(ii).data.expValues_mat.H);
        end
        
        % set(gui.handles.pm_pixData_GUI, 'Value', 1);
        % TriDiMap_runPlot;
        % daspect([1 1 100]);
        % view([20 20]);
        
        set(gui.handles.value_numXindents_GUI, 'String', num2str(length(gui.data3D.meanZVal_YM)));
        set(gui.handles.value_numYindents_GUI, 'String', num2str(ii));
        set(gui.handles.value_MaxXCrop_GUI, 'String', num2str(length(gui.data3D.meanZVal_YM)));
        set(gui.handles.value_MaxYCrop_GUI, 'String', num2str(ii));
        
        gui.config.flagZplot = 1;
        guidata(gcf, gui);
        
        TriDiMap_runPlot;
        
    else
        display('No 3D data loaded !');
    end
elseif ~isempty(answer)
    if str2num(answer{:}) < 2
        errordlg('Load more than 1 file for Z plot !');
    end
end