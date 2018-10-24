function mm = setData( mm, x, resetfit )
% SETDATA set or clears the data from a mixture model. 
%
% setting a new data matrix reset the optimized parameters 
% 
% example
%       mm = setData( mm, x )
%          x is an m x n matrix
%          if mm.s is set, then x must be compatible, otherwise all n are
%          used in the model. Resets optimized fit results if any.
%       mm = setData( mm, [] )
%          removes data and derived mahalonbis distances from the mm
%          this is convient for more compact storage of the results of a
%          fit
%       mm = setData( mm, x, false )
%          x is an m x n matrix and mm isoptimized then sets the model data
%          to x and does not reset the optimized fit. Instead it uses the
%          optimized fit as starting parameters to run a new optimization.


% $Id: setData.m,v 1.2 2007/05/11 21:32:45 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com




if nargin < 2 || isempty(x)
    mm.x    = [];
    mm.d2   = [];    
    return;
end;



mm.x = x;
n = size(x,2);

if isempty(mm.s)        % x is being set for the first time and no
    mm.s = true(n,1);   % use all dimensions 
    mm   = setTheta(mm, repmat(x,mm.k,1), repmat(cov(x),[1 1 k]), ones(k,1)/k );
elseif n ~= length(mm.s)
    error('linstats:MModel:setTheta', 'parameter structure is incosistent with model dimensions');
elseif nargin < 3 || resetfit
    mm.L     = [];
    mm.bhat  = [];
    mm.u     = weightedMeans( mm );
    mm.d2    = mah(mm );
else
    w = weightedMeans(mm);
    if max( mm.u(:) - w(:)) > 1e-4
        error('linstats:MModel:wrongData', 'The data is inconsistent with the optimized fit');
    end
    mm.d2 = mah(mm);
end



