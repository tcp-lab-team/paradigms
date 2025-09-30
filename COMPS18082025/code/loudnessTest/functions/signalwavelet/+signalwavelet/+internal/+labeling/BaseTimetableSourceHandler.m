classdef BaseTimetableSourceHandler < signalwavelet.internal.labeling.BaseSourceHandler
%BaseTimetableSourceHandler Base class for source handlers that deal with
%timetables.
% 
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

properties (Access = protected)
    pNumMembers
    pMemberNameList
    pData    
end

methods (Abstract, Hidden, Static)
    flag = isDataSupportedBySourceHandler(data)
end

methods (Abstract, Access = protected)
    [numMembers,data] = parseInputSource(~,data)
end

methods (Hidden)  
    function sInfo = addMembers(obj,data,tinfoValue,mnames) %#ok<INUSD>
        % Input data has already been checked by the caller. If tinfo is
        % not empty, it means it applies for the time information at hand.
        
        [newNumMembers,data] = parseInputSource(obj,data);        
        currentNumMembers = obj.pNumMembers;
        
        if isempty(mnames)
            newMemberNameList = createMemberList(obj,newNumMembers,currentNumMembers);
        else
            if numel(mnames) ~= newNumMembers
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotEqualNumMembersAdded'));
            end
            newMemberNameList = mnames;
        end
        
       
        % Set properties and data only after all checks have been done        
        obj.pMemberNameList = [obj.pMemberNameList; newMemberNameList];
        obj.pNumMembers = obj.pNumMembers + newNumMembers;
        obj.pData = [obj.pData; data];
        
        sInfo.NewNumMembers = newNumMembers;
        sInfo.NewMemberNameList = newMemberNameList;
    end
    
    function removeMembers(obj,mIdxVect)        
        % Remove data from source and from time info
        obj.pData(mIdxVect,:) = [];
        obj.pNumMembers  = obj.pNumMembers - numel(mIdxVect);        
        obj.pMemberNameList = createMemberList(obj,obj.pNumMembers);               
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
    
    function tInfo = getTimeInformation(~)
        tInfo = "inherent";
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
        info = getTimeInfoStruct(obj);                
    end   
end

%--------------------------------------------------------------------------
methods (Hidden, Static)      
    function flag = validateTimetable(T)
        flag = all(varfun(@(x)isnumeric(x) && ismatrix(x), T,'OutputFormat','uniform'));
        if flag
            flag = isduration(T.Properties.RowTimes) && issorted(T.Properties.RowTimes,'strictascend');
        end
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
           
    function info = getTimeInfoStruct(obj)
        info = struct;
        info.TimeInformation = getTimeInformation(obj);
    end            
end

end % classdef