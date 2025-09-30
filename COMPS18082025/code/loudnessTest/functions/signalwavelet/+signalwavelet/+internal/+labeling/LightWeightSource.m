classdef LightWeightSource < handle & matlab.mixin.Copyable
%Light Weight Labeling source   
% 
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

properties     
    MemberIDs
end

methods (Hidden)
    function obj = LightWeightSource(memberIDs)
        %LightWeightSource  
        validateattributes(memberIDs,{'string'},{});
        if ~isempty(memberIDs)
            validateattributes(memberIDs,{'string'},{'vector'});
        end
        obj.MemberIDs = memberIDs(:);
    end
    
    %----------------------------------------------------------------------
    function s = addMembers(obj,memberIDs)
        narginchk(2,2);
        validateattributes(memberIDs,{'string'},{'vector'});
        
        if numel(unique(memberIDs)) ~= numel(memberIDs)
            error(message('shared_signalwavelet:labeling:LightWeightSource:MemberIDsMustBeUnique'));
        end
        
        if any(ismember(memberIDs,obj.MemberIDs))
            error(message('shared_signalwavelet:labeling:LightWeightSource:MemberIDsAlreadyExist'));
        end
        obj.MemberIDs = [obj.MemberIDs; memberIDs(:)];
        
        % Structure containing how many new members were added and the
        % added member list
        s.NewNumMembers = numel(memberIDs);
        s.NewMemberNameList = memberIDs;
    end
    
    function removeMembers(obj,memberIDs)
        narginchk(2,2);
        validateattributes(memberIDs,{'string'},{'vector'});
        memberIDs = unique(memberIDs);
        
        if ~all(ismember(memberIDs,obj.MemberIDs))
            error(message('shared_signalwavelet:labeling:LightWeightSource:MemberIDsDONotExist'));
        end
        obj.MemberIDs = setdiff(obj.MemberIDs,memberIDs);
        % The obj.MemberIDs is expected to be strings(0,1) when empty
        if isempty(obj.MemberIDs)
            obj.MemberIDs = strings(0,1);
        end
    end
    
    function updateMemberIndices(obj,memberIDs)
        narginchk(2,2);
        validateattributes(memberIDs,{'string'},{'vector'});
        memberIDs = unique(memberIDs,'stable');
        
        if ~all(ismember(memberIDs,obj.MemberIDs))
            error(message('shared_signalwavelet:labeling:LightWeightSource:MemberIDsDONotExist'));
        end
        
        if numel(memberIDs) ~= numel(obj.MemberIDs)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIDsNotEqualNumMembers'));
        end
            
        obj.MemberIDs = memberIDs(:);
    end
    
    function numMembers = getNumMembers(obj)
        numMembers = numel(obj.MemberIDs);
    end
    
    function nameList = getMemberNameList(obj)
        nameList = obj.MemberIDs;
    end
    
    function setMemberNameList(obj,mNames)
        obj.MemberIDs = mNames;
    end
end

%--------------------------------------------------------------------------
methods (Hidden, Static)        
    function flag = isCustomMemberNamesSupported(~)
        flag = true;
    end
end
%--------------------------------------------------------------------------
methods (Access = protected)
    function cp = copyElement(obj)
        % Deep copy of Source
        cp = copyElement@matlab.mixin.Copyable(obj);
    end
end
end


