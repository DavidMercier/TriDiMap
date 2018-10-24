function b = isOptimized(mm)
%ISOPTIMIZED returns true if parameters have been optimized on this data

% $Id: isOptimized.m,v 1.1 2007/04/19 23:32:45 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com

b = ~isempty(mm.bhat);


