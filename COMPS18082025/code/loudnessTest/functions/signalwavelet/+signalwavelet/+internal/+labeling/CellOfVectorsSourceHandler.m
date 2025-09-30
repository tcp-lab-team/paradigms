classdef CellOfVectorsSourceHandler < signalwavelet.internal.labeling.BaseVectorSourceHandler
%CellOfVectorsSourceHandler Source handler for signal ensembles stored
%as cell array of vectors.
% 
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

methods(Hidden)
    function obj = CellOfVectorsSourceHandler(data,tinfo,mnames)
        % We are guaranteed that data is a cell array of cell array of
        % vectors.
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
        % CellOfVectorsSourceHandler supports a cell array containing cell
        % arrays of vectors. Each cell array of vectors is a member.
        
        if nargin < 2
            errorFlag = false;
        end
        
        % Check that we have a cell array of cell arrays
        flag =  iscell(data) && all(cellfun(@(x) iscell(x), data, 'UniformOutput', true));
        
        % Now check that each cell inside the cell contains numeric vectors
        if flag
            for idx = 1:numel(data)
                flag = all(cellfun(@(x) checkInput(x), data{idx}, 'UniformOutput', true));
                if ~flag
                    break;
                end
            end
        end  
        
        if ~flag && errorFlag
             error(message('shared_signalwavelet:labeling:CellOfVectorsSourceHandler:ExpectedSource'));
        end
    end
end

%--------------------------------------------------------------------------
methods (Access = protected)
    function [s,data] = parseInputSource(~,data)        
        s = struct('NumMembers',[],'DataSizes',[]);   
        s.NumMembers = numel(data);
        s.DataSizes = cell(s.NumMembers,1);
        
        if isrow(data)
            data = data.';
        end
        
        % Store data sizes in a cell array of 2 col matrices. 
        % Each matrix contains the sizes of the elements of each cell in
        % the source. 
        for idx = 1:s.NumMembers
            s.DataSizes{idx} = zeros(numel(data{idx}),2);
            for k = 1:numel(data{idx}) 
                if isrow(data{idx})
                    data{idx} = data{idx}.';
                end
                if isrow(data{idx}{k})
                    data{idx}{k} = data{idx}{k}.';
                end
                 s.DataSizes{idx}(k,:) = size(data{idx}{k});            
            end
        end        
    end
     
    function memberSizes = validateMemberSizesForTvSetting(~,dataSizes)
        % Cannot specify time values if any of the cells have vectors of
        % different sizes.
                        
        memberSizes = zeros(numel(dataSizes),1);
        
        for idx = 1:numel(dataSizes)
            if numel(unique(dataSizes{idx}(:,1))) ~= 1
                error(message('shared_signalwavelet:labeling:CellOfVectorsSourceHandler:InvalidTvNotSameSizeEnsemble'));
            else
                memberSizes(idx) = dataSizes{idx}(1,1);
            end            
        end                       
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

flag = isnumeric(x) && isvector(x) && size(x,1) > 1;
end



