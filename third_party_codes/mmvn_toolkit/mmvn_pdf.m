function [p sp] = mmvn_pdf(X, varargin)
% MMVN_PDF Returns the density of a (mixture of) multivariate nomal probabilities
%
% The density for mixture of multivariate distributions is the
% weighted sum of the density of each component. 
%
% p = mmvn_pdf(X,theta)   
%     returns p, a n x k matrix of weighted probabilities for each class
%     X is a n x d matrix
%     Theta is a standard mmvn struct (see mmvn_getTheta)
% p = mmvn_pdf(X,M)   % provide k x d matrix of means and assume equal
%                     % weight and unit variance (uncorrelated)
% p = mmvn_pdf(X,M,V) % also provide d x d x k matrix of variances (equal
%                     % weight)
% p = mmvn_pdf(X,M,V,W) % proved k vector of weights. 
%
% [p sp] = mmvn_pdf(X, ...) 
%     also returns SP, a n-vector of sum of weighted probabilities for each
%     point in X
%
% Example
%     [X idx theta] = mmvn_gen( 10, [0 5; 5 0; 5 5; 0 0] );
%     [p sp] = mmvn_pdf(X, theta);
%
% See also mmvn_gen, mmvn_getTheta, mvn_pdfln, mmvn_expectation


theta = mmvn_getTheta( varargin{:} );

n     = size(X,1);
k     = size(theta.M,1);
p     = zeros(n,k);

for j = 1:k
    % calculate expectations
    if theta.W(j) == 0;
        p(:,j) = 0;
    else
        p(:,j) = theta.W(j).*mvn_pdf( X, theta.M(j,:), theta.V(:,:,j) );
    end
end;

if nargout > 1
    sp = sum(p,2);
end;


function p = mvn_pdf( X, M, V )

d = size(M,2);

k = d*log(2*pi);
[L r] = chol(V);

if r ~= 0
    [U S T] = svd(V);
    sd = diag(S);
    tol = length(sd)*eps(max(sd));
    r = sum(sd>tol);
    Vinv = T(:,1:r)*diag(1./sd(1:r))*U(1:r,:);

    ll = (k + sum(log( sd(1:r)) ) + (X-M)*Vinv*(X-M)' )/2;

    if s == 0
        error('linstats:mvn_lnpdf:NegativeVariance', 'Variance matrix must be non-negative definite');
    end
else
    k = d*log(2*pi);
    Xo = center(X,M);
    XL    = Xo/L;
    ll = (k + 2*sum(log(diag(L))) + sum( (XL).^2,2))/2;
end

p = exp(-ll);

