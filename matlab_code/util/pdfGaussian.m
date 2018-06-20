%% Copyright 2014 MERCIER David
function y = pdfGaussian(x,sigma,mu)
%% Function to plot pdf written by A. Hillhorst

y = zeros(length(mu),length(x));
for ii = 1:1:length(mu)
    y(ii,:) = exp(-((x-mu(ii)).^2)/2/sigma(ii)^2)/sqrt(2*pi*sigma(ii)^2);
end
end