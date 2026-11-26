function limits = TriDiMap_pdfYLimits(values)
finite = values(isfinite(values));
if isempty(finite) || max(finite) <= 0
    warning('TriDiMap:EmptyPDFRange', ...
        'No positive finite histogram or PDF values are displayed; check the selected histogram range and bin size.');
    limits = [0, 1];
else
    limits = [0, 1.1*max(finite)];
end
end
