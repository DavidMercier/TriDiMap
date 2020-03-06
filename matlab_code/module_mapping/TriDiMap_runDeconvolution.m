%% Copyright 2014 MERCIER David
function [p2, p_all2, minmeanVec, minstddev, minf, pos] = TriDiMap_runDeconvolution(propVal, exphist, M, maxIter, limit, property, ...
    strUnit_Property, flagStat)
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
iter = 0;

minVal = min(exphist(:,1));
maxVal = max(propVal);
N = length(propVal);

while((norma2 > limit) && (iter <= maxIter)) && ...
        get(gui.handles.cb_deconvolutionHist_GUI, 'Value')
    r = rand(M-1,1);
    r = sort(r);
    Lim = zeros(1,M+1);
    Lim(1) = 0;
    pom = maxVal .* r;
    for ii = 1:M-1
        Lim(ii+1) = pom(ii);
    end
    Lim(M+1) = maxVal;
    
    sVal = sort(propVal);
    index_Lim = zeros(1,ii);
    for ii = 1:M+1
        index_Lim(ii) = N;
    end
    index_Lim(1) = 0;
    
    jj = 2;
    mez = Lim(jj);
    
    for ii = 1:N
        if (sVal(ii) > mez)
            index_Lim(jj) = ii-1;
            jj = jj+1;
            mez = Lim(jj);
        end
    end
    
    meanVec = zeros(1,M);
    stddev = zeros(1,M);
    f = zeros(1,M);
    for ii = 1:M
        Vect = sVal(index_Lim(ii)+1:index_Lim(ii+1));
        if (length(Vect) > 1)
            meanVec(ii) = mean(Vect);
            stddev(ii) = std(Vect);
        else
            meanVec(ii) = 0;
            stddev(ii) = 0;
        end
        f(ii) = length(Vect)/N;
    end
    
    p2 = zeros(length(exphist),M);
    for jj = 1:M
        x = exphist(1,1);
        if (meanVec(jj) ~= 0)
            if flagStat
                %p2(1,jj) = pdf('normal',x,meanVec(jj),stddev(jj));
                p2(ii,jj) = normpdf(x,meanVec(jj),stddev(jj));
            else
                p2(ii,jj) = pdfGaussian(x,meanVec(jj),stddev(jj));
            end
        else
            p2(ii,jj) = 0;
        end
        
        for ii = 2 : length(exphist)
            %x_prev = exphist(ii-1,1);
            x = exphist(ii,1);
            if (meanVec(jj)~=0)
                if flagStat
                    %p2(ii,jj) = pdf('normal',x,meanVec(jj),stddev(jj))*f(jj);
                    p2(ii,jj) = normpdf(x,meanVec(jj),stddev(jj))*f(jj);
                else
                    p2(ii,jj) = pdfGaussian(x,meanVec(jj),stddev(jj))*f(jj);
                end
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
        %minLim = Lim;
        minmeanVec = meanVec;
        minstddev = stddev;
        minf = f;
        
        set(gui.handles.value_IterResHist_GUI, 'String', num2str(iter - 1));
        set(gui.handles.value_PrecHistRes_GUI, 'String', num2str(norma2));
        cla;
        %text(0.025*(maxXPos)+minE,maxYPos,char(t0));hold on;
        if ~get(gui.handles.cb_colorHist_GUI, 'Value')
            %h1 = plot(exphist(:,1), exphist(:,2),'-ko','LineWidth',2);
            h1 = bar(exphist(:,1), exphist(:,2),'FaceColor','none',...
                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5); %Unicolor barchart
            hold on;
        end
        
        for jj = 1:M
            t = sprintf('Phase %i\n%8.3f\n%8.3f\n%8.3f\n', jj, minmeanVec(jj), minstddev(jj), minf(jj));
            switch jj
                case 1
                    ht1 = text(0.05*(maxXPos)+minVal,maxYPos,char(t));hold on;
                    if get(gui.handles.cb_colorHist_GUI, 'Value')
                        if M > 1
                            if ~(sum(p2(:,jj+1))==0)
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj) & p2(:,jj+1)>p2(:,jj)),1));
                            else
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj))));
                            end
                            indX(jj) = nanmin(find(exphist(:,1) >= X_intercepVec(jj)));
                            h11 = bar(exphist(1:indX(jj),1), ...
                                exphist(1:indX(jj),2), 'FaceColor','b',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        else
                            h11 = bar(exphist(:,1), ...
                                exphist(:,2), 'FaceColor','b',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        end
                    end
                    hold on;
                    h2 = plot(exphist(:,1),p2(:,jj),'b','LineWidth',2);
                case 2
                    ht2 = text(0.15*(maxXPos)+minVal,maxYPos,char(t));hold on;
                    if get(gui.handles.cb_colorHist_GUI, 'Value')
                        if M > 2
                            if ~(sum(p2(:,jj+1))==0)
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj) & p2(:,jj+1)>p2(:,jj)),1));
                            else
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj))));
                            end
                            indX(jj) = nanmin(find(exphist(:,1) >= X_intercepVec(jj)));
                            h12 = bar(exphist(indX(jj-1):indX(jj),1), ...
                                exphist(indX(jj-1):indX(jj),2), 'FaceColor','r',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        else
                            h12 = bar(exphist(indX(jj-1):end,1), ...
                                exphist(indX(jj-1):end,2), 'FaceColor','r',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        end
                    end
                    hold on;
                    h3 = plot(exphist(:,1),p2(:,jj),'r','LineWidth',2);
                case 3
                    ht3 = text(0.25*(maxXPos)+minVal,maxYPos,char(t));hold on;
                    if get(gui.handles.cb_colorHist_GUI, 'Value')
                        if M > 3
                            if ~(sum(p2(:,jj+1))==0)
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj) & p2(:,jj+1)>p2(:,jj)),1));
                            else
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj))));
                            end
                            indX(jj) = nanmin(find(exphist(:,1) >= X_intercepVec(jj)));
                            h13 = bar(exphist(indX(jj-1):indX(jj),1), ...
                                exphist(indX(jj-1):indX(jj),2), 'FaceColor','g',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        else
                            h13 = bar(exphist(indX(jj-1):end,1), ...
                                exphist(indX(jj-1):end,2), 'FaceColor','g',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        end
                    end
                    hold on;
                    h4 = plot(exphist(:,1),p2(:,jj),'g','LineWidth',2);
                case 4
                    ht4 = text(0.35*(maxXPos)+minVal,maxYPos,char(t));hold on;
                    if get(gui.handles.cb_colorHist_GUI, 'Value')
                        if M > 4
                            if ~(sum(p2(:,jj+1))==0)
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj) & p2(:,jj+1)>p2(:,jj)),1));
                            else
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj))));
                            end
                            indX(jj) = nanmin(find(exphist(:,1) >= X_intercepVec(jj)));
                            h14 = bar(exphist(indX(jj-1):indX(jj),1), ...
                                exphist(indX(jj-1):indX(jj),2), 'FaceColor','y',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        else
                            h14 = bar(exphist(indX(jj-1):end,1), ...
                                exphist(indX(jj-1):end,2), 'FaceColor','y',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        end
                    end
                    hold on;
                    h5 = plot(exphist(:,1),p2(:,jj),'y','LineWidth',2);
                case 5
                    ht5 = text(0.45*(maxXPos)+minVal,maxYPos,char(t));hold on;
                    if get(gui.handles.cb_colorHist_GUI, 'Value')
                        if M > 5
                            if ~(sum(p2(:,jj+1))==0)
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj) & p2(:,jj+1)>p2(:,jj)),1));
                            else
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj))));
                            end
                            indX(jj) = nanmin(find(exphist(:,1) >= X_intercepVec(jj)));
                            h15 = bar(exphist(indX(jj-1):indX(jj),1), ...
                                exphist(indX(jj-1):indX(jj),2), 'FaceColor','m',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        else
                            h15 = bar(exphist(indX(jj-1):end,1), ...
                                exphist(indX(jj-1):end,2), 'FaceColor','m',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        end
                    end
                    hold on;
                    h6 = plot(exphist(:,1),p2(:,jj),'m','LineWidth',2);
                case 6
                    ht6 = text(0.55*(maxXPos)+minVal,maxYPos,char(t));hold on;
                    if get(gui.handles.cb_colorHist_GUI, 'Value')
                        if M > 6
                            if ~(sum(p2(:,jj+1))==0)
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj) & p2(:,jj+1)>p2(:,jj)),1));
                            else
                                X_intercepVec(jj) = nanmin(exphist((exphist(:,1) >= minmeanVec(jj))));
                            end
                            indX(jj) = nanmin(find(exphist(:,1) >= X_intercepVec(jj)));
                            h16 = bar(exphist(indX(jj-1):indX(jj),1), ...
                                exphist(indX(jj-1):indX(jj),2), 'FaceColor','c',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        else
                            h16 = bar(exphist(indX(jj-1):end,1), ...
                                exphist(indX(jj-1):end,2), 'FaceColor','c',...
                                'EdgeColor',[0.5 0.5 0.5], 'LineWidth', 1.5);
                        end
                    end
                    hold on;
                    h7 = plot(exphist(:,1),p2(:,jj),'c','LineWidth',2);
                otherwise
            end
            hold on;
        end
        if get(gui.handles.cb_colorHist_GUI, 'Value')
            if M > 0
                set(ht1, 'Color', 'b'); end
            if M > 1
                set(ht2, 'Color', 'r'); end
            if M > 2
                set(ht3, 'Color', 'g'); end
            if M > 3
                set(ht4, 'Color', 'y'); end
            if M > 4
                set(ht5, 'Color', 'm'); end
            if M > 5
                set(ht6, 'Color', 'c'); end
        else
            if M > 0
                set(ht1, 'Color', 'k'); end
            if M > 1
                set(ht2, 'Color', 'k'); end
            if M > 2
                set(ht3, 'Color', 'k'); end
            if M > 3
                set(ht4, 'Color', 'k'); end
            if M > 4
                set(ht5, 'Color', 'k'); end
            if M > 5
                set(ht6, 'Color', 'k'); end
        end
        h8 = plot(exphist(:,1),p_all2,'k:','LineWidth',2);
        hold on;
        switch M
            case 1
                if get(gui.handles.cb_colorHist_GUI, 'Value')
                    legend ('Experiment - P1','#1','Overall PDF');
                else
                end
            case 2
                if get(gui.handles.cb_colorHist_GUI, 'Value')
                    legend ('Experiment - P1','#1','Experiment - P2','#2','Overall PDF');
                else
                    legend ('Experiment','#1','#2','Overall PDF');
                end
            case 3
                if get(gui.handles.cb_colorHist_GUI, 'Value')
                    legend ('Experiment - P1','#1','Experiment - P2','#2','Experiment - P3','#3','Overall PDF');
                else
                    legend ('Experiment','#1','#2','#3','Overall PDF');
                end
            case 4
                if get(gui.handles.cb_colorHist_GUI, 'Value')
                    legend ('Experiment - P1','#1','Experiment - P2','#2','Experiment - P3','#3','Experiment - P4','#4','Overall PDF');
                else
                    legend ('Experiment','#1','#2','#3','#4','Overall PDF');
                end
            case 5
                if get(gui.handles.cb_colorHist_GUI, 'Value')
                    legend ('Experiment - P1','#1','Experiment - P2','#2','Experiment - P3','#3','Experiment - P4','#4','Experiment - P5','#5','Overall PDF');
                else
                    legend ('Experiment','#1','#2','#3','#4','#5','Overall PDF');
                end
            case 6
                if get(gui.handles.cb_colorHist_GUI, 'Value')
                    legend ('Experiment - P1','#1','Experiment - P2','#2','Experiment - P3','#3','Experiment - P4','#4','Experiment - P5','#5','Experiment - P6','#6','Overall PDF');
                else
                    legend ('Experiment','#1','#2','#3','#4','#5','#6','Overall PDF');
                end
            otherwise
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
    ylim([0 1.2]);
end
if get(gui.handles.cb_deconvolutionHist_GUI, 'Value')
    %msgbox('Deconvolution completed');
    title('Deconvolution process completed');
else
    %msgbox('Deconvolution aborted');
    title('Deconvolution process aborted');
end
pos = [minVal maxVal maxXPos maxYPos];
end