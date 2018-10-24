function flag = checkFit( mm, theta )
%CHECKFIT compares mixture model means to a target mixture model given in
%theta.
%
% flag = checkFit( mm, theta ) a scalar indicating consistency between two parameter sets
%   0 = ok
%   1 = class label swap
%   2 = relative location change
%   3 = constant shifts

bopt= getTheta(mm);
k   = size(bopt.M,1);

if nargin > 1
    b0 = theta;
else
    b0 = mm.b0;
end

% sort results
% the first gaussian is closest to the first seed, etc
d2 = mah( bopt.M, b0.M, b0.V );
[dmin, i] = min(d2, [], 2 );


j = find(i' ~= 1:k);%#ok - i don't understand lint's tip
flag = 0;
if ~isempty(j)
    % locations have swapped
    flag = 1;
elseif any(dmin > 9 )
    if any( var(bopt.M - b0.M) > 9 )
        % relative locations have changed
        flag = 2;
    else
        % locations have shifted
        flag = 3;
    end
end;
