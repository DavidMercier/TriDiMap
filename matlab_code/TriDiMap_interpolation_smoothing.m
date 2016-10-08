%% Copyright 2014 MERCIER David
function [expValuesInterp, expValuesSmoothed, expValuesInterpSmoothed] = ...
    TriDiMap_interpolation_smoothing(...
    expValues, interpolBool, interpolFac, ...
    smoothBool, smoothFact, binarizedGrid, criterion, varargin)
%% Function to interpolate, to smooth and to binarize a 3D dataset
% x_step and y_step: Steps between indents in X and Y axis in microns.
% expValues: Values of experimental properties obtained by indentation in GPa.
% interpol: Boolean to interpolate values of the grid
% interpolFac: Interpolation factor to "smooth" data vizualization
% binarizedGrid: Boolean to binarize values of the grid
% smoothCorrection: Boolean to correct values after smoothing
% smoothVal: Number of points used to smooth respectively rows and columns (Nc and Nr)

if nargin < 6
    binarizedGrid = 1;
end

if nargin < 5
    smoothFact = 2;
end

if nargin < 4
    smoothBool = 1;
end

if nargin < 3
    %interpolFac = 0; % for no interpolation
    interpolFac = 2;
end

if nargin < 2
    interpolBool = 1;
end

if nargin < 1
    %expValues = randi(101,101);
    expValues = peaks(51);
end

%% Interpolation - Definition of pixels coordinates
if ~interpolBool
    interpolFac = 0;
end
expValuesInterp = interp2(expValues,interpolFac);
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

for ii=1:size(expValuesInterp,1)
    for jj=1:size(expValuesInterp,2)
        if binarizedGrid == 0
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
            
        elseif binarizedGrid == 1
            if expValuesInterp(ii,jj) < criterion
                expValuesInterpSmoothed(ii,jj) = ...
                    expValuesSmoothed(ii,jj) + deltaMin;
                
                %                 expValuesInterpSmoothed(ii,jj) = ...
                %                      expValuesSmoothed(ii,jj) + ...
                %                     (expValuesInterp(ii,jj) - expValuesSmoothed(ii,jj));
                % ==> Residual map equals zero
                
            elseif expValuesInterp(ii,jj) > criterion
                expValuesInterpSmoothed(ii,jj) = ...
                    expValuesSmoothed(ii,jj) + deltaMax;
                
            else
                expValuesInterpSmoothed(ii,jj) = expValuesSmoothed(ii,jj);
            end
            
        elseif binarizedGrid == 2
            if expValuesInterp(ii,jj) < criterion
                expValuesInterpSmoothed(ii,jj) = minValInterpol;
                
            elseif expValuesInterp(ii,jj) >= criterion
                expValuesInterpSmoothed(ii,jj) = maxValInterpol;
            end
        end
    end
end

end