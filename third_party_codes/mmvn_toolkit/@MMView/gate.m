function [i x] = gate( v )
% GATE - applies the current gate and returns the resutls
% 
% [i, x] = gate(v);
%   return i, a logical vector of accepted points and 
%   x a matrix of accepted rows
%
% this function is a simple wrapper for MMGate/gate
%  
% Example
%       see MMGate/gate for examples

% $Id: gate.m,v 1.2 2007/05/11 21:32:45 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com
% 

[i, x] = gate( v.view, v.mm );


