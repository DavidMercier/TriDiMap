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
isolated_figure_title1 = fullfile(pathname_sav_fig, filename_sav_fig1);
isolated_figure_title2 = fullfile(pathname_sav_fig, filename_sav_fig2);
isolated_figure_title3 = fullfile(pathname_sav_fig, filename_sav_fig3);

%% Exportation of the figures in a .png format
export_fig(isolated_figure_title1, gcf);
display(strcat('Figure saved as: ', filename_sav_fig1));
export_fig(isolated_figure_title2, isolate_axes(gca));
display(strcat('Figure saved as: ', filename_sav_fig2));

hNewFig = figure;
%copyobj(gui.handles.AxisPlot_GUI,hNewFig);
gui.config.saveFlag = 1;
guidata(gcf, gui);
TriDiMap_runPlot;
delete(findall(findall(gcf,'Type','axe'),'Type','text'));
axis off; box off;
set(gca,'units','normalized','position',[0 0 1 1]);
export_fig(isolated_figure_title3, isolate_axes(gca));
display(strcat('Figure saved as: ', filename_sav_fig3));
close(hNewFig);

end