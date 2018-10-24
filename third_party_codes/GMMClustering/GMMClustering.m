% University of Malta
% CSA3220 - Machine Learning, Expert Systems, & Fuzzy Logic
% Dr. George Azzopardi
% December, 2015

% Clustering with Gaussian Mixture Models
% Input parameter K is the number of Gaussian functions used
function [labels, model, data] = GMMClustering(K, x, varargin)

% Default value of K is 2
if nargin == 1
    x = getData;
end

if nargin == 0
    x = getData;
    K = 2;
end

N = size(x,1);
nfeatures = size(x,2);

%Step 1 - initialize means with KMeans
[labels,mu] = kmeans(x,K);

% Compute weights and covariance matrices using MLE
for k = 1:K
    weight(k) = sum(labels == k)/N;
    Sigma{k} = cov(x(labels==k,:));
end

convergence = 0;
t = 1;

%figure;
while t==1 || ~convergence %convergence criteria
    
    % Step 2: Expectation - Compute posteriors of each cluster
    for n = 1:N
        for k = 1:K
           posterior(n,k) = weight(k) * mmvn_pdf(x(n,:),mu(k,:),Sigma{k});
        end
        posterior(n,:) = posterior(n,:)./sum(posterior(n,:));
    end
        
    visualize(x,mu,Sigma,posterior);
    
    % Step 3: Maximization; i.e. update model parameters (means, covariances
    % matrices and weights
    for k = 1:K
        % Update means        
        sp(k) = sum(posterior(:,k));
        mu(k,:) = sum(bsxfun(@times,posterior(:,k),x))/sp(k);
        
        % Update covariance matrices
        Sigma{k} = zeros(nfeatures,nfeatures);
        for n = 1:N
            Sigma{k} = Sigma{k} + posterior(n,k)*(x(n,:)-mu(k,:))'*(x(n,:)-mu(k,:));
        end
        Sigma{k} = Sigma{k}./sp(k);                              
    end
    %Update the weights
    weight = sp./sum(sp);
          
    % Step 4: Evaluation - compute log likelihood
    llh(t) = 0;
    for i = 1:n
        innerterm = 0;
        for k = 1:K
            innerterm = innerterm + (weight(k) * mmvn_pdf(x(i,:),mu(k,:),Sigma{k}));
        end
        llh(t) = llh(t) + log(innerterm);
    end
    llh(t) = llh(t) / n;
    
    if t > 1
        convergence = (llh(t) - llh(t-1)) < 0.000001;
    end
    t = t + 1;            
end

visualize(x,mu,Sigma,posterior);

model.means = mu;
model.covariances = Sigma;
model.weights = weight;
data = x;
[~,labels] = max(posterior,[],2);
    
% % Show the clustered data
% colorList = jet(K);
% %figure;hold on;
% for k = 1:K
%     plot(data(labels==k,1),data(labels==k,2),'k+','color',colorList(k,:));
% end

% Create 3 Gaussian distributions
function Data = getData
A1 = mvnrnd([-1,0.3],[.5 .4;.4 .6],1000);
A2 = mvnrnd([-3,0.3],[.5 .4;.4 .6],1000);
A3 = mvnrnd([-2,0.5],[.5 -.4;-.4 .6],1000);
Data = [A1;A2;A3];

% Visualize the determined distributions
function visualize(data,mu,Sigma,posterior)
cla;
[~,labels] = max(posterior,[],2);

%gscatter(data(:,1),data(:,2),labels);
hold on;
for k = 1:size(posterior,2)
    F = @(x,y) mmvn_pdf([x y],mu(k,:),Sigma{k});
    fcontour(F);%,[min(data(:,1)),max(data(:,1))],[min(data(:,2)),max(data(:,2))]);
end
%drawnow;