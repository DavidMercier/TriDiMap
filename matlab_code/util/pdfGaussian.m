%% Copyright 2014 MERCIER David
function y = pdfGaussian(x,mu,sigma)
%% Function to plot pdf written by A. Hillhorst

% Return NaN for out of range parameters.
sigma(sigma <= 0) = NaN;

y = zeros(length(mu),length(x));
for ii = 1:1:length(mu)
    y(ii,:) = exp(-0.5*((x-mu(ii)).^2)/sigma(ii)^2)/sqrt(2*pi*sigma(ii));
end

end