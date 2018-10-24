function crit = checkCrit(crit)
%CHECKCRIT - internal function to error check crit for class MMGate
%
% checkCrit(obj)

% $Id: checkCrit.m,v 1.1 2007/04/19 23:32:42 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com

if ~isnumeric(crit) || ~isscalar(crit) || crit < 0 
    error('FacsMM:Gate:BadThreshold', 'crit must postive value');
end

