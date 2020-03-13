%% Copyright 2014 MERCIER David
function cumulativeFunction = TriDiMap_MinWeibull_cdf(OPTIONS, xdata_fit, ydata_fit)
%% Function giving the Weibull cumulative distribution function
% See http://de.mathworks.com/help/stats/wblcdf.html
% See Weibull W., “A statistical distribution function of wide applicability”, J. Appl. Mech.-Trans. ASME (1951), 18(3).

gui = guidata(gcf);

cumulativeFunction = struct();
cumulativeFunction.xdata_cdf_Fit = xdata_fit;

% Model (mortal function)
weibull_cdf_m = @(p,x) (1 - exp(-(x./p(2)).^p(1)));

% Make a starting guess of coefficients p(1) and p(2)
% p(1) = Weibull modulus --> 10 when good homogeneity in size defect distribution
% p(2) = Mean value
cumulativeFunction.p0 = [1; mean(xdata_fit)];

if gui.config.licenceOpt_Flag
    [cumulativeFunction.coefEsts, ...
        cumulativeFunction.resnorm, ...
        cumulativeFunction.residual, ...
        cumulativeFunction.exitflag, ...
        cumulativeFunction.output, ...
        cumulativeFunction.lambda, ...
        cumulativeFunction.jacobian] =...
        lsqcurvefit(weibull_cdf_m, cumulativeFunction.p0, ...
        cumulativeFunction.xdata_cdf_Fit, ydata_fit, ...
        [gui.config.numerics.Min_mWeibull ; 0], ...
        [gui.config.numerics.Max_mWeibull ; max(xdata_fit)], ...
        OPTIONS);
else
    model = @LMS;
    cumulativeFunction.coefEsts = fminsearch(model, cumulativeFunction.p0);
    warning('No Optimization toolbox available !');
end

    function [sse, FittedCurve] = LMS(params)
        p(1) = params(1);
        p(2) = params(2);
        FittedCurve = 1 - exp(-(cumulativeFunction.xdata_cdf_Fit./p(2)).^p(1));
        ErrorVector = FittedCurve - ydata_fit;
        sse = sum(ErrorVector .^ 2);
    end

cumulativeFunction.coefEsts(1) = ...
    real(cumulativeFunction.coefEsts(1));
cumulativeFunction.coefEsts(2) = ...
    real(cumulativeFunction.coefEsts(2));

cumulativeFunction.ydata_cdf_Fit = ...
    (1 - exp(-(cumulativeFunction.xdata_cdf_Fit./cumulativeFunction.coefEsts(2)) ...
    .^ cumulativeFunction.coefEsts(1)));

end