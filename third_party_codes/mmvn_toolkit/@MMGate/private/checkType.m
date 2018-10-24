function type = checkType(type)
%CHECKTYPE - check gate type for class MMGate
%
% checkType(obj)

% $Id: checkType.m,v 1.1 2007/04/19 23:32:42 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com

types = {'inclusion', 'exclusion', 'none' };

if iscellstr(type) || ischar(type)
    b  = ismember( lower(type), types );
    if ~b
            error('FacsMM:Gate:BadGateType', 'type must be in inclusion, exclusion or none');
    end
    type = lower(type);
elseif ~ischar(type)
    error('FacsMM:Gate:BadGateType', 'type must a cellstr or char');
end

