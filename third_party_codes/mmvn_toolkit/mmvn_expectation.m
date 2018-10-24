function [logL E p] = mmvn_expectation(X, varargin)
%MMVN_EXPECTATION The expectation step in Expectation Maximizations
%
% calculates the average log liklihood and related values
% 
% Example:
%  All examples include X, and other input parameters provide informatino
%  about the distrubution of X. X is a n x d matrix of n observations in d
%  dimensions. 
% logL  = mmvn_expectation(X,theta)      % provide mmvn struct
% logL  = mmvn_expectation(X, M )        % provide M  (assume equal W and
%                                        % unit V)
% logL  = mmvn_expectation(X, M, V)      % provide M and V (assume equal W)
% logL  = mmvn_expectation(X, M, V, W)   % provide M, V, and W
%         
% % LOGL  is the average log of the likelihood over all observations
% % [logL E p] = mmvn_expectation(...);
% %          also returns E, the scaled probabilities (each row sums to 1)
% %          also returns p, the row_totals of the probabilities
%
% See also mmvn_gen, mmvn_getTheta
%

%% $Id: mmvn_expectation.m,v 1.1 2007/04/19 23:32:52 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com

theta = mmvn_getTheta(varargin{:});

E = mmvn_pdf( X, theta );


% scale so sum(E,2) = 1;
p = sum(E,2);
p(p==0) = realmin;              % smallest p val we can represent. 
                                % E will still be 0, but logL wont be -Inf

logL = nanmean(log(p));
                                
if nargout > 1
    % TODO if all(E==0,2) it should probably be set to the previous W so that each obs still
    % sums to 1 and the weighted mean is calculated properly
    E = E./repmat(p,1,size(E,2)); 
end;


