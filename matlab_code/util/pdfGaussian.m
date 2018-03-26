%% Copyright 2014 MERCIER David
function y = pdfGaussian(x,sigma,mu)
%% Function to plot pdf written by A. Hillhorst

y = zeros(length(mu),length(x));
for i=1:1:length(mu)
    y(i,:) = exp(-((x-mu(i)).^2)/2/sigma(i)^2)/sqrt(2*pi*sigma(i)^2);
end
end