function x = subsref( v, S )
% SUBSREF - provides read access to MMView data 
%

% $Id: subsref.m,v 1.1 2007/04/19 23:32:43 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com
% 

if strcmp( S(1).type,'()' )
    error( 'MModel:subsref', '() not supported');
elseif strcmp( S(1).type, '.')
    switch( S(1).subs)
        case 'mm'
            x = v.mm;
        case 'view'
            x = v.view;
        case 'dims'
            x = v.dims;
            
        otherwise
            error( 'MModel:subsref', 'illegal access');            
    end;
end
if length( S) > 1
    x = subsref( x, S(2:end) );
end
