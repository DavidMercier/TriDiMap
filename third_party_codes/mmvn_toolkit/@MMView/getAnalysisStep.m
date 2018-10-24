function as = getAnalysisStep( v )
% getAnalysisStep - build an analysis step based on the best parameterscurrent model and view
%

mm = opt_init( v.mm );
as = AnalysisStep( [], v.dims, v.view, mm, 0);


