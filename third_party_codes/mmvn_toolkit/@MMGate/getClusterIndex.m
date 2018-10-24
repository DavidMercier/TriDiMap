function i = getClusterIndex( g, mm )
% GETCLUSTERINDEX returns a cluster index based on mah distance
%
% Example
%        i = getClusterIndex( g, mm )

% $Id: getClusterIndex.m,v 1.1 2007/04/19 23:32:41 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com

i      = ones( size(mm.x,1),1 );


if isempty(mm.x) || strcmp(g.type , 'none' );
    return;
end;


[mind2, i] = min( mm.d2, [], 2 );
