function addLabelDropDowns( labels, menus )
%ADDLABELDROPDOWNS creates context menus on axis labels

% $Id: addLabelDropDowns.m,v 1.1 2007/04/19 23:32:43 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com
% 
str = {'xlabel', 'ylabel', 'zlabel'};
for i = 1:min(3,length(labels) )
    lh = get(gca, str{i} );
    set( lh, 'string', labels{i}, ...
             'uicontextmenu', menus{i} );
end;
    