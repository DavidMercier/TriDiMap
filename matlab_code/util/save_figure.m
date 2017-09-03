%% Copyright 2014 MERCIER David
function save_figure
%% Function to save figure from the GUI
gui = guidata(gcf);

if gui.config.property == 1
    property = 'E';
elseif gui.config.property == 2
    property = 'H';
end

%% Definition of path and filenames
pathname_sav_fig = gui.config.data_path;
filename_sav_fig1 = [gui.config.name, '_' ,property, '_GUI'];
filename_sav_fig2 = [gui.config.name, '_' ,property, '_map'];
filename_sav_fig3 = [gui.config.name, '_' ,property, '_mapCropped'];
filename_sav_fig4 = [gui.config.name, '_' ,property, '_binarizedMaps'];
filename_sav_fig4a = [gui.config.name, '_' ,property, '_binPropMap'];
filename_sav_fig4b = [gui.config.name, '_' ,property, '_binMicroMap'];
filename_sav_fig4c = [gui.config.name, '_' ,property, '_binDiffMap'];
isolated_figure_title1 = fullfile(pathname_sav_fig, filename_sav_fig1);
isolated_figure_title2 = fullfile(pathname_sav_fig, filename_sav_fig2);
isolated_figure_title3 = fullfile(pathname_sav_fig, filename_sav_fig3);
isolated_figure_title4 = fullfile(pathname_sav_fig, filename_sav_fig4);
isolated_figure_title4a = fullfile(pathname_sav_fig, filename_sav_fig4a);
isolated_figure_title4b = fullfile(pathname_sav_fig, filename_sav_fig4b);
isolated_figure_title4c = fullfile(pathname_sav_fig, filename_sav_fig4c);

%% Map
if strcmp(get(gui.handles.binarization_GUI, 'String'), 'BINARIZATION')
    % Exportation of the figures in a .png format
    export_fig(isolated_figure_title1, gcf);
    display(strcat('Figure saved as: ', filename_sav_fig1));
    export_fig(isolated_figure_title2, isolate_axes(gca));
    display(strcat('Figure saved as: ', filename_sav_fig2));
    
    hNewFig = figure;
    %copyobj(gui.handles.AxisPlot_GUI,hNewFig);
    %     set(0, 'currentfigure', hNewFig);
    %     axis;
    %     set(hNewFig,'CurrentAxes', gca);
    gui.config.saveFlag = 1;
    guidata(gcf, gui);
    TriDiMap_runPlot;
    pause(2);
    delete(findall(findall(gcf,'Type','axe'),'Type','text'));
    axis off; box off;
    set(gca,'units','normalized','position',[0 0 1 1]);
    export_fig(isolated_figure_title3, isolate_axes(gca));
    display(strcat('Figure saved as: ', filename_sav_fig3));
    close(hNewFig);
    
    %% Binarized images
else
    export_fig(isolated_figure_title4, gcf);
    display(strcat('Figure saved as: ', filename_sav_fig4));
    
    hNewFig = figure;
    gui.config.saveFlagBin = 1;
    guidata(gcf, gui);
    TriDiMap_runBin;
    pause(2);
    delete(findall(findall(gcf,'Type','axe'),'Type','text'));
    axis off; box off;
    set(gca,'units','normalized','position',[0 0 1 1]);
    export_fig(isolated_figure_title4a, isolate_axes(gca));
    display(strcat('Figure saved as: ', filename_sav_fig4a));
    close(hNewFig);
    
    hNewFig = figure;
    gui.config.saveFlagBin = 2;
    guidata(gcf, gui);
    TriDiMap_runBin;
    pause(2);
    delete(findall(findall(gcf,'Type','axe'),'Type','text'));
    axis off; box off;
    set(gca,'units','normalized','position',[0 0 1 1]);
    export_fig(isolated_figure_title4b, isolate_axes(gca));
    display(strcat('Figure saved as: ', filename_sav_fig4b));
    close(hNewFig);
    
    hNewFig = figure;
    gui.config.saveFlagBin = 3;
    guidata(gcf, gui);
    TriDiMap_runBin;
    pause(2);
    delete(findall(findall(gcf,'Type','axe'),'Type','text'));
    axis off; box off;
    set(gca,'units','normalized','position',[0 0 1 1]);
    export_fig(isolated_figure_title4c, isolate_axes(gca));
    display(strcat('Figure saved as: ', filename_sav_fig4c));
    close(hNewFig);
end

set(0, 'currentfigure', gui.handles.MainWindow);
gui.config.saveFlagBin = 0;
guidata(gcf, gui);

end