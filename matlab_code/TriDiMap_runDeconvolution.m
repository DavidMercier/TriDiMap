%% Copyright 2014 MERCIER David
function TriDiMap_runDeconvolution(propVal, exphist, M, maxIter, limit, property, ...
    strUnit_Property)
%% Function to run the deconvolution
% See decon M-file for decon.fig of J. Nemecek

% propVal: load property, e.g. E[GPa], save to vector propVal
% exphist: load experimental probability density function
% M: Number of phases
% maxIter: max number of iterations
% limit: precision
gui = guidata(gcf);

norma2 = 1;
minnorma = 1;
iter=0;

minE = min(exphist(:,1));
maxE = max(propVal);
N = length(propVal);

while((norma2>limit) && (iter<=maxIter)) && ...
        get(gui.handles.cb_deconvolutionHist_GUI, 'Value');
    r = rand(M-1,1);
    r = sort(r);
    Lim = zeros(1,M+1);
    Lim(1) = 0;
    pom = maxE .* r;
    for ii = 1:M-1;
        Lim(ii+1) = pom(ii);
    end
    Lim(M+1) = maxE;
    
    sE = sort(propVal);
    index_Lim = zeros(1,ii);
    for ii = 1:M+1
        index_Lim(ii) = N;
    end
    index_Lim(1)=0;
    
    jj = 2;
    mez = Lim(jj);
    
    for ii = 1:N
        if (sE(ii) > mez)
            index_Lim(jj) = ii-1;
            jj = jj+1;
            mez = Lim(jj);
        end
    end
    
    x = exphist(1,1);
    meanVec = zeros(1,M);
    stddev = zeros(1,M);
    for ii = 1:M
        Vect = sE(index_Lim(ii)+1:index_Lim(ii+1));
        if (length(Vect) > 1)
            meanVec(ii) = mean(Vect);
            stddev(ii) = std(Vect);
        else
            meanVec(ii) = 0;
            stddev(ii) = 0;
        end
        f(ii)=length(Vect)/N;
    end
    
    for jj = 1:M
        x = exphist(1,1);
        if (meanVec(jj) ~= 0)
            %p2(1,jj) = cdf('normal',x,meanVec(jj),stddev(jj));
            p2(1,jj) = pdf('normal',x,meanVec(jj),stddev(jj));
        else
            p2(1,jj) = 0;
        end
        
        for ii = 2 : length(exphist)
            x_prev = exphist(ii-1,1);
            x = exphist(ii,1);
            if (meanVec(jj)~=0)
                p2(ii,jj) = pdf('normal',x,meanVec(jj),stddev(jj))*f(jj);
            else
                p2(ii,jj) = 0;
            end
        end
        
    end
    
    norma2 = 0;
    p_all2 = zeros(1,length(exphist));
    for ii = 1 : length(exphist)
        p_all2(ii) = 0;
        for jj = 1:M
            p_all2(ii) = p_all2(ii)+p2(ii,jj);
        end
        norma2 = norma2+(exphist(ii,2)-p_all2(ii))^2 * exphist(ii,2)^2;
    end
    
    iter = iter+1;
    
    maxXPos = 1.2*round(max(exphist(:,1))*1000)/1000;
    maxYPos = 1.2*round(max(exphist(:,2))*1000)/1000;
    %t0 = sprintf('Iter. %i\nPrec. %f', iter - 1, norma2);
    drawnow;
    
    if(norma2 < minnorma)
        minnorma = norma2;
        minLim = Lim;
        minmeanVec = meanVec;
        minstddev = stddev;
        minf=f;
        
        set(gui.handles.value_IterResHist_GUI, 'String', num2str(iter - 1));
        set(gui.handles.value_PrecHistRes_GUI, 'String', num2str(norma2));
        cla;
        %text(0.025*(maxXPos)+minE,maxYPos,char(t0));hold on;
        h1 = plot(exphist(:,1), exphist(:,2),'-ko','LineWidth',2);
        hold on;
        
        for jj = 1:M
            t = sprintf('Phase %i\n%8.3f\n%8.3f\n%8.3f\n', jj, minmeanVec(jj), minstddev(jj), minf(jj));
            switch jj
                case 1
                    text(0.05*(maxXPos)+minE,maxYPos,char(t));hold on;
                    h2 = plot(exphist(:,1),p2(:,1),'b','LineWidth',2);
                case 2
                    text(0.15*(maxXPos)+minE,maxYPos,char(t));hold on;
                    h3 = plot(exphist(:,1),p2(:,2),'r','LineWidth',2);
                case 3
                    text(0.25*(maxXPos)+minE,maxYPos,char(t));hold on;
                    h4 = plot(exphist(:,1),p2(:,3),'g','LineWidth',2);
                case 4
                    text(0.35*(maxXPos)+minE,maxYPos,char(t));hold on;
                    h5 = plot(exphist(:,1),p2(:,4),'y','LineWidth',2);
                case 5
                    text(0.45*(maxXPos)+minE,maxYPos,char(t));hold on;
                    h6 = plot(exphist(:,1),p2(:,5),'m','LineWidth',2);
                case 6
                    text(0.55*(maxXPos)+minE,maxYPos,char(t));hold on;
                    h7 = plot(exphist(:,1),p2(:,6),'c','LineWidth',2);
                otherwise ;
            end
            hold on;
        end
        h8 = plot(exphist(:,1),p_all2,':','LineWidth',2);
        hold on;
        switch M
            case 1
                legend ('Experiment','#1','Overall PDF');
            case 2
                legend ('Experiment','#1','#2','Overall PDF');
            case 3
                legend ('Experiment','#1','#2','#3','Overall PDF');
            case 4
                legend ('Experiment','#1','#2','#3','#4','Overall PDF');
            case 5
                legend ('Experiment','#1','#2','#3','#4','#5','Overall PDF');
            case 6
                legend ('Experiment','#1','#2','#3','#4','#5','#6','Overall PDF');
            otherwise ;
        end
        legend boxoff;
        
        if property == 4
            xlabel(strcat('Elastic modulus (',strUnit_Property, ')'));
        elseif property == 5
            xlabel(strcat('Hardness (',strUnit_Property, ')'));
        end
        ylabel('Frequency density');
    end
    ylim([0 1.2*maxYPos]);
end
if get(gui.handles.cb_deconvolutionHist_GUI, 'Value');
    msgbox('Deconvolution completed');
else
    msgbox('Deconvolution aborted');
end
end