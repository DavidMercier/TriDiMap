function f = normal_gaussian_pdf(x,m,sig)
% % this code is written by Jamal A. Hussein
% % barznjy79@yahoo.com
% % all rights reserved
%
% clc; clear all; close all;
%
% colors=['r','g','b'] ;
% m = 0;
% sig = [0.25 0.6 1];
% x = -5:0.05:5;

f=zeros(1,length(x));

for w = 1:length(sig)
    for ii = 1:length(x)
        f(ii) = 1/(sig(w)*sqrt(2*pi)) .* ...
            exp(-((x(ii)-m)^2 / (2*(sig(w))^2)));
    end
    %
    % plot(x,f,colors(w))
    % hold on
    
end

% xlabel('x');
% ylabel('PDF');
% title('probability density function')
% hleg1 = legend('sigma=0.25','sigma=0.6','sigma=1');
% set(hleg1,'Location','NorthEast')
% axis([-5 5 0 2]);
% grid on

end