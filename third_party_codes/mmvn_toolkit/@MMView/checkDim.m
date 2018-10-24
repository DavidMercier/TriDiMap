function i = checkDim(g, i )
%CHECKDIM - error check view dimensions 
%

% $Id: checkDim.m,v 1.1 2007/04/19 23:32:42 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com
% 

if ~isnumeric(i)  || any(i > size(g.mm.x,2))
    error( 'FacsMM:AnalysisStep:BadConstructor', 'Bad dim' );
end
