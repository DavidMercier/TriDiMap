function g = MMGate( varargin )
% MMGate - selects rows of x nearest (in some sense) a centroid
%
%       g = MMGate
%       g = MMGate(g)
%       g = MMGate( type, method, crit, group )
%       g = MMGate( type, method, crit, group, mmodel )
%
% supported types are 'none', 'inclusion', and 'exclusion'
% supported methods, (pseudo-)metrics. 
%     'nearest and distance'      % both nearest and distance      
%     'nearest'                   % based on mah      
%     'distance'                  % mah < crit        
%     'unclustered'               % not within crit of any named cluster
%     'most likely'               % based on prob     
%     'probability'               % prob > crit  
%
% Example
%   % find points near cluster 1
%
%   [X idx theta] = mmvn_gen( 1000, [0 5; 5 0; 5 5; 0 0] );
%   mm = em(MModel( X, [], 4 )); 
%   g = MMGate( 'inclusion', 'nearest', 2, 1 );
%   [i X1] = gate(g, mm);
%   plot( X(:,1), X(:,2), '.', 'color', [.8 .8 .8] ); hold on;
%   plot( X(i,1), X(i,2), 'r.' );

if nargin == 0
    g.type   = 'none';
    g.method = 0;
    g.crit   = 2;
    g.group  = 1;
elseif nargin == 1 && isa(varargin{1}, 'Gate')
    g = varargin{1};
    return;
elseif nargin >= 4;
    g.type   = checkType( varargin{1} );
    g.method = checkMethod( varargin{2} );
    g.crit   = checkCrit( varargin{3} );
    if nargin == 5 && isa( varargin{5}, 'MModel' )
        g.group  = checkGroup( varargin{4}, varargin{5} );
    else
        g.group = varargin{4};
    end
else
    error( 'FacsMM:Gate:Constructor', 'no such constructor available' );
end
      
    
g = class(g,'MMGate');