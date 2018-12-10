%% Copyright 2014 MERCIER David
function tridim_root = get_tridim_root
%% Get environment variable for NIMS

tridim_root = getenv('TRIDIM_TBX_ROOT');

if isempty(tridim_root)
    msg = 'Run the path_management.m script !';
    commandwindow;
    disp(msg);
    %errordlg(msg, 'File Error');
    error(msg);
end

end