%% Copyright 2014 MERCIER David
function y = cdfGaussian(x,sigma,mu)
%% Function to plot cdf written by A. Hillhorst

y = zeros(length(mu),length(x));
for i=1:1:length(mu)
    y(i,:) = (1+erf((x-mu(i))/(sigma(i)*sqrt(2))))/2;
end
end