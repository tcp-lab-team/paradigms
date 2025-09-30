function [codeDir, COMPSDir] = setupPaths()
    % Get this function's directory (folder where this setupPaths function lives)
    functionsDir = fileparts(mfilename('fullpath')); % functions folder
    
    % Navigate up to get parent and root project folders
    codeDir = fileparts(functionsDir);   % code folder
    COMPSDir = fileparts(codeDir);       % root project folder
        
    % Add subfolders to the MATLAB path
    addpath(fullfile(codeDir, 'screens'));
end
