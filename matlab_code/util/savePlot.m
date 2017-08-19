%% Copyright 2014 MERCIER David
function savePlot(pathStr, nameFile, plotName)
% Function to save map with or without axes

saveas(gcf,[pathStr,nameFile,'_',plotName],'png');
set(gca,'position',[0 0 1 1],'units','normalized')
saveas(gcf,[pathStr,nameFile,'_',plotName,'_cropped'],'png');


%% Saving results
if config.flag_data
    assignin('base', 'TriDiMap_results', gui);
    display('Results are saved in the Matlab workspace in TriDiMap_results variable.');
end

end