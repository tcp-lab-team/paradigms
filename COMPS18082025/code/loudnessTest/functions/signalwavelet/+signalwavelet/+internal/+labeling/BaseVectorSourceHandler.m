classdef BaseVectorSourceHandler < signalwavelet.internal.labeling.BaseSourceHandler
%BaseVectorSourceHandler Base class for source handlers that deal with
%matrices and vectors.
% 
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

properties (Access = protected)
    pNumMembers
    pMemberNameList
    pData
    pTimeInformation
    pSampleRate
    pSampleTime
    pTimeValues 
    pDataSizes   
end

methods (Abstract, Hidden, Static)
    flag = isDataSupportedBySourceHandler(data)
end

methods (Abstract, Access = protected)
    [s,data] = parseInputSource(obj,data)  
    memberSizes = validateMemberSizesForTvSetting(obj)
end

methods (Hidden)  
    function sInfo = addMembers(obj,data,tinfoValue,mnames)
        % Input data has already been checked by the caller. If tinfo is
        % not empty, it means it applies for the time information at hand.
        
        [s,data] = parseInputSource(obj,data);
        newNumMembers = s.NumMembers;
        currentNumMembers = obj.pNumMembers;
        if isempty(mnames)
            newMemberNameList = createMemberList(obj,newNumMembers,currentNumMembers);
        else
            if numel(mnames) ~= newNumMembers
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotEqualNumMembersAdded'));
            end
            newMemberNameList = mnames;
        end
                
        if obj.pTimeInformation == "sampleRate"
            if ~isempty(tinfoValue)
                tinfoValue = validateSampleRate(obj,tinfoValue,newNumMembers);
            end
            
            if numel(obj.pSampleRate) > 1 && isempty(tinfoValue)
                error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidFsNotScalar'));
            end
            
            if numel(obj.pSampleRate) == 1
                if numel(tinfoValue) == 1 && obj.pSampleRate ~= tinfoValue
                    obj.pSampleRate = obj.pSampleRate(ones(currentNumMembers,1),1);
                    newSampleRate = tinfoValue(ones(newNumMembers,1),1);
                    obj.pSampleRate = [obj.pSampleRate; newSampleRate];
                elseif numel(tinfoValue) > 1
                    obj.pSampleRate = obj.pSampleRate(ones(currentNumMembers,1),1);
                    obj.pSampleRate = [obj.pSampleRate; tinfoValue];
                end
            else
                if numel(tinfoValue) == 1
                    tinfoValue = tinfoValue(ones(newNumMembers,1),1);
                end
                obj.pSampleRate = [obj.pSampleRate; tinfoValue];
            end
            
        elseif obj.pTimeInformation == "sampleTime"
            if ~isempty(tinfoValue)
                tinfoValue = validateSampleTime(obj,tinfoValue,newNumMembers);
                if string(class(tinfoValue)) ~= string(class(obj.pSampleTime))
                    error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTsDataType',class(obj.pSampleTime)));
                end
            end
            
            if numel(obj.pSampleTime) > 1 && isempty(tinfoValue)
                error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTsNotScalar'));
            end
            
            if numel(obj.pSampleTime) == 1
                if numel(tinfoValue) == 1 && obj.pSampleTime ~= tinfoValue
                    obj.pSampleTime = obj.pSampleTime(ones(currentNumMembers,1),1);
                    newSampleTime = tinfoValue(ones(newNumMembers,1),1);
                    obj.pSampleTime = [obj.pSampleTime; newSampleTime];
                elseif numel(tinfoValue) > 1
                    obj.pSampleTime = obj.pSampleTime(ones(currentNumMembers,1),1);
                    obj.pSampleTime = [obj.pSampleTime; tinfoValue];
                end
            else
                if numel(tinfoValue) == 1
                    tinfoValue = tinfoValue(ones(newNumMembers,1),1);
                end
                obj.pSampleTime = [obj.pSampleTime; tinfoValue];
            end
            
        elseif obj.pTimeInformation == "timeValues"
            if ~isempty(tinfoValue)
                tinfoValue = validateTimeValues(obj,tinfoValue,newNumMembers,s.DataSizes);
                if string(class(tinfoValue{1})) ~= string(class(obj.pTimeValues{1}))
                    error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTvDataType',class(obj.pTimeValues)));
                end
            end
            
            if numel(obj.pTimeValues) > 1 && isempty(tinfoValue)
                error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTvNotScalar'));
            end
            
            if numel(obj.pTimeValues) == 1
                memberSizes = validateMemberSizesForTvSetting(obj,s.DataSizes);
                if isempty(tinfoValue) && any(numel(obj.pTimeValues{1}) ~= memberSizes)
                    error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTvInherit'));
                elseif numel(tinfoValue) == 1 && (~all(size(obj.pTimeValues{1})== size(tinfoValue{1})) || ~all(obj.pTimeValues{1} == tinfoValue{1}))
                    obj.pTimeValues = obj.pTimeValues(ones(currentNumMembers,1),1);
                    newTimeValues = tinfoValue(ones(newNumMembers,1),1);
                    obj.pTimeValues = [obj.pTimeValues; newTimeValues];
                elseif numel(tinfoValue) > 1
                    obj.pTimeValues = obj.pTimeValues(ones(currentNumMembers,1),1);
                    obj.pTimeValues = [obj.pTimeValues; tinfoValue];
                end
            else
                if numel(tinfoValue) == 1
                    tinfoValue = tinfoValue(ones(newNumMembers,1),1);
                end
                obj.pTimeValues = [obj.pTimeValues; tinfoValue];
            end
        end
        
        % Set properties and data only after all checks have been done
        obj.pDataSizes = [obj.pDataSizes; s.DataSizes];
        obj.pMemberNameList = [obj.pMemberNameList; newMemberNameList];
        obj.pNumMembers = obj.pNumMembers + s.NumMembers;
        obj.pData = [obj.pData; data];
        
        sInfo.NewNumMembers = newNumMembers;
        sInfo.NewMemberNameList = newMemberNameList;
    end
    
    function removeMembers(obj,mIdxVect)        
        % Remove data from source and from time info
        obj.pData(mIdxVect,:) = [];
        obj.pNumMembers  = obj.pNumMembers - numel(mIdxVect);
        obj.pDataSizes(mIdxVect,:) = [];
        obj.pMemberNameList = createMemberList(obj,obj.pNumMembers);        
        
        if obj.pTimeInformation == "sampleRate"
            if obj.pNumMembers == 0
                obj.pSampleRate = [];
            elseif numel(obj.pSampleRate) > 1
                obj.pSampleRate(mIdxVect) = [];
            end
        elseif obj.pTimeInformation == "sampleTime"
            if obj.pNumMembers == 0
                obj.pSampleTime = [];
            elseif numel(obj.pSampleTime) > 1
                obj.pSampleTime(mIdxVect) = [];
            end                        
        elseif obj.pTimeInformation == "timeValues"
            if obj.pNumMembers == 0
                obj.pTimeValues = {};
            elseif numel(obj.pTimeValues) > 1
                obj.pTimeValues(mIdxVect) = [];
            end
        end                    
    end
    
    function numMembers = getNumMembers(obj)
        numMembers = obj.pNumMembers;        
    end
    
    function nameList = getMemberNameList(obj)
        nameList = obj.pMemberNameList;
    end
    
    function setMemberNameList(obj,mNames,mIdx)
        if isempty(mIdx)
            obj.pMemberNameList = mNames;
        else
            obj.pMemberNameList(mIdx) = mNames;
        end
    end

    function setSampleRate(obj,value)
        value = validateSampleRate(obj,value,obj.pNumMembers);
        obj.pSampleRate = value;
        obj.pTimeInformation = "sampleRate";
        obj.pSampleTime = [];
        obj.pTimeValues = [];
    end
    
    function setSampleTime(obj,value)
        value = validateSampleTime(obj,value,obj.pNumMembers);       
        obj.pSampleTime = value;    
        obj.pTimeInformation = "sampleTime";
        obj.pSampleRate = [];
        obj.pTimeValues = [];
    end
    
    function setTimeValues(obj,value)       
        value = validateTimeValues(obj,value,obj.pNumMembers,obj.pDataSizes);        
        obj.pTimeValues = value;
        obj.pTimeInformation = "timeValues";
        obj.pSampleRate = [];
        obj.pSampleTime = [];
    end
    
    function setTimeInformation(obj,value)
        if obj.pNumMembers > 0 || value ~= "none"
            error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTinfoSet'));               
        end
        obj.pTimeInformation = "none";
        obj.pSampleRate = [];
        obj.pSampleTime = [];        
        obj.pTimeValues = [];
    end
    
    function tInfo = getTimeInformation(obj)
        tInfo = obj.pTimeInformation;        
    end
    
    function fs = getSampleRate(obj)
        fs = obj.pSampleRate;
    end
    
    function ts = getSampleTime(obj)
        ts = obj.pSampleTime;
    end
    
    function tv = getTimeValues(obj)
        tv = obj.pTimeValues;
    end
    
    function data = getSourceData(obj)
        data = obj.pData;
    end        
    
    function data = getPrivateSourceData(obj)
        data = obj.pData;
    end
    
    function [s, info] = getSignalEnsemble(obj,mIdxVect)
        if numel(mIdxVect) == 1
            s = obj.pData{mIdxVect};
        else
            s = obj.pData(mIdxVect);
        end
        info = getTimeInfoStruct(obj,mIdxVect);                
    end        
end

%--------------------------------------------------------------------------
methods (Hidden, Static)    
    function flag = isSourceTimeInfoInherent(~)
        flag = false;
    end
    
    function flag = isCustomMemberNamesSupported(~)
        flag = true;
    end
    
    function flag = isSupportedInSignalAnalyzer(~)
        flag = true;
    end
    
    function flag = isSupportedInSignalLabeler(~)
        flag = true;
    end
end

%--------------------------------------------------------------------------
methods (Access = protected)
    function list = createMemberList(~,numMembers,offset)
        if nargin == 2
            offset = 0;
        end
        list = strings(numMembers,1);
        for idx = 1:numMembers
            list(idx,1) = "Member{" + num2str(idx + offset) + "}";
        end
    end    
           
    function info = getTimeInfoStruct(obj,mIdxVect)
        info = struct;
        info.TimeInformation = obj.pTimeInformation;
        if obj.pTimeInformation == "sampleRate"
            if numel(obj.pSampleRate) == 1
                info.SampleRate = obj.pSampleRate;
            else
                info.SampleRate = obj.pSampleRate(mIdxVect);
            end
        elseif obj.pTimeInformation == "sampleTime"
            if numel(obj.pSampleTime) == 1
                info.SampleTime = obj.pSampleTime;
            else
                info.SampleTime = obj.pSampleTime(mIdxVect);
            end
        elseif obj.pTimeInformation == "timeValues"
            if numel(obj.pTimeValues) == 1
                info.TimeValues = obj.pTimeValues{:};
            else
                info.TimeValues = obj.pTimeValues(mIdxVect);
            end
        end
    end  
    
    function value = validateSampleRate(~,value,numMembers)
        if ~isempty(value)
            validateattributes(value,{'numeric'},{'vector','real','positive','finite'},'labeledSignalSet','SampleRate');
        end
        if ~isscalar(value) && numel(value) ~= numMembers
            error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidFsNumel'));
        end
        if isrow(value)
            value = value(:);
        end
    end
    
    function value = validateSampleTime(~,value,numMembers)        
        if ~isempty(value)
            if isnumeric(value)
                validateattributes(value,{'numeric'},{'vector','real','positive','finite'},'labeledSignalSet','SampleTime');
            elseif isduration(value)
                validateattributes(value,{'duration'},{'vector','finite'},'labeledSignalSet','SampleTime');
            else
                validateattributes(value,{'duration','numeric'},{'vector','finite'},'labeledSignalSet','SampleTime');
            end
        end
        if ~isscalar(value) && numel(value) ~= numMembers
            error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTsNumel'));        
        end
        if isrow(value)
            value = value(:);
        end        
    end   
    
    function value = validateTimeValues(obj,value,numMembers,dataSizes)
        % Validate time value input and return as a cell array of vectors
        % even when input was a matrix.
        if ~isempty(value)
            if ~(ismatrix(value) || iscell(value))                
                error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTv'));
            end
            
            if  (isnumeric(value) || isduration(value)) && ismatrix(value)
                if isrow(value)
                    value = value(:);
                end
                % Store time vectors in a cell array always
                value = mat2cell(value,size(value,1),ones(size(value,2),1));
            elseif iscell(value)                
                for idx = 1:numel(value)
                    if isrow(value{idx})
                        value{idx} = value{idx}.';
                    end
                end
            else
                error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTv'));
            end
            
            % Now that we have a cell array of vectors check sizes and data
            % type
            isAllNumeric = all(cellfun(@(x) isnumeric(x), value, 'UniformOutput',true));
            isAllDurations = all(cellfun(@(x) isduration(x), value, 'UniformOutput',true));
            isAllVectors = all(cellfun(@(x) isvector(x), value,'UniformOutput',true));
            if ~isAllVectors || ~any([isAllNumeric isAllDurations])
                error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InconsistentTvDataType'));
            end
            
            isAllIncreasing = all(cellfun(@(x) issorted(x,'strictascend'), value, 'UniformOutput',true));
            isAllFinite = all(cellfun(@(x) all(isfinite(x)), value, 'UniformOutput',true));
            if ~isAllIncreasing || ~isAllFinite
                error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTvIncreasing'));
            end
        end
        
        if numel(value) >1 && numel(value) ~= numMembers
            error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTvNumel'));           
        end
        
        if isrow(value)
            % Ensure column cell array
            value = value.';
        end
        
        if ~isempty(value)
            valueLengths = cellfun(@(x) size(x,1), value, 'UniformOutput', true); 
            % Get member lengths and validate if it is possible to set time
            % values on the source. 
            memberLengths = validateMemberSizesForTvSetting(obj,dataSizes);            
            if ~all(valueLengths == memberLengths)
                error(message('shared_signalwavelet:labeling:BaseVectorSourceHandler:InvalidTvRowDims'));
            end            
        end        
    end    
end


end % classdef