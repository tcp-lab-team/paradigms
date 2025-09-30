function create_extractCurve
% This file is for internal use only.

%   Copyright 2018-2019 The MathWorks, Inc.

fileName = {'+signalwavelet/+internal/+tfridge/extractCurve'};
fprintf('Building %s ... \n',fileName{:});
buildMexFunction(fileName{:});

end

%% Build EML file into MEX Functions
function buildMexFunction(inputFileName)

% Set up coder config to target mex
cfg = coder.config('mex');
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;

[filePath,fileName] = fileparts(inputFileName);

% Write output file to tfridge folder
outputFileName = fullfile( matlabroot,'toolbox','shared','signalwavelet','signalwavelet',filePath,fileName);

% Create a temporary directory
tempDir = tempname;

for class = {'double' 'single'}
    fprintf('    ...for class %s...\n',class{:});
    switch class{:}
        case 'double'
            codegen(inputFileName, ...
                '-config',cfg, ...
                '-o',[outputFileName '_mx'], ...
                '-d',[tempDir '/' inputFileName '_mx'], ...
                '-args',{coder.typeof(1,[Inf Inf]),coder.typeof(1,[1 1])});
        case 'single'
            codegen(inputFileName, ...
                '-config',cfg, ...
                '-o',[outputFileName '_mxs'], ...
                '-d',[tempDir '/' inputFileName '_mxs'], ...
                '-args',{coder.typeof(single(1),[Inf Inf]),coder.typeof(single(1),[1 1])});        
    end
    
end
cleanup(tempDir);

end

function cleanup(tempDir)
rmdir(tempDir,'s');
end

% LocalWords:  tfridge mxs Func
