function iqr_value = iqrVal(x)

y = sort(x);

% compute 25th percentile (first quartile)
q(1) = median(y(find(y<median(y))));

% compute 50th percentile (second quartile)
q(2) = median(y);

% compute 75th percentile (third quartile)
q(3) = median(y(find(y>median(y))));

% compute Interquartile Range (IqR)
iqr_value = q(3)-q(1);

end