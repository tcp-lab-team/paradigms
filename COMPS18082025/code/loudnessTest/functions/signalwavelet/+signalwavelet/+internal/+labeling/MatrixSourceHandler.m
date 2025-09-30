classdef MatrixSourceHandler < signalwavelet.internal.labeling.BaseVectorSourceHandler
%MatrixSourceHandler Source handler for matrix signal ensembles    
% 
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.
    
methods(Hidden)
    function obj = MatrixSourceHandler(data,tinfo,mnames)
        % We are guaranteed that data is a matrix or a cell array of
        % matrices. We ensure that data is stored as a cell array of
        % matrices.
        if nargin == 1
            tinfo = [];
            mnames = [];
        elseif nargin == 2
            mnames = [];
        end
        
        obj.pNumMembers = 0;
        obj.pMemberNameList = strings(0,0);
        obj.pData = {};
        obj.pSampleRate = [];
        obj.pSampleTime = [];
        obj.pTimeValues = [];
        obj.pDataSizes = [];
        obj.pTimeInformation = "none";
        addMembers(obj,data,tinfo,mnames);                                     
    end
end

%--------------------------------------------------------------------------
methods (Hidden, Static)
    function flag = isDataSupportedBySourceHandler(data,errorFlag)
        if nargin < 2
            errorFlag = false;
        end
        % MatrixSourceHandler supports a matrix input or a cell array of
        % matrices input. Each matrix is a member. 
        flag = isnumeric(data) && ismatrix(data);
        if flag 
            if isrow(data)
                data = data(:);
            end
            flag = flag & size(data,1) > 1;
        end
        
        if ~flag        
            flag =  iscell(data) && all(cellfun(@(x) checkInput(x), data, 'UniformOutput', true));     
        end
        
        if ~flag && errorFlag
            error(message('shared_signalwavelet:labeling:MatrixSourceHandler:ExpectedSource'));
        end
    end       
end

%--------------------------------------------------------------------------
methods (Access = protected)
    function [s,data] = parseInputSource(~,data)        
        s = struct('NumMembers',[],'DataSizes',[]);   
        
        if isnumeric(data) && ismatrix(data)
            s.NumMembers = 1;            
            data = {data};
        else
            s.NumMembers = numel(data);                   
        end  
        
         if isrow(data)
            data = data.';
         end
        
        s.DataSizes = zeros(s.NumMembers,2);
        for idx = 1:s.NumMembers            
            if isrow(data{idx})
                data{idx} = data{idx}.';
            end
            s.DataSizes(idx,:) = size(data{idx});
        end            
    end
       
    function memberSizes = validateMemberSizesForTvSetting(~,dataSizes)   
        % Just return memberSizes, nothing to validate, you can always set
        % time values for matrix sources. 
        memberSizes = dataSizes(:,1);
    end
end
end % classdef

%--------------------------------------------------------------------------
% Helper functions
%--------------------------------------------------------------------------
function flag = checkInput(x)
if isrow(x)
    x = x(:);
end

flag = isnumeric(x) && ismatrix(x) && size(x,1) > 1;
end


