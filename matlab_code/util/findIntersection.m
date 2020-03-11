%% Copyright 2014 MERCIER David
function [intersectionVal, yval] = findIntersection(pdfRes, varargin)
%% Function to find intersection between 2 PDFs

meanVal = pdfRes.minmeanVec;
stdDev = pdfRes.minstddev;

% See function y = pdfGaussian(x,mu,sigma) for more details
yfun = @(mu,sigma,x)exp(-0.5*((x-mu).^2)/sigma^2)/sqrt(2*pi*sigma);

intersectionVal = zeros(1,length(meanVal)-1);
for ii = 1:length(meanVal)-1
    intersectionVal(ii) = fzero(@(x) ...
        yfun(meanVal(ii), stdDev(ii), x) - yfun(meanVal(ii+1), stdDev(ii+1), x), ...
        mean([meanVal(ii:ii+1), stdDev(ii:ii+1)]));
end

yval = yfun(meanVal(1), stdDev(1), intersectionVal);

end