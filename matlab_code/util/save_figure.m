%% Copyright 2014 MERCIER David
function save_figure
%% Function to save figure from the GUI
gui = guidata(gcf);

if isfield(gui.config,'property')
    if gui.config.property == 1
        property = 'E';
    elseif gui.config.property == 2
        property = 'H';
    elseif gui.config.property == 3
       property = 'EvsH';
    elseif gui.config.property == 4
       property = 'E_pdf';
    elseif gui.config.property == 5
       property = 'H_pdf';
    elseif gui.config.property == 6
       property = 'E_cdf';
    elseif gui.config.property == 7
       property = 'H_cdf';
    end
end
%% Definition of path and filenames
if gui.config.data_path
    pathname_sav_fig = gui.config.data_path;
    if isfield(gui.config,'property')
        if ~gui.config.flagZplot
            filename_sav_fig1 = [gui.config.name, '_' ,property, '_GUI'];
            filename_sav_fig2 = [gui.config.name, '_' ,property, '_map'];
            filename_sav_fig3 = [gui.config.name, '_' ,property, '_mapCropped'];
        else
            filename_sav_fig1 = [gui.config.name, '_' ,property, '_GUI_Zplot'];
            filename_sav_fig2 = [gui.config.name, '_' ,property, '_map_Zplot'];
            filename_sav_fig3 = [gui.config.name, '_' ,property, '_mapCropped_Zplot'];
        end
        isolated_figure_title1 = fullfile(pathname_sav_fig, filename_sav_fig1);
        isolated_figure_title2 = fullfile(pathname_sav_fig, filename_sav_fig2);
        isolated_figure_title3 = fullfile(pathname_sav_fig, filename_sav_fig3);
    end
    
    filename_sav_fig4 = [gui.config.name, '_' , '_binarizedMaps'];
    isolated_figure_title4 = fullfile(pathname_sav_fig, filename_sav_fig4);
    filename_sav_fig4a = [gui.config.name, '_' , '_binEMap'];
    filename_sav_fig4b = [gui.config.name, '_' , '_binHMap'];
    filename_sav_fig4c = [gui.config.name, '_' , '_binMicroMap'];
    filename_sav_fig4d = [gui.config.name, '_' , '_binDiffEMicroMap'];
    filename_sav_fig4e = [gui.config.name, '_' , '_binDiffHMicroMap'];
    filename_sav_fig4f = [gui.config.name, '_' , '_binDiffEHMap'];
    isolated_figure_title5(1,:) = {fullfile(pathname_sav_fig, filename_sav_fig4a)};
    isolated_figure_title5(2,:) = {fullfile(pathname_sav_fig, filename_sav_fig4b)};
    isolated_figure_title5(3,:) = {fullfile(pathname_sav_fig, filename_sav_fig4c)};
    isolated_figure_title5(4,:) = {fullfile(pathname_sav_fig, filename_sav_fig4d)};
    isolated_figure_title5(5,:) = {fullfile(pathname_sav_fig, filename_sav_fig4e)};
    isolated_figure_title5(6,:) = {fullfile(pathname_sav_fig, filename_sav_fig4f)};
    
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
        
        for ii = 1:6
            hNewFig = figure;
            gui.config.saveFlagBin = ii;
            guidata(gcf, gui);
            TriDiMap_runBin;
            pause(2);
            delete(findall(findall(gcf,'Type','axe'),'Type','text'));
            axis off; box off;
            set(gca,'units','normalized','position',[0 0 1 1]);
            export_fig(char(isolated_figure_title5(ii, :)), isolate_axes(gca));
            close(hNewFig);
        end
    end
    
    set(0, 'currentfigure', gui.handles.MainWindow);
    gui.config.saveFlagBin = 0;
    guidata(gcf, gui);
else
    errordlg(['First set indentation grid parameters and load an Excel file '...
        'to plot a property map !']);
end

end