%% Copyright 2014 MERCIER David
function [expValuesInterp, expValuesSmoothed, expValuesInterpSmoothed] = ...
    TriDiMap_interpolation_smoothing(...
    expValues, interpolBool, interpolFac, ...
    smoothBool, smoothFact)
%% Function to interpolate, to smooth and to binarize a 3D dataset
% REMARKS %
% Don't set a too high number of points to smooth rows and columns...
% or the absolute maximum/minimum values are decreasing !

% x_step and y_step: Steps between indents in X and Y axis in microns.
% expValues: Values of experimental properties obtained by indentation in GPa.
% interpol: Boolean to interpolate values of the grid
% interpolFac: Interpolation factor to "smooth" data vizualization
% smoothCorrection: Boolean to correct values after smoothing
% smoothVal: Number of points used to smooth respectively rows and columns (Nc and Nr)

%% Interpolation - Definition of pixels coordinates
if ~interpolBool
    interpolFac = 0;
end
if size(expValues,1) == 1
    expValuesInterp = interpn(expValues',interpolFac,'linear');
else
    expValuesInterp = interp2(expValues,interpolFac);
end
maxValInterpol = max(max(expValuesInterp));
minValInterpol = min(min(expValuesInterp));
meanValInterpol = mean(mean(expValuesInterp));

%% Data smoothing
expValuesSmoothed = smooth2a(expValuesInterp, smoothFact, smoothFact);
maxValSmoothed = max(max(expValuesSmoothed));
minValSmoothed = min(min(expValuesSmoothed));
meanValSmoothed = mean(mean(expValuesSmoothed));

%% Correction of loss after smoothing step
deltaMax = (maxValInterpol - maxValSmoothed);
deltaMin = (minValInterpol - minValSmoothed);
expValuesInterpSmoothed = zeros(size(expValuesInterp,1), size(expValuesInterp,2));
meanValexpValuesInterpSmoothed= mean(mean(expValuesInterpSmoothed));
criterion = meanValexpValuesInterpSmoothed;

for ii=1:size(expValuesInterp,1)
    for jj=1:size(expValuesInterp,2)
        %if binarizedGrid == 0
        if smoothBool
            if expValuesInterp(ii,jj) < criterion
                expValuesInterpSmoothed(ii,jj) = ...
                    expValuesSmoothed(ii,jj) - ...
                    ((expValuesSmoothed(ii,jj) - expValuesInterp(ii,jj)) / ...
                    (expValuesInterp(ii,jj)/minValInterpol));
                
            elseif expValuesInterp(ii,jj) > criterion
                expValuesInterpSmoothed(ii,jj) = ...
                    expValuesSmoothed(ii,jj) + ...
                    ((expValuesInterp(ii,jj) - expValuesSmoothed(ii,jj)) * ...
                    (expValuesInterp(ii,jj)/maxValInterpol));
            else
                expValuesInterpSmoothed(ii,jj) = expValuesSmoothed(ii,jj);
            end
        else
            expValuesInterpSmoothed(ii,jj) = expValuesInterp(ii,jj);
        end
        
        %         elseif binarizedGrid == 1
        %             if expValuesInterp(ii,jj) < criterion
        %                 expValuesInterpSmoothed(ii,jj) = ...
        %                     expValuesSmoothed(ii,jj) + deltaMin;
        %
        %                 %                 expValuesInterpSmoothed(ii,jj) = ...
        %                 %                      expValuesSmoothed(ii,jj) + ...
        %                 %                     (expValuesInterp(ii,jj) - expValuesSmoothed(ii,jj));
        %                 % ==> Residual map equals zero
        %
        %             elseif expValuesInterp(ii,jj) > criterion
        %                 expValuesInterpSmoothed(ii,jj) = ...
        %                     expValuesSmoothed(ii,jj) + deltaMax;
        %
        %             else
        %                 expValuesInterpSmoothed(ii,jj) = expValuesSmoothed(ii,jj);
        %             end
        %
        %         elseif binarizedGrid == 2
        %             if expValuesInterp(ii,jj) < criterion
        %                 expValuesInterpSmoothed(ii,jj) = minValInterpol;
        %
        %             elseif expValuesInterp(ii,jj) >= criterion
        %                 expValuesInterpSmoothed(ii,jj) = maxValInterpol;
        %             end
        %         end
    end
end

end