%% Copyright 2014 MERCIER David
function [xData, yData] = TriDiMap_meshing(expValues, x_step, y_step)

xData = zeros(size(expValues,1), size(expValues,2));
xData(1) = 0;
for ii = 2:size(expValues,1)
    for jj = 1:size(expValues,2)
        xData(ii,jj) = xData(ii-1,1) + x_step;
    end
end

yData = zeros(size(expValues,2), size(expValues,1));
yData(1) = 0;
for ii = 2:size(expValues,2)
    for jj = 1:size(expValues,1)
        yData(ii,jj) = yData(ii-1,1) + y_step;
    end
end

end