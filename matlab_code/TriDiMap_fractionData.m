%% Copyright 2014 MERCIER David
function TriDiMap_fractionData(data, dataType)
%% Function to get fraction of each phases

if dataType == 1
    str = 'elastic modulus';
elseif dataType == 2
    str = 'hardness';
end

ind = find(data <=mean(mean(data)));
fractionMin = length(ind)/(length(data)^2);
fractionMax = 1 - fractionMin;
display(['Fraction of phase with lower ', str, ': ']);
disp(fractionMin);
display(['Fraction of phase with higher ', str, ': ']);
disp(fractionMax);

end