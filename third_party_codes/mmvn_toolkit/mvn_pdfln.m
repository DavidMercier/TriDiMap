function ll = mvn_pdfln( X, M, V )
%MVN_PDF returns the ln of the density of X, evaluated at M and V
%
% mean to replace the mvnpdf provided by mathworks, which underflows for
% very high dimensional data. 
% 
% Example
%  % generate a 1000 vector of observations where 
%  % y ~ N( 0, V);
%  % simulate V
%  V = randn(1000);
%  V = V'*V; % make sure it is positive definite;
% [X idx theta] = mmvn_gen( 1, zeros(1,1000), V );
% % get the log density at 
% ll = mvn_pdfln( X,theta.M(1,:), theta.V(:,:,1));  %useful for
% optimization
% p = exp(ll);      % underflows 

d = size(M,2);

k = d*log(2*pi);
[L r] = chol(V);

if r ~= 0
    [U S T] = svd(V);
    sd = diag(S);
    tol = length(sd)*eps(max(sd));
    r = sum(sd>tol);
    Vinv = T(:,1:r)*diag(1./sd(1:r))*U(1:r,:);

    ll = -(k + sum(log( sd(1:r)) ) + (X-M)*Vinv*(X-M)' )/2;

    if s == 0
        error('linstats:mvn_lnpdf:NegativeVariance', 'Variance matrix must be non-negative definite');
    end
else
    k = d*log(2*pi);
    Xo = center(X,M);
    XL    = Xo/L;
    ll = -(k + 2*sum(log(diag(L))) + sum( (XL).^2,2))/2;
end

