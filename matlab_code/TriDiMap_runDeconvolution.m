%% Copyright 2014 MERCIER David
function TriDiMap_runDeconvolution(E, exphist, M, maxiter, limit, property, ...
    strUnit_Property)
%% Function to run the deconvolution
%See Decon M-file for decon.fig of J N?me?ek

% E: load property, e.g. E[GPa], save to vector E
% exphist: load experimental probability density function
% M: Number of phases
% maxiter: max number of iterations
% limit: precision

%----------------
%---Deconvolution algorithm
%-----------------
norma2=1;
minnorma=1;
%minmeze=1;
%minprumer=1;
%minstddev=1;
%minf=1;
iter=0;

maxE=max(E); %maximum value in E vector
N=length(E); %dimension of E vector

while( (norma2>limit) && (iter<=maxiter))
    r=rand(M-1,1); %nahodny vektor M-1 cisel 0,1
    r=sort(r); %vzestupne serazeny vektor r
    meze(1)=0;  %prvni mez je na nule
    pom= maxE .* r; % generace M-1 mezi z nahodneho vektoru
    for i=1:M-1;
        meze(i+1)=pom(i);  % generace M-1 mezi
    end
    meze(M+1)=maxE; %posledni mez
    
    sE=sort(E); %vzestupne serazeny vektor E
    
    for i=1:M+1
        index_meze(i)=N; %naplni vektor indexu maximalni hodnotou
    end
    index_meze(1)=0; %index pred prvni mezi je nula
    
    j=2; %zacinam od druhe meze (prvni je nula)
    mez=meze(j);
    
    for i=1:N %cyklus pres vsechny hodnoty
        if (sE(i) > mez)
            index_meze(j)=i-1; %ulozi index hodnoty, ktera lezi pod mezi
            j=j+1;
            mez=meze(j);
        end
    end
    
    x=exphist(1,1); %prvni kategorie
    for i=1:M %cyklus pres faze
        vektor=sE(index_meze(i)+1:index_meze(i+1));
        if (length(vektor)>1)
            prumer(i) = mean(vektor);
            stddev(i) = std(vektor);
        else
            prumer(i) = 0;
            stddev(i) = 0;
        end
        f(i)=length(vektor)/N; %fraction
    end
    
    for j=1:M %cyklus pres faze
        x=exphist(1,1);
        if (prumer(j)~=0)
            %p(1,j)=cdf('normal',x,prumer(j), stddev(j)); %cdf pro prvni kategorii
            p2(1,j)=pdf('normal',x,prumer(j), stddev(j)); %pdf
        else
            %p(1,j)=0;
            p2(1,j)=0;
        end
        
        for i = 2 : length(exphist)  %cyklus pres vsechny kategorie
            x_prev=exphist(i-1,1);
            x=exphist(i,1);
            if (prumer(j)~=0)
                p2(i,j)=pdf('normal',x,prumer(j), stddev(j))*f(j);
            else
                p2(i,j)=0;
            end
        end
        
    end
    
    norma2=0;
    for i = 1 : length(exphist)
        p_all2(i)=0;
        for j=1:M %cyklus pres faze
            p_all2(i)=p_all2(i)+p2(i,j);
        end
        norma2=norma2+(exphist(i,2)-p_all2(i))^2 * exphist(i,2)^2;
    end
    
    iter=iter+1;
    
    %onscreen output during iteration
    
    %Show text
    %t=strcat('Iteration: ' , num2str(iter))
    %set(handles.text25_iter,'String',num2str(iter-1) );
    %set(handles.text28_norm,'String', num2str(norma2) );
    drawnow;
    
    if(norma2<minnorma)
        % output if precision was reached
        minnorma=norma2;
        minmeze=meze;
        minprumer=prumer;
        minstddev=stddev;
        minf=f;
        %Show text output and graph
        %axes(handles.graf_decon); %plots the x and y data
        cla;
        plot(exphist(:,1), exphist(:,2),'-ko');
        hold on; %legend ('show');
        
        %delete all lists
        %         set(handles.dist1,'String', '-' );
        %         set(handles.dist2,'String', '-' );
        %         set(handles.dist3,'String', '-' );
        %         set(handles.dist4,'String', '-' );
        %         set(handles.dist5,'String', '-' );
        %         set(handles.dist6,'String', '-' );
        
        for  j=1:M
            t=sprintf('%8.3f\n%8.3f\n%8.3f\n', minprumer(j), minstddev(j), minf(j));
            switch j
                case 1
                    %set(handles.dist1,'String', t );
                    plot(exphist(:,1),p2(:,1),'b');
                case 2
                    %set(handles.dist2,'String', t );
                    plot(exphist(:,1),p2(:,2),'r');
                case 3
                    %set(handles.dist3,'String', t );
                    plot(exphist(:,1),p2(:,3),'g');
                case 4
                    %set(handles.dist4,'String', t );
                    plot(exphist(:,1),p2(:,4),'y');
                case 5
                    %set(handles.dist5,'String', t );
                    plot(exphist(:,1),p2(:,5),'m');
                case 6
                    %set(handles.dist6,'String', t );
                    plot(exphist(:,1),p2(:,6),'c');
                otherwise ;
            end
        end
        plot(exphist(:,1),p_all2,':');
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
        
        if property == 4
            xlabel(strcat('Elastic modulus (',strUnit_Property, ')'));
        elseif property == 5
            xlabel(strcat('Hardness (',strUnit_Property, ')'));
        end
        ylabel('Frequency density');
    end
end
end