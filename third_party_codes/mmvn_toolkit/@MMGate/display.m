function display( g )
%DISPLAY Display method for MMGate objects.
%
%    DISPLAY(OBJ) displays information pertaining to the MMGate object.
%
% $Id: display.m,v 1.1 2007/04/19 23:32:41 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com


methods = {                                         % binary
    'none'
    'nearest and distance'                          % 3
    'nearest'                   % based on mah      % 1
    'distance'                  % mah < crit        % 2
    'unclustered'               % 
    'most likely'               % based on prob     % 4
    'probability'               % prob > crit       % 8
    };

group = g.group;
if isnumeric(group) 
    group = num2str(group);
end;
   


str = sprintf( '%s filter\nevents from class %s \n%s method \ncrit = %.2f', ...
                g.type,  ...
                group,   ...
                methods{g.method+1},  ...
                g.crit );

disp(str);