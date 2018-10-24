function g = subsasgn( g, S, B )
%SUBSASGN provides write access to mmview class 



if strcmp( S(1).type,'()' )
    error( 'MModel:subsasgn', '() not supported');
elseif strcmp( S(1).type, '.')
    switch( S(1).subs)
        case 'bhat'
            g.bhat     = B;
        otherwise
            error( 'MModel:subsref', 'illegal access');
    end
end



