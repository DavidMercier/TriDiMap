%% Copyright 2014 MERCIER David
function cumulativeFunction = TriDiMap_MinGaussian_cdf(OPTIONS, xdata_fit, ydata_fit)
%% Function giving the Gaussian cumulative distribution function

gui = guidata(gcf);

cumulativeFunction = struct();
cumulativeFunction.xdata_cdf_Fit = xdata_fit;

% Model
Gaussian_cdf_m = @(p,x) (1+erf((x-p(1))/(p(2)*sqrt(2))))/2;

% Make a starting guess of coefficients p(1) and p(2)
% p(1) = Mean value
% p(2) = Standard deviation
cumulativeFunction.p0 = [1; mean(xdata_fit)];

if gui.config.licenceOpt_Flag
    [cumulativeFunction.coefEsts, ...
        cumulativeFunction.resnorm, ...
        cumulativeFunction.residual, ...
        cumulativeFunction.exitflag, ...
        cumulativeFunction.output, ...
        cumulativeFunction.lambda, ...
        cumulativeFunction.jacobian] =...
        lsqcurvefit(Gaussian_cdf_m, cumulativeFunction.p0, ...
        cumulativeFunction.xdata_cdf_Fit, ydata_fit, ...
        [gui.config.numerics.Min_mGaussian ; 0], ...
        [gui.config.numerics.Max_mGaussian ; max(xdata_fit)], ...
        OPTIONS);
else
    model = @LMS;
    cumulativeFunction.coefEsts = fminsearch(model, cumulativeFunction.p0);
    warning('No Optimization toolbox available !');
end

    function [sse, FittedCurve] = LMS(params)
        p(1) = params(1);
        p(2) = params(2);
        FittedCurve = (1+erf((cumulativeFunction.xdata_cdf_Fit-p(1))/(p(2)*sqrt(2))))/2;
        ErrorVector = FittedCurve - ydata_fit;
        sse = sum(ErrorVector .^ 2);
    end

cumulativeFunction.coefEsts(1) = ...
    real(cumulativeFunction.coefEsts(1));
cumulativeFunction.coefEsts(2) = ...
    real(cumulativeFunction.coefEsts(2));

cumulativeFunction.ydata_cdf_Fit = ...
    (1+erf((cumulativeFunction.xdata_cdf_Fit-...
    cumulativeFunction.coefEsts(1))/(cumulativeFunction.coefEsts(2)*sqrt(2))))/2;

end