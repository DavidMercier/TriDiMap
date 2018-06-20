%% Copyright 2014 MERCIER David
function y = cdfGaussian(x,sigma,mu)
%% Function to plot cdf written by A. Hillhorst

y = zeros(length(mu),length(x));
for ii = 1:1:length(mu)
    y(ii,:) = (1+erf((x-mu(ii))/(sigma(ii)*sqrt(2))))/2;
end
end