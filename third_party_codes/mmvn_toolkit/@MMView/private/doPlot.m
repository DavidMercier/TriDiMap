function [v xnew] = doPlot( v )
%DOPLOT internal function to plot mm data. 
%

% $Id: doPlot.m,v 1.3 2007/05/21 22:57:16 mboedigh Exp $
% Copyright 2006 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com
% 

hold off;
newplot

% subset columns
x = v.mm.x(:,v.dims);


colors = v.prism;
set(gca,'colororder',colors);
colormap(colors);

% plot data
[i xnew] = gate( v.view, v.mm );

if strcmp( v.view.type, 'none' )
    c = [0.05 0.05 0.05 ];
else
    c = colors(groupi(v.view, v.mm),:);
end


% draw unselected first so selected show up better
h{2} = plot( x(~i,1), x(~i,2), ...
             'marker',    '.', ...
             'linestyle', 'none', ...
             'markersize',  1, ...
             'color',       [.2 .2 .2] );
set(h{2},'hittest','off');
hold on;

ssize = v.ssize;

h{1} = plot( x(i,1), x(i,2), ...
             'marker',    '.', ...
             'linestyle', 'none', ...
             'markersize',  ssize, ...
             'color',      c );

set(h{1},'hittest','off');


% plot ellipses
%    plot ellipses if view shows unique dimensions included in 
%    the model

s = v.mm.s;           % model dims
g(s==1) = 1:sum(s);     % convert dimensions of x -> dimensions in model

[theta, isopt] = getTheta(v.mm);
if isopt
    ls = '-';
else
    ls = '-.';
end

if length(unique(v.dims)) == length(v.dims) && all(s(v.dims))
    v  = createClusterMenu(v);
    
    eh = ellipse( theta.M, theta.V, g(v.dims) );
    set(eh, 'linestyle', ls, 'linewidth', 2);
    h{3} = eh;
    set(eh(:,1),'hittest', 'off');
    legend( eh(:,1), v.mm.knames, 'location', 'northeastoutside' );
    v = createEllipseMenu( v, eh(:,2) );
elseif length(unique(v.dims)) == length(v.dims) && sum(s(v.dims))==1
    if s(v.dims(1))         % x-axis shows viewed model dim
        d = g(v.dims(1));
        m = theta.M(:,d);
        s2 = theta.V(d,d,:);
        q = get(gca,'xlim');
        p = get(gca,'ylim');
        xx = linspace( q(1), q(2), 100 )';
        yy = mmvn_pdf( xx, m, s2 );  
        % scale xx to fill up xlim
        yy = yy.*p(2)*.9./max(yy(:));
        h{3} = plot(xx,yy);
        
    elseif s(v.dims(2))    % y-axis shows vieded model dim
        d = g(v.dims(2));
        m = theta.M(:,d);
        s2 = theta.V(d,d,:);
        q = get(gca,'ylim');
        p = get(gca,'xlim');
        yy = linspace( q(1), q(2), 100 )';
        xx = mmvn_pdf( yy, m, s2 );  
        % scale xx to fill up xlim
        xx = xx.*.9*p(2)./max(xx(:));
        h{3} = plot(xx,yy);
    end
    legend( h{3}, v.mm.knames, 'location', 'northeastoutside' );
    v = createEllipseMenu( v, h{3} );
    
    
else
    v = createExtDimMenu(v);
    h{3} = [];
end

% add optimization information
if ~isempty( v.mm.L )
    [xpos, ypos] = getAxisInset( 0.01, 0.95 );
    str = sprintf( 'LogL = %2.2f', v.mm.L );
    text(xpos, ypos, str );
end;

hold off;

addLabelDropDowns( v.labels(v.dims), v.labelMenus );

view.selh           = h{1};       % selected scatter points
view.unselh         = h{2};       % unselected
view.ellipseh       = h{3};       % ellipses
set(gca,'userdata', v );          % save data


