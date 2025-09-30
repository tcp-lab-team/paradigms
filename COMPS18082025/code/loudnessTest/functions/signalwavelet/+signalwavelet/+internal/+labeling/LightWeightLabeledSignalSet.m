classdef LightWeightLabeledSignalSet < signalwavelet.internal.labeling.LabeledSignalSetBase
%LIGHTWEIGHTLABELEDSIGNALSET Lightweight labeled signal set used in signal labeler app
% 
% A light weight labeled set does not hold member data, only member IDs.
% Each label instance in the label table is assigned a unique ID. Label
% values can be retrieved via the unique ID. 
%
%   For internal use only. 

%   Copyright 2018 MathWorks, Inc.

%#ok<*AGROW>

properties (Access = private)     
    % Map label def IDs to name and other info
    pLabelDefIDMap
    pLabelDefOrderedSet
end
%--------------------------------------------------------------------------
% Constructor
%--------------------------------------------------------------------------
methods (Hidden)
    
    function [obj,info] = LightWeightLabeledSignalSet(memberIDs,LSS)
        % Construct a light weight labeled signal set
        %
        % LWLSS = LightWeightLabeledSignalSet(memberIDs) returns a
        % lightweight labeled signal set with member IDs in memberIDs.
        %
        % LWLSS = LightWeightLabeledSignalSet(memberIDs,LSS) gets label
        % definitions and label values from a labeled signal set LS to
        % create a lightweight labeled signal set.
        % LightWeightLabeledSignalSet assumes that each member of LS
        % corresponds to an ID of memberIDs in the same order.
        
        narginchk(0,2)
        info = struct;
        obj.pAssignIDToLabelValues = true;
        
        if nargin > 0
            validateattributes(memberIDs,{'string'},{'vector'});
        else
            memberIDs = strings(0,0);
        end
        
        obj.pLabelDefIDMap = containers.Map('KeyType','char','ValueType','any');
        obj.pLabelDefOrderedSet = strings(0,0);
        obj.pSource = signalwavelet.internal.labeling.LightWeightSource(memberIDs);
        
        % Create an empty label definitions vector and the labels table
        lblDefsVect = signalLabelDefinition.empty;
        obj.pLabelDefinitions = lblDefsVect;
        tbl = createLabelValuesTable(obj,lblDefsVect);
        if ~isempty(tbl)
            tbl.Properties.RowNames = obj.pSource.getMemberNameList();
        end
        obj.pLabels = tbl;
        
        if nargin > 1
            % Convert LSS to a LWLSS
            if nargout > 1
                info = convertLSSToLWLSS(obj,LSS,memberIDs);
            else
                % Used in import from workspace controller
                convertLSSToLWLSS(obj,LSS,memberIDs);
            end
        end
    end
    
    function  copyLabelsFromLWLSS(obj,srcLWLSS,labelDefinitionIDs,isCopyAllDefinitionsFromSrc)
        %copyLabelsFromLWLSS copies labels table to LWLSS from srcLWLSS for
        % the input labelDefinitionIDs but if labelDefinitionID is sublabel
        % then the parentLabel table is copied
        
        % copyLabelsFromLWLSS(dstLss,srcLWLSS,labelDefinitionIDs, false)
        % copies only the labels table from srcLWLSS to dstLss for all
        % labelDefinitionIDs. labelDefinitionIDs is a vector of string
        % representing labelDefinitionID of all labels and sublabels whose
        % lables table are to be copied.
        
        % copyLabelsFromLWLSS(dstLss,srcLWLSS,labelDefinitionIDs, true)
        % copies the labels table from srcLWLSS to dstLss  for all
        % labelDefinitionIDs.Additionally, all the labelDefinitions in
        % srcLSS and related maps are copied before copying the labels
        % table
        
        validateattributes(labelDefinitionIDs,{'string'},{'vector','scalar'});
        memberIDsToCopy = srcLWLSS.pSource.MemberIDs;
        %  if isCopyAllDefinitionsFromSrc also copies all the Labeldefintions
        if isCopyAllDefinitionsFromSrc
            % Copy all labelDefinitions and its metadata
            obj.pLabelDefinitions = copy(srcLWLSS.pLabelDefinitions);
            obj.pLabelDefIDMap = srcLWLSS.pLabelDefIDMap;
            obj.pLabelDefOrderedSet = srcLWLSS.pLabelDefOrderedSet;
            memberIDsToCopy = obj.pSource.MemberIDs;
        end
        % Copy the labels table for labelDefinitionIDs
        nameOfTablesToCopy = [];
        for idx= 1: numel(labelDefinitionIDs)
            labelDefinitionID = labelDefinitionIDs(idx);
            labelDefinitionInfo = getLabelDefInfoFromLabelDefID(obj,labelDefinitionID);            
            if labelDefinitionInfo.isSublabel
                % for sublabel we copy  parentLabelsTable
                labelDefinitionID = labelDefinitionInfo.parentLabelDefID;
                labelDefinitionInfo = getLabelDefInfoFromLabelDefID(obj,labelDefinitionID);
            end
            labelDefinition = getLabelDefinitionFromLabelDefID(obj,labelDefinitionID);
            nameOfTablesToCopy= [nameOfTablesToCopy labelDefinitionInfo.name];
            if strcmp(labelDefinition.LabelType,"attribute")
                % for attribute label we have a seperate UID table
                nameOfTablesToCopy= [nameOfTablesToCopy labelDefinitionInfo.name+ "_UID"];
            end
        end
        % remove duplicate ParentLabelDefinitionName before copying table
        nameOfTablesToCopy = unique(nameOfTablesToCopy,'stable');
       
        obj.pLabels(memberIDsToCopy,nameOfTablesToCopy) = srcLWLSS.Labels(memberIDsToCopy,nameOfTablesToCopy);
    end
   
    function flag = isLightWeightLabeledSetsCompatible(varargin)
        narginchk(2,Inf);
        if ~all(cellfun(@(x)isa(x,'signalwavelet.internal.labeling.LightWeightLabeledSignalSet'), varargin))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidConcatClasses'));
        end
        flag = validateCompatibleLabelDefinitionsForMerge(varargin{:});
    end
    
    function [LSS, info] = merge(varargin)
        %MERGE Merge two or more light weight labeled signal sets
        %   LSS = MERGE(LSS1,...,LSSN) merges N lw labeled signal set
        %   objects, LSS1,...,LSSN, and produces a lw labeled signal set,
        %   L, containing all the members IDs and label values of the input
        %   sets.
        
        narginchk(2,Inf);
        if ~all(cellfun(@(x)isa(x,'signalwavelet.internal.labeling.LightWeightLabeledSignalSet'), varargin))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidLWMergeClasses'));
        end
        
        % Validate inputs for unique members
        validateCompatibleMembers(varargin{:});
        
        LSS = varargin{1};
        % This validation fails only when any of the imported label
        % defintions has same name but different values
        validateCompatibleLabelDefinitionsForMerge(varargin{:});
        
        % Set label values on the table
        LSS = copy(LSS);
        
        for idx = 2:numel(varargin)
            
            previousNumMembers= LSS.NumMembers;
            newLblSet = varargin{idx};
            
            % Add label definitions from new label set that are not
            % already present in L
            lblDefs = getLabelDefinitions(LSS);
            lblNames = string([lblDefs.Name]);
            newLblDefs = getLabelDefinitions(newLblSet);
            newLblNames = string([newLblDefs.Name]);
            uniqueLblDefs = newLblDefs(~ismember(newLblNames,lblNames));
            if numel(uniqueLblDefs) > 0
                addLabelDefinitions(LSS,uniqueLblDefs,[],true);
            end
            
            % Add label definitions that are not present in new label set
            % from L
            lblDefs = getLabelDefinitions(LSS);
            lblNames = string([lblDefs.Name]);
            lblNamesIncludingUIDVars = getVarNamesIncludingUID(LSS);
            uniqueLblDefs = lblDefs(~ismember(lblNames,newLblNames));
            if numel(uniqueLblDefs) > 0
                addLabelDefinitions(newLblSet,uniqueLblDefs,[],true);
            end
            
            % Now both L and newLblSet should have same label definitions
            
            if newLblSet.NumMembers > 0
                % Get the private data source content from pSource so that
                % we can copy it
                addMembers(LSS,newLblSet.pSource.getMemberNameList());
                
                if numel(lblDefs) > 0
                    % Fill in labels and sub labels on L table
                    % Reorder label names
                    
                    newLblNamesIncludingUIDVars = getVarNamesIncludingUID(newLblSet);
                    varIdx = arrayfun(@(s)find(strcmp(s,newLblNamesIncludingUIDVars) == true),lblNamesIncludingUIDVars);
                    LSS.pLabels(previousNumMembers+1:end,:) = newLblSet.pLabels(:,varIdx);
                    
                    for k = 1:numel(lblNames)
                        lblName = lblNames(k);
                        lblDef = getLabelDefinitionByName(LSS,lblName);
                        
                        if isempty(lblDef.Sublabels)
                            continue;
                        end
                        newLblDef = getLabelDefinitionByName(newLblSet,lblName);
                        
                        % Reorder sublabel names
                        sublblNamesIncldingUIDVars = getSublabelVarNamesIncludingUID(LSS,lblDef);
                        newSublblNamesIncludingUIDVars = getSublabelVarNamesIncludingUID(newLblSet,newLblDef);
                        subVarIdx = arrayfun(@(s)find(strcmp(s,newSublblNamesIncludingUIDVars) == true),sublblNamesIncldingUIDVars);
                        
                        for jj = previousNumMembers+1:LSS.NumMembers
                            LSS.pLabels.(lblName){jj}.Sublabels = LSS.pLabels.(lblName){jj}.Sublabels(:,subVarIdx);
                        end
                    end
                end
            end
        end
        
        memberIDs = getMemberNames(LSS);
        lblDefIDs = getAllLabelDefinitionIDs(LSS);
        if isempty(lblDefIDs) || isempty(memberIDs)
            return;
        end
        
        if nargout > 1
            % Gather IDs and value info and correct instance IDs so that they
            % all have the correct new label definition IDs elements.
            % gatherLabelInstanceIDsAndValues does all of it.
            info = gatherLabelInstanceIDsAndValues(LSS,[],[],[],true);
        else
            % Correct new label definition IDs elements.
            % If info is not required a output, we just need to convert the
            % label definition IDs. gatherLabelInstanceIDsAndValues gets
            % info too and we don't need it.
            correctLabelDefinitionsInLWLSS(LSS);
        end
    end
    
    %----------------------------------------------------------------------
    % Member handlers
    %----------------------------------------------------------------------
    function info = addMembers(obj,memberIDs)
        narginchk(2,2);
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        
        % Source will validate memberIDs
        try
            s = obj.pSource.addMembers(memberIDs);
        catch ME
            info.successFlag = false;
            info.exception = formatExceptionString(obj,ME.identifier);
            return;
        end
        
        tbl = createLabelValuesTable(obj,obj.pLabelDefinitions,false,s.NewNumMembers);
        tbl.Properties.RowNames = s.NewMemberNameList;
        obj.pLabels = [obj.pLabels; tbl];
        
        [info.newAttrLabelInstanceIDs, info.newAttrLabelInstanceValues,~, info.newAttrParentLabelInstanceIDs] = ...
            assignUniqueInstanceIDsToAttributeLabels(obj,memberIDs);
    end
    
    function info = removeMembers(obj,memberIDs)
        %removeMembers Remove members from labeled signal set
        %   removeMembers(LS,memberIDs)
        
        narginchk(2,2);
        % gatherLabelInstanceIDs and Source will validate memberIDs
        mIdxVect = getMemberIndicesByMemberID(obj,memberIDs);
        infoTmp = gatherLabelInstanceIDs(obj,memberIDs);
        info.removedLabelInstanceIDs = infoTmp.labelInstanceIDs;
        % Remove members from source
        obj.pSource.removeMembers(memberIDs);
        
        % Remove from table
        obj.pLabels(mIdxVect,:) = [];
    end
    
    function [LS,info] = subset(obj,memberIDs)
        %subset Get a new labeled signal set with a subset of members
        %   LSNEW = subset(LS,memberIDs)
        
        narginchk(2,2);
        % getMemberIndicesByMemberID will validate the memberIDs input
        mIdxVect = getMemberIndicesByMemberID(obj,memberIDs);
        
        memberIDsToRemove = getMemberNames(obj);
        memberIDsToRemove(mIdxVect) = [];
        
        LS = copy(obj);
        info = removeMembers(LS,memberIDsToRemove);
    end
    
    function info = updateMemberIndices(obj,memberIDs)
        %updateMemberOrder Change the order of members in the
        %labeledSignalSet. MemberIDs specifies the signal IDs to place in throw index values to
        %update.
        %   memberIdx = str2num(getMemberNames(LS))
        %   newIdx = memberIdx(end:-1:1)
        %   LS = updateMemberOrder(LS,newIdx)
        
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        
        narginchk(2,2);
        
        try
            obj.pSource.updateMemberIndices(memberIDs)
            [~,~,rowIdx] = intersect(memberIDs(:),string(obj.pLabels.Properties.RowNames),'stable');
            obj.pLabels = obj.pLabels(rowIdx,:);
        catch ME
            info.successFlag = false;
            info.exception = formatExceptionString(obj,ME.identifier);
            return;
        end
    end
    
    function info = setMemberNames(obj,mNames)
        %setMemberNames Set member names in labeled signal set
        %   setMemberNames(LS,MNAMES) sets the member names to MNAMES, a
        %   string array or cell array of characters specifying names for
        %   each member. The length of MNAMES must be equal to the number
        %   of members. For LightWeightLabeledSignalSets, set the member
        %   names to the signal IDs of the members. 
        
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        
        try
            if obj.NumMembers == 0
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNoMembers'));
            elseif length(mNames) ~= obj.NumMembers
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotEqualNumMembers'));
            elseif any(mNames == "")
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesEmpty'));
            end
            
            if iscellstr(mNames) || ischar(mNames) %#ok<ISCLSTR>
                mNames = string(mNames);
            end
            mNames = mNames(:);
            obj.pSource.setMemberNameList(mNames);
            
            %Update the Labels table
            obj.pLabels.Properties.RowNames = mNames;
            %Update the signal IDs in all label and sublabel instances
            obj.pLabels = updateMemberNameInLabelInstances(obj,mNames);
        catch ME
            info.successFlag = false;
            info.exception = formatExceptionString(obj,ME.identifier);
            return;
        end
        
    end
    
    function val = updateMemberNameInLabelInstances(obj,mNames)
        % Update the member ID values in all of the label instances of the
        % Labels table for the lightweight labeledSignalSet. This is used
        % to correct the signal IDs to their current values when a
        % previously saved session is loaded into Signal analyzer
        
        val = obj.pLabels;
        
        % Correct the member IDs for all parent labels
        for lblIndex = 1:length(obj.pLabelDefinitions)
            lblDef = obj.pLabelDefinitions(lblIndex);
            for memberIdx = 1:size(val,1)
                if lblDef.LabelType == "attribute"
                    % Grab the UID column for attribute labels
                    IDcol = strcat(lblDef.Name,"_UID");
                    val.(IDcol)(memberIdx) = replaceMemberIDsInLabelInstanceIDs(obj,val.(IDcol)(memberIdx),mNames(memberIdx));
                else
                    % Update member IDs for parent point and ROI labels
                    val.(lblDef.Name){memberIdx}.UID = replaceMemberIDsInLabelInstanceIDs(obj,val.(lblDef.Name){memberIdx}.UID,mNames(memberIdx));
                end
                
                % Correct the member IDs for all sublabels
                for subLblIndex = 1:length(lblDef.Sublabels)
                    subLblDef = lblDef.Sublabels(subLblIndex);
                    if subLblDef.LabelType == "attribute"
                        IDcol = strcat(subLblDef.Name,'_UID');
                        val.(lblDef.Name){memberIdx}.Sublabels.(IDcol) = ...
                            replaceMemberIDsInLabelInstanceIDs(obj,val.(lblDef.Name){memberIdx}.Sublabels.(IDcol),mNames(memberIdx));
                    else
                        numRows =numel(val.(lblDef.Name){memberIdx}.Sublabels.(subLblDef.Name));
                        for jj = 1:numRows
                            val.(lblDef.Name){memberIdx}.Sublabels.(subLblDef.Name){jj}.UID = ...
                                replaceMemberIDsInLabelInstanceIDs(obj,val.(lblDef.Name){memberIdx}.Sublabels.(subLblDef.Name){jj}.UID,mNames(memberIdx));
                            
                        end
                    end
                end
            end
        end
    end
    
    %----------------------------------------------------------------------
    % Label definition handlers
    %----------------------------------------------------------------------
    function info = addLabelDefinitions(obj,lblDefsVect,labelDefID,assignUIDsToAttrInstancesFlag)
        % Add label definitions in vector lblDefsVect
        %
        % Specify parent label def ID labelDefID if you want lblDefsVect to
        % be sublabels of that parent.
        
        if nargin < 4
            assignUIDsToAttrInstancesFlag = true;
        end
        
        % Call super class method and then parse label definitions for IDs
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        info.newLabelDefIDs = strings(0,0);
        
        if nargin < 3 || (nargin > 2 && isempty(labelDefID))
            % Add label definitions
            try
                addLabelDefinitions@signalwavelet.internal.labeling.LabeledSignalSetBase(obj,lblDefsVect);
            catch ME
                info.successFlag = false;
                info.exception = formatExceptionString(obj,ME.identifier);
                return;
            end
            info.newLabelDefIDs = parseLabelDefVector(obj,lblDefsVect);
        else
            % Add sub label definitions
            % getLabelDefNameFromLabelDefID will validate labelDefID
            lblName = getLabelDefNameFromLabelDefID(obj,labelDefID);
            try
                addLabelDefinitions@signalwavelet.internal.labeling.LabeledSignalSetBase(obj,lblDefsVect,lblName);
            catch ME
                info.successFlag = false;
                info.exception = formatExceptionString(obj,ME.identifier);
                return;
            end
            info.newLabelDefIDs = parseSublabelDefVector(obj,labelDefID,lblDefsVect);
        end
        
        if assignUIDsToAttrInstancesFlag
            memberIDs = getMemberNames(obj);
            [info.newAttrLabelInstanceIDs, info.newAttrLabelInstanceValues, ~, info.newAttrParentLabelInstanceIDs] = ...
                assignUniqueInstanceIDsToAttributeLabels(obj,memberIDs,info.newLabelDefIDs);
        end
    end
    
    function info = removeLabelDefinition(obj,labelDefID)
        % Remove label definition with ID labelDefID
        info = struct;
        info.removedLabelDefinitionIDs = labelDefID;
        memberIDs = getMemberNames(obj);
        
        % Get label info using the getLabelDefInfoFromLabelDefID method to
        % ensure labelDefID is validated
        lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
        lblDef = getLabelDefinitionFromLabelDefID(obj,labelDefID);
        info.removedLabelDefinitionTypes = lblDef.LabelType; 
        lblName = lblInfo.name;
        
        % Cache label types
        if ~isempty(lblInfo.childrenLabelDefIDs)
            for idx = 1: numel(lblInfo.childrenLabelDefIDs)
                sublblDef = getLabelDefinitionFromLabelDefID(obj,lblInfo.childrenLabelDefIDs(idx));
                info.removedLabelDefinitionTypes = [info.removedLabelDefinitionTypes; sublblDef.LabelType];
            end
        end
                
        % Gather label instance IDs. Make sure we also gather instances of
        % the sublabels as these will also be removed.
        infoTmp = gatherLabelInstanceIDs(obj,memberIDs,[labelDefID; lblInfo.childrenLabelDefIDs(:)]);
        info.removedLabelInstanceIDs = infoTmp.labelInstanceIDs;
        info.parentLabelInstanceIDs = infoTmp.parentLabelInstanceIDs;
        
        if lblInfo.isSublabel
            parentLblName = getLabelDefNameFromLabelDefID(obj,lblInfo.parentLabelDefID);
            inputLblName = [parentLblName lblName];
        else
            inputLblName = lblName;
        end
        % Call super class method and then update label def maps
        removeLabelDefinition@signalwavelet.internal.labeling.LabeledSignalSetBase(obj,inputLblName);
        
        if lblInfo.isSublabel
            % If this is a sublabel then remove the sublabel ID from the
            % parent's childrenIDs
            parentLabelInfo = obj.pLabelDefIDMap(lblInfo.parentLabelDefID);
            parentLabelInfo.childrenLabelDefIDs(parentLabelInfo.childrenLabelDefIDs == labelDefID) = [];
            obj.pLabelDefIDMap(lblInfo.parentLabelDefID) = parentLabelInfo;
        else
            % If this is a parent label, then remove children IDs from the
            % label def Map and from the ordered set.
            for idx = 1:numel(lblInfo.childrenLabelDefIDs)
                sublblID = lblInfo.childrenLabelDefIDs(idx);
                remove(obj.pLabelDefIDMap,sublblID);
                obj.pLabelDefOrderedSet(obj.pLabelDefOrderedSet == sublblID) = [];
            end
        end
        remove(obj.pLabelDefIDMap,labelDefID);
        obj.pLabelDefOrderedSet(obj.pLabelDefOrderedSet == labelDefID) = [];
        if isempty(obj.pLabelDefOrderedSet)
            % Avoid a (1x0) string as this will prevent concatenation with
            % new IDs 
            obj.pLabelDefOrderedSet = strings(0,0);
        end
        
        info.removedLabelDefinitionIDs = [info.removedLabelDefinitionIDs;lblInfo.childrenLabelDefIDs(:)];
    end
    
    function info = editLabelDefinition(obj,labelDefID,propName,propValue)
        % Edit label definition with ID labelDefID
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        
        % Get label def info from label def map. Validation of labelDefID
        % happens inside getLabelDefInfoFromLabelDefID.
        lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
        lblName = lblInfo.name;
        
        if lblInfo.isSublabel
            parentLblName = getLabelDefNameFromLabelDefID(obj,lblInfo.parentLabelDefID);
            inputLblName = [parentLblName lblName];
        else
            inputLblName = lblName;
        end
        % Call super class method and then update label def maps
        try
            editLabelDefinition@signalwavelet.internal.labeling.LabeledSignalSetBase(obj,inputLblName,propName,propValue);
        catch ME
            info.successFlag = false;
            info.exception = formatExceptionString(obj,ME.identifier);
            return;
        end
        
        propName = validatestring(propName,["Name","DefaultValue","Tag","Description","Categories"]);
        if strcmp(propName,"Name")
            % Update name on label definition map
            lblInfo.name = string(propValue);
            obj.pLabelDefIDMap(labelDefID) = lblInfo;
        end
    end
    
    function linfo = getLabelDefInfoFromLabelDefID(obj,labelDefID)
        labelDefID = validateLabelDefinitionIDs(obj,labelDefID);
        validateattributes(labelDefID,{'string'},{'nonempty'},'getLabelDefInfoFromLabelDefID','labelDefID');
        linfo = obj.pLabelDefIDMap(labelDefID);
    end
    
    function lblDef = getLabelDefinitionFromLabelDefID(obj,labelDefID)
        linfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
        if linfo.isSublabel
            parentName = getLabelDefNameFromLabelDefID(obj,linfo.parentLabelDefID);
            lblDef = getSublabelDefinitionByName(obj,parentName,linfo.name);
        else
            lblDef = getLabelDefinitionByName(obj,linfo.name);
        end
        % DO NOT RETURN A LIVE HANDLE
        lblDef = copy(lblDef);
    end
    
    function lblName = getLabelDefNameFromLabelDefID(obj,labelDefID)
        lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
        lblName = lblInfo.name;
    end
    
    function lblDefIDs = getAllLabelDefinitionIDs(obj)
        lblDefIDs = string(obj.pLabelDefOrderedSet)';
    end
    
    function parentLblDefIDs = getAllParentLabelDefinitionIDs(obj)
        lblDefIDs = string(obj.pLabelDefOrderedSet)';
        parentLblDefIDs = [];
        for idx = 1:length(lblDefIDs)
            labelInfo = getLabelDefInfoFromLabelDefID(obj,lblDefIDs(idx));
            if(~labelInfo.isSublabel)
                parentLblDefIDs = [parentLblDefIDs,lblDefIDs(idx)];
            end
        end
    end
    
    function info = undoAutomatedLabelInstance(obj,autoAddedInstanceInfo)
        narginchk(2,inf)
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        info.updateAttributLabelInstanceIDs = [];
        info.updatedAttrParentLabelInstanceIDs = [];
        info.removedLabelInstanceIDs = [];
        instanceIDs = autoAddedInstanceInfo.InstanceIDs;
        parentInstanceIDs =  autoAddedInstanceInfo.ParentInstanceIDs;
        labelDefinitionType = autoAddedInstanceInfo.LabelDefinitionType;
        instancesOldValues = autoAddedInstanceInfo.InstancesOldValues;
        
        for idx = 1: numel(instanceIDs)
            if labelDefinitionType == "attribute"
                obj.editLabelValue(instanceIDs(idx),instancesOldValues{idx});
                info.updateAttributLabelInstanceIDs = [info.updateAttributLabelInstanceIDs;instanceIDs(idx)];
                info.updatedAttrParentLabelInstanceIDs = [info.updatedAttrParentLabelInstanceIDs;parentInstanceIDs(idx)];
            else
                obj.removeLabelValue(instanceIDs(idx));
                info.removedLabelInstanceIDs = [info.removedLabelInstanceIDs;instanceIDs(idx)];
            end
        end
    end
    %----------------------------------------------------------------------
    % Label value handlers
    %----------------------------------------------------------------------
    function info = autoAddLabelValues(obj,memberInfo,labelDefintionIDs,functionHandle,labelerSettingsArguments,runTimeLimits)
        % autoAddLabelValues Add new label values in labeled signal set
        % returned by funtion handle.labelDefintionIDs is a single vector
        % of labelDefintionID if autoLabeling only parent labeldefinitions
        % and a 2 column matrix if at least one labeldefinition being auto
        % labeled is a sublabel. The first column represents
        % parentLabelDefintionID
        
        narginchk(4,inf)
        data = memberInfo.Data;
        time = memberInfo.Time;
        memberID = memberInfo.memberID;
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        info.newAttrLabelInstanceIDs = [];
        info.newAttrLabelInstanceDefIDs = [];
        info.newAttrLabelInstanceValues = [];
        info.newAttrParentLabelInstanceIDs = [];
        info.updatedAttrLabelInstanceIDs = [];
        info.updatedAttrLabelInstanceValues = [];
        info.updatedAttrParentLabelInstanceIDs = [];
        info.updatedAttrLabelInstanceOldValues = [];
        info.newInstanceIDs = [];
        info.newInstanceParentLabelInstanceIDs = [];
        info.newInstanceValues = [];
        info.newInstanceLocations = [];
        c = size(labelDefintionIDs,2);
        parentLabelInstanceInfo= [];
        numberOfParentInstanceLoops = 1;
        isSublabeling = false;
        if c==1
            allLabelDefintionIDs = labelDefintionIDs;
            allParentLabelDefintionIDs = strings(0,1);
        elseif c==2            
            allLabelDefintionIDs = labelDefintionIDs(:,2);
            allParentLabelDefintionIDs = labelDefintionIDs(:,1);
        end
        for idx= 1:numel(allLabelDefintionIDs)
            if ~isempty(allParentLabelDefintionIDs)
                % if sublabel get all parent instances
                isSublabeling = true;
                parentLabelInstanceInfo = obj.gatherLabelInstanceIDsAndValues(memberID,allParentLabelDefintionIDs(idx));
                numberOfParentInstanceLoops = numel(parentLabelInstanceInfo.labelInstanceIDs);
            end
            for jdx= 1: numberOfParentInstanceLoops
                parentLabelInstanceID = [];
                parentLabelInstanceValue = [];
                parentLabelInstanceLocations =[];
                if isSublabeling
                    parentLabelInstanceID = parentLabelInstanceInfo.labelInstanceIDs(jdx);
                    parentLabelInstanceValue = parentLabelInstanceInfo.labelInstanceValues{jdx};
                    if parentLabelInstanceInfo.labelInstanceDefinitionType(jdx) == "roi"
                        parentLabelInstanceLocations = [parentLabelInstanceInfo.labelInstanceT1Times(jdx) parentLabelInstanceInfo.labelInstanceT2Times(jdx)];
                        if ~isempty(runTimeLimits) && ~(parentLabelInstanceLocations(1)>=runTimeLimits(1) && parentLabelInstanceLocations(2)<=runTimeLimits(2))
                            % Skip parentLabelInstanceLoctions which are
                            % not with in runTimeLimits                            
                            continue;
                        end
                    elseif parentLabelInstanceInfo.labelInstanceDefinitionType(jdx) == "point"
                        parentLabelInstanceLocations = parentLabelInstanceInfo.labelInstanceT1Times(jdx);
                        if ~isempty(runTimeLimits) && ~(parentLabelInstanceLocations(1)>=runTimeLimits(1) && parentLabelInstanceLocations(1)<=runTimeLimits(2))
                            % Skip parentLabelInstanceLoctions which are
                            % not with in runTimeLimits                            
                            continue;
                        end
                    end
                end
                % Call the functionHandle to get labelvalues and locations
                try
                    if isempty(labelerSettingsArguments)
                        [labelValue,LabelLocs]= functionHandle(data,time,parentLabelInstanceValue,parentLabelInstanceLocations);
                    else
                        [labelValue,LabelLocs]= functionHandle(data,time,parentLabelInstanceValue,parentLabelInstanceLocations,labelerSettingsArguments{:});
                    end
                catch e
                    info.successFlag = false;
                    info.exception = e.message;
                    return;
                end
                % Get the current labelDefinition info               
                labelDef = obj.getLabelDefinitionFromLabelDefID(allLabelDefintionIDs(idx));             
                if ~isempty(labelValue)
                    % converting to string for case when labelValue is char
                    % array, LSS handle it when adding to labels so converting
                    % here to get right size computation
                    [labelValueRow,labelValueCol] = size(string(labelValue));
                    [labelLocationsRow,labelLocationsCol] = size(LabelLocs);
                    % Check if  function returned labelValue and labelLocs
                    % in row major format, so convert it to col major
                    % format for futher processing
                    if labelDef.LabelType == "point"
                        if labelValueCol > 1
                            info.successFlag = false;
                            info.exception = 'InvalidLabelValueDimension';
                            break;
                        elseif labelLocationsCol ~= 1
                            info.successFlag = false;
                            info.exception = 'InvalidLocationDimensionPoint';
                            break;
                        end
                    elseif labelDef.LabelType == "roi"
                        if labelValueCol > 1
                            info.successFlag = false;
                            info.exception = 'InvalidLabelValueDimension';
                            break;
                        elseif labelLocationsCol ~= 2
                            info.successFlag = false;
                            info.exception = 'InvalidLocationDimensionROI';
                            break;
                        end
                    elseif labelDef.LabelType == "attribute"
                        if labelValueCol > 1 || labelValueRow > 1
                            info.successFlag = false;
                            info.exception = 'InvalidLabelValueDimension';
                            break;
                        elseif labelLocationsCol > 0 || labelLocationsRow > 0
                            info.successFlag = false;
                            info.exception = 'InvalidLocationDimension';
                            break;
                        end
                    end
                    if labelDef.LabelType == "attribute"
                        % For attribute Label get the labelInstanceInfo so
                        % that we can update the value
                        labelInstanceInfo = obj.gatherLabelInstanceIDsAndValues(memberID,allLabelDefintionIDs(idx));
                        % there can be only one attribute instance per
                        % signal or per parentLabelInstance if sublabel
                        attributeInstanceIdx = 1;
                        if isSublabeling
                            attributeInstanceIdx = jdx;
                        end
                        newInfo =  obj.editLabelValue(labelInstanceInfo.labelInstanceIDs(attributeInstanceIdx),labelValue);
                    else
                        newInfo = obj.addLabelValue(memberID,allLabelDefintionIDs(idx),parentLabelInstanceID,LabelLocs,labelValue);
                    end
                    if newInfo.successFlag
                        if isfield(newInfo,'newInstanceIDs') && ~isfield(newInfo,'newInstanceValues')
                            newInfo.newInstanceParentLabelInstanceIDs = [];
                            newInfo.newInstanceValues = [];
                            newInfo.newInstanceLocations = [];
                        end
                        newInstanceParentLabelInstanceIDs = [];
                        if ~isempty(parentLabelInstanceID)
                            % repeat the ID by number of newInstanceIDs
                            newInstanceParentLabelInstanceIDs =repmat(parentLabelInstanceID,numel(labelValue),1);
                        end
                        
                        if islogical(labelValue)
                            % Convert 1 and 0 to true or false string
                            % before sending to client
                            labelValue = string(labelValue);
                        end
                        
                        if labelDef.LabelType == "attribute"
                            info.updatedAttrLabelInstanceValues = [info.updatedAttrLabelInstanceValues; labelValue];
                            info.updatedAttrLabelInstanceOldValues = [info.updatedAttrLabelInstanceOldValues; labelInstanceInfo.labelInstanceValues(attributeInstanceIdx)];
                            info.updatedAttrLabelInstanceIDs = [info.updatedAttrLabelInstanceIDs; labelInstanceInfo.labelInstanceIDs(attributeInstanceIdx)];
                            info.updatedAttrParentLabelInstanceIDs = [info.updatedAttrParentLabelInstanceIDs; labelInstanceInfo.parentLabelInstanceIDs(attributeInstanceIdx)];
                        else
                            info.newInstanceIDs = [info.newInstanceIDs; newInfo.newInstanceIDs];
                            info.newInstanceParentLabelInstanceIDs = [info.newInstanceParentLabelInstanceIDs; newInstanceParentLabelInstanceIDs];
                            info.newInstanceValues = [info.newInstanceValues; labelValue];
                            info.newInstanceLocations = [info.newInstanceLocations; LabelLocs];
                            % Need this for case of ROI/Point label
                            % with attribute sublabel
                            info.newAttrLabelInstanceIDs = [info.newAttrLabelInstanceIDs; newInfo.newAttrLabelInstanceIDs];
                            info.newAttrLabelInstanceDefIDs = [info.newAttrLabelInstanceDefIDs; newInfo.newAttrLabelInstanceDefIDs];
                            info.newAttrParentLabelInstanceIDs = [info.newAttrParentLabelInstanceIDs; newInfo.newAttrParentLabelInstanceIDs];
                            info.newAttrLabelInstanceValues = [info.newAttrLabelInstanceValues; newInfo.newAttrLabelInstanceValues];
                        end
                    else
                        info.successFlag = info.successFlag && newInfo.successFlag;
                        info.exception = newInfo.exception;
                        break;
                    end
                end
            end
            if ~info.successFlag
                break;
            end
        end
    end
    
    function info = addLabelValue(obj,memberID,lblDefID,parentInstanceID,varargin)
        %addLabelValue Add new label values in labeled signal set
        %
        %   Only valid for point and ROI labels
        %   For attribute labels, use editLabelValue
        %
        %   setLabelValue(LS,MID,LBLDEFID,[],LIMITS,VAL) --> roi label
        %   setLabelValue(LS,MID,LBLDEFID,[],LOCS,VAL)   --> point label
        %
        % For sublabels of point or ROI labels specify the parent label
        % instance ID where new values should be added.
        %
        %   setLabelValue(LS,MID,LBLDEFID,PARENTINSTID,LIMITS,VAL) --> roi sublabel
        %   setLabelValue(LS,MID,LBLDEFID,PARENTINSTID,LOCS,VAL)   --> point sublabel
        
        narginchk(4,inf)
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        info.newAttrLabelInstanceIDs = [];
        info.newAttrLabelInstanceDefIDs = [];
        info.newAttrLabelInstanceValues = [];
        info.newAttrParentLabelInstanceIDs = [];
        
        % Get member indices - memberID is validated inside
        % getMemberIndicesByMemberID. Also get the label def info -
        % lblDefID is validated inside getLabelDefInfoFromLabelDefID
        memberIdx = getMemberIndicesByMemberID(obj,memberID);
        lblInfo = getLabelDefInfoFromLabelDefID(obj,lblDefID);
        
        parentInstanceID = validateInstanceIDs(obj,parentInstanceID);
        
        if ~isempty(parentInstanceID)
            [~,parentLblDefID] = parseInstanceID(obj,parentInstanceID);
        end
        
        if  lblInfo.isSublabel
            
            sublblInfo = obj.pLabelDefIDMap(lblDefID);
            sublblName = sublblInfo.name;
            
            if isempty(parentInstanceID)
                s.LabelRowIndex = [];
                s.SublabelRowIndex = [];
            else
                if sublblInfo.parentLabelDefID ~= parentLblDefID
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelDefNotAChildOfParent'));
                end
                s = getRowIndicesOfInstanceID(obj,parentInstanceID);
            end
            
            parentLblDefInfo = getLabelDefInfoFromLabelDefID(obj,sublblInfo.parentLabelDefID);
            lblName = parentLblDefInfo.name;
            
            lblDef = getLabelDefinitionByName(obj,lblName);
            sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName);
            
            if sublblDef.LabelType == "attribute"
                error(message('shared_signalwavelet:labeling:labeledSignalSet:UnsuportedAddValuesMethodForAttrLbl'));
            end
            
            if ~isempty(parentInstanceID)
                if ~isempty(s.LabelRowIndex) && lblDef.LabelType == "attribute"
                    s.LabelRowIndex = [];
                end
                
                if ~isempty(s.SublabelRowIndex) && sublblDef.LabelType == "attribute"
                    s.SublabelRowIndex = [];
                end
            end
            
            try
                info.newInstanceIDs = setSublabelValueInTable(obj,lblDef,sublblDef,lblDefID,memberIdx,memberID,s,varargin{:});
                
            catch ME
                info.successFlag = false;
                info.exception = formatExceptionString(obj,ME.identifier);
                return;
            end
        else
            
            if ~isempty(parentInstanceID)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:ParentInstanceIDInputNotApplies'));
            end
            lblName = lblInfo.name;
            lblDef = getLabelDefinitionByName(obj,lblName);
            if lblDef.LabelType == "attribute"
                error(message('shared_signalwavelet:labeling:labeledSignalSet:UnsuportedAddValuesMethodForAttrLbl'));
            end
            
            try
                info.newInstanceIDs = setLabelValueInTable(obj,lblDef,lblDefID,memberIdx,memberID,[],varargin{:});
            catch ME
                info.successFlag = false;
                info.exception = formatExceptionString(obj,ME.identifier);
                return;
            end
            
            if ~isempty(lblInfo.childrenLabelDefIDs)
                % When a point or roi label is added, the attribute sublabels
                % automatically get instantiated with a default or empty value.
                % Ensure these attribute labels get instance IDs.
                [info.newAttrLabelInstanceIDs, info.newAttrLabelInstanceValues,info.newAttrLabelInstanceDefIDs, info.newAttrParentLabelInstanceIDs] = ...
                    assignUniqueInstanceIDsToAttributeLabels(obj,memberID,lblInfo.childrenLabelDefIDs);
            end
        end
    end
    
    function info = editLabelValue(obj,labelInstanceID,varargin)
        % editLableValue edit value of label with instanceID ID
        %
        % editLabelValue(LS,LBLINSTID,VAL)        --> attr label
        % editLabelValue(LS,LBLINSTID,LIMITS,VAL) --> roi label
        % editLabelValue(LS,LBLINSTID,LOC,VAL)    --> point label
        
        narginchk(2,4)
        info = struct;
        info.successFlag = true;
        info.exception = strings(0,0);
        
        [memberID,lblDefID] = parseInstanceID(obj,labelInstanceID);
        memberIdx = getMemberIndicesByMemberID(obj,memberID);
        lblInfo = getLabelDefInfoFromLabelDefID(obj,lblDefID);
        s = getRowIndicesOfInstanceID(obj,labelInstanceID);
        
        if  lblInfo.isSublabel
            sublblInfo = obj.pLabelDefIDMap(lblDefID);
            sublblName = sublblInfo.name;
            parentLblDefInfo = getLabelDefInfoFromLabelDefID(obj,sublblInfo.parentLabelDefID);
            lblName = parentLblDefInfo.name;
            
            lblDef = getLabelDefinitionByName(obj,lblName);
            sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName);
            
            if ~isempty(s.LabelRowIndex) && lblDef.LabelType == "attribute"
                s.LabelRowIndex = [];
            end
            
            if ~isempty(s.SublabelRowIndex) && sublblDef.LabelType == "attribute"
                s.SublabelRowIndex = [];
            end
            
            try
                setSublabelValueInTable(obj,lblDef,sublblDef,lblDefID,memberIdx,memberID,s,varargin{:});
            catch ME
                info.successFlag = false;
                info.exception = formatExceptionString(obj,ME.identifier);
                return;
            end
        else
            lblName = lblInfo.name;
            lblDef = getLabelDefinitionByName(obj,lblName);
            
            if ~isempty(s.LabelRowIndex) && lblDef.LabelType == "attribute"
                s.LabelRowIndex = [];
            end
            
            try
                setLabelValueInTable(obj,lblDef,lblDefID,memberIdx,memberID,s.LabelRowIndex,varargin{:});
            catch ME
                info.successFlag = false;
                info.exception = formatExceptionString(obj,ME.identifier);
                return;
            end
        end
    end
    
    function info = removeLabelValue(obj,labelInstanceID)
        % Remove label value corresponding to labelInstanceID. This method
        % removes a point or roi label, or sets the value of an attribute
        % label to emmpty. If the sublabel has sublabels, the attribute
        % sublabels are set to empty and ROI/Point are removed.
        
        narginchk(2,2)
        info.removedLabelInstanceIDs = [];
        info.editedLabelInstanceIDs = [];
        info.parentLabelInstanceIDsForEditedLabelInstanceIDs = [];
        info.labelType = "";
        
        [memberID,lblDefID] = parseInstanceID(obj,labelInstanceID);
        memberIdx = getMemberIndicesByMemberID(obj,memberID);
        lblInfo = getLabelDefInfoFromLabelDefID(obj,lblDefID);
        s = getRowIndicesOfInstanceID(obj,labelInstanceID);
        
        if  lblInfo.isSublabel
            sublblInfo = obj.pLabelDefIDMap(lblDefID);
            sublblName = sublblInfo.name;
            parentLblDefInfo = getLabelDefInfoFromLabelDefID(obj,sublblInfo.parentLabelDefID);
            lblName = parentLblDefInfo.name;
            
            lblDef = getLabelDefinitionByName(obj,lblName);
            sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName);
            info.labelType = sublblDef.LabelType;
            
            if sublblDef.LabelType == "attribute"
                info.editedLabelInstanceIDs = labelInstanceID;
                info.parentLabelInstanceIDsForEditedLabelInstanceIDs = gatherLabelInstanceIDs(obj,memberID,sublblInfo.parentLabelDefID).labelInstanceIDs(s.LabelRowIndex);
                missingValue = getMissingValueForLabel(sublblDef);
                editLabelValue(obj,labelInstanceID,missingValue);
            else
                inputArgs = {};
                if ~isempty(s.LabelRowIndex) && lblDef.LabelType ~= "attribute"
                    inputArgs = [inputArgs {'LabelRowIndex',s.LabelRowIndex}];
                end
                if ~isempty(s.SublabelRowIndex)
                    inputArgs = [inputArgs {'SublabelRowIndex',s.SublabelRowIndex}];
                end
                info.removedLabelInstanceIDs = labelInstanceID;
                removeRowValue(obj,sublblDef.LabelType,memberIdx,[lblName,sublblName],inputArgs{:});
            end
        else
            lblName = lblInfo.name;
            lblDef = getLabelDefinitionByName(obj,lblName);
            info.labelType = lblDef.LabelType;
            childrenLabelDefIDs = lblInfo.childrenLabelDefIDs;
            childrenInstanceIDs = strings(0,0);
            if ~isempty(childrenLabelDefIDs)
                infoTmp = gatherLabelInstanceIDs(obj,memberID,childrenLabelDefIDs,labelInstanceID);
                childrenInstanceIDs = infoTmp.labelInstanceIDs;
            end
            
            if lblDef.LabelType == "attribute"
                info.editedLabelInstanceIDs = labelInstanceID;
                info.parentLabelInstanceIDsForEditedLabelInstanceIDs = "";
                missingValue = getMissingValueForLabel(lblDef);
                editLabelValue(obj,labelInstanceID,missingValue);
                
                for idx = 1:numel(childrenInstanceIDs)
                    childrenInfo = removeLabelValue(obj,childrenInstanceIDs(idx));
                    info.removedLabelInstanceIDs = [info.removedLabelInstanceIDs; childrenInfo.removedLabelInstanceIDs];
                    info.editedLabelInstanceIDs = [info.editedLabelInstanceIDs; childrenInfo.editedLabelInstanceIDs];
                    info.parentLabelInstanceIDsForEditedLabelInstanceIDs = [info.parentLabelInstanceIDsForEditedLabelInstanceIDs;...
                        childrenInfo.parentLabelInstanceIDsForEditedLabelInstanceIDs];
                end
            else
                inputArgs = {};
                if ~isempty(s.LabelRowIndex)
                    inputArgs ={'LabelRowIndex',s.LabelRowIndex};
                end
                info.removedLabelInstanceIDs = [labelInstanceID;childrenInstanceIDs];
                removeRowValue(obj,lblDef.LabelType,memberIdx,lblName,inputArgs{:});
            end
        end
    end
    
    function [val,sublblTbl] = getLabelValuesByLabelDefID(obj,memberID,lblDefID,parentInstanceID)
        % Get label values based on a memberID, and label definition ID.
        % For sublabels of point or roi labels, target the particular
        % parent instance by specifying a parentInstanceID
        %
        % First output is label value, second output is a table of
        % sublabels.
        
        narginchk(3,4)
        if nargin < 4
            parentInstanceID = [];
        end
        
        memberIndex = getMemberIndicesByMemberID(obj,memberID);
        lblInfo = getLabelDefInfoFromLabelDefID(obj,lblDefID);
        
        parentInstanceID = validateInstanceIDs(obj,parentInstanceID);
        
        if ~isempty(parentInstanceID)
            [~,parentLblDefID] = parseInstanceID(obj,parentInstanceID);
        end
        
        if  lblInfo.isSublabel
            
            sublblInfo = obj.pLabelDefIDMap(lblDefID);
            sublblName = sublblInfo.name;
            
            if isempty(parentInstanceID)
                s.LabelRowIndex = [];
            else
                if parentLblDefID ~= sublblInfo.parentLabelDefID
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelDefNotAChildOfParent'));
                end
                s = getRowIndicesOfInstanceID(obj,parentInstanceID);
            end
            
            parentLblDefInfo = getLabelDefInfoFromLabelDefID(obj,sublblInfo.parentLabelDefID);
            lblName = parentLblDefInfo.name;
            lblDef = getLabelDefinitionByName(obj,lblName);
            
            if isempty(s.LabelRowIndex) || lblDef.LabelType == "attribute"
                [val,sublblTbl] = getLabelValues(obj,memberIndex,[lblName,sublblName]);
            else
                [val,sublblTbl] = getLabelValues(obj,memberIndex,[lblName,sublblName],'LabelRowIndex',s.LabelRowIndex);
            end
        else
            if ~isempty(parentInstanceID)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:ParentInstanceIDInputNotApplies'));
            end
            lblName = lblInfo.name;
            [val,sublblTbl] = getLabelValues(obj,memberIndex,lblName);
        end
    end
    
    function [val, t1, t2] = getLabelValueByInstanceID(obj,labelInstanceID)
        % Get label value for a particular label instance ID
        narginchk(2,2)
        
        [memberID,lblDefID] = parseInstanceID(obj,labelInstanceID);
        memberIndex = getMemberIndicesByMemberID(obj,memberID);
        lblInfo = getLabelDefInfoFromLabelDefID(obj,lblDefID);
        s = getRowIndicesOfInstanceID(obj,labelInstanceID);
        
        if  lblInfo.isSublabel
            sublblInfo = obj.pLabelDefIDMap(lblDefID);
            sublblName = sublblInfo.name;
            parentLblDefInfo = getLabelDefInfoFromLabelDefID(obj,sublblInfo.parentLabelDefID);
            lblName = parentLblDefInfo.name;
            lblDef = getLabelDefinitionByName(obj,lblName);
            sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName);
            targetLblType = sublblDef.LabelType;
            
            inputArgs = {};
            if ~isempty(s.LabelRowIndex) && lblDef.LabelType ~= "attribute"
                inputArgs = [inputArgs {'LabelRowIndex',s.LabelRowIndex}];
            end
            if ~isempty(s.SublabelRowIndex) && sublblDef.LabelType ~= "attribute"
                inputArgs = [inputArgs {'SublabelRowIndex',s.SublabelRowIndex}];
            end
            
            tmpVal = getLabelValues(obj,memberIndex,[lblName,sublblName],inputArgs{:});
            
        else
            lblName = lblInfo.name;
            lblDef = getLabelDefinitionByName(obj,lblName);
            targetLblType = lblDef.LabelType;
            inputArgs = {};
            if ~isempty(s.LabelRowIndex) && lblDef.LabelType ~= "attribute"
                inputArgs ={'LabelRowIndex',s.LabelRowIndex};
            end
            tmpVal = getLabelValues(obj,memberIndex,lblName,inputArgs{:});
        end
        
        t1 = [];
        t2 = [];
        if targetLblType == "attribute"
            val = readValue(obj,tmpVal);
        elseif targetLblType == "point"
            val = readValue(obj,tmpVal.Value);
            t1 = tmpVal.Location;
        else
            % roi case
            val = readValue(obj,tmpVal.Value);
            t1 = tmpVal.ROILimits(1);
            t2 = tmpVal.ROILimits(2);
        end
    end
    
    function numInstances = getNumInstancesForParentLabelDefinitionID(obj,memberID,labelDefID)
        % Get number of instances that exist for a parent label definition
        % ID.
        memberIndex = getMemberIndicesByMemberID(obj,memberID);
        lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
        lblName = lblInfo.name;
        numInstances = height(obj.pLabels.(lblName){memberIndex});
    end
    
   
    function info = gatherLabelInstanceIDs(obj,memberIDs,labelDefIDs,parentLabelInstanceID)
        % Gather all the label instance IDs contained in labels with labedDefIDs
        %
        % If labelDefIDs is a sublabel or a group of sublabels that share
        % the same parent, you can specify a parentLabelInstanceID to only
        % gather sublabel instance IDs belonging to that parent instance.
        % In this case memberIDs must be a scalar. If you do not specify
        % parentLabelInstanceID you get sublabel instance IDs for all
        % instance parents.
        %
        % parentInstanceIDs contains the parent label instance ID for each
        % instance ID. If the instanceID does not belong to a sublabel, the
        % value in parentInstanceIDs is "".
        info = struct;
        if nargin < 2
            memberIDs = getMemberNames(obj);
        else
            memberIDs = validateMemberIDs(obj,memberIDs);
        end
        if nargin < 3
            labelDefIDs = getAllLabelDefinitionIDs(obj);
        else
            labelDefIDs = validateLabelDefinitionIDs(obj,labelDefIDs);
        end
        
        isParentLabelInstanceIDSpecified = false;
        if nargin > 3
            if numel(memberIDs) > 1
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIDsMustBeScalarWhenParentInstSpecified'));
            end
            [memberID,parentLblDefID] = parseInstanceID(obj,parentLabelInstanceID);
            parentLblDefInfo = getLabelDefInfoFromLabelDefID(obj,parentLblDefID);
            
            if ~all(ismember(labelDefIDs,parentLblDefInfo.childrenLabelDefIDs))
                error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelDefNotAChildOfParent'));
            end
            
            if memberID ~= memberIDs
                error(message('shared_signalwavelet:labeling:labeledSignalSet:ParentInstanceIDNotBelongToMember'));
            end
            isParentLabelInstanceIDSpecified = true;
        end
        
        info.labelInstanceIDs = strings(0,0);
        info.parentLabelInstanceIDs = strings(0,0);
        if isempty(memberIDs) || isempty(labelDefIDs)
            return;
        end
        
        tbl = obj.pLabels;
        
        for lblIndex = 1:numel(labelDefIDs)
            labelDefID = labelDefIDs(lblIndex);
            
            lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
            if lblInfo.isSublabel
                parentInfo = getLabelDefInfoFromLabelDefID(obj,lblInfo.parentLabelDefID);
                parentLblName = parentInfo.name;
                
                parentLblDef = getLabelDefinitionByName(obj,parentLblName);
                
                if isParentLabelInstanceIDSpecified
                    if lblIndex == 1
                        cachedParentDefID = lblInfo.parentLabelDefID;
                    else
                        if cachedParentDefID ~= lblInfo.parentLabelDefID
                            error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelDefsMustShareSameParent'));
                        end
                    end
                    
                    if parentLblDef.LabelType == "attribute"
                        parentIndex = 1;
                    else
                        parentIndex = (tbl.(parentLblName){memberIDs}.UID == parentLabelInstanceID);
                    end
                end
                
                sublblName = lblInfo.name;
                sublblDef = getSublabelDefinitionByName(obj,parentLblName,sublblName);
                sublabelType = sublblDef.LabelType;
                
                for idx = 1:numel(memberIDs)
                    if ~isempty(tbl.(parentLblName){memberIDs(idx)}.Sublabels)
                        if sublabelType == "attribute"
                            if isParentLabelInstanceIDSpecified
                                info.labelInstanceIDs = [info.labelInstanceIDs; tbl.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName+"_UID")(parentIndex)];
                                info.parentLabelInstanceIDs = [info.parentLabelInstanceIDs; parentLabelInstanceID];
                            else
                                info.labelInstanceIDs = [info.labelInstanceIDs; tbl.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName+"_UID")];
                                if parentLblDef.LabelType == "attribute"
                                    numInstances = numel(tbl.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName+"_UID"));
                                    info.parentLabelInstanceIDs = [info.parentLabelInstanceIDs; repmat(tbl.(parentLblName+"_UID"){memberIDs(idx)},numInstances,1)];
                                else
                                    info.parentLabelInstanceIDs = [info.parentLabelInstanceIDs; tbl.(parentLblName){memberIDs(idx)}.UID];
                                end
                            end
                        else
                            tblCell = tbl.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName);
                            if isParentLabelInstanceIDSpecified
                                tblCell = tblCell(parentIndex);
                            end
                            for kk = 1:numel(tblCell)
                                UIDVect = tblCell{kk}.UID;
                                numUIDs = numel(UIDVect);
                                info.labelInstanceIDs = [info.labelInstanceIDs; UIDVect];
                                if isParentLabelInstanceIDSpecified
                                    info.parentLabelInstanceIDs = [info.parentLabelInstanceIDs; repmat(parentLabelInstanceID,numUIDs,1)];
                                else
                                    if parentLblDef.LabelType == "attribute"
                                        info.parentLabelInstanceIDs = [info.parentLabelInstanceIDs; repmat(tbl.(parentLblName+"_UID"){memberIDs(idx)},numUIDs,1)];
                                    else
                                        info.parentLabelInstanceIDs = [info.parentLabelInstanceIDs; repmat(tbl.(parentLblName){memberIDs(idx)}.UID(kk),numUIDs,1)];
                                    end
                                end
                            end
                        end
                    end
                end
            else
                if nargin > 3
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:ParentInstanceIDInputNotApplies2'));
                end
                lblName = lblInfo.name;
                lblDef = getLabelDefinitionByName(obj,lblName);
                lblType = lblDef.LabelType;
                
                if lblType == "attribute"
                    memberIndices = getMemberIndicesByMemberID(obj,memberIDs);
                    info.labelInstanceIDs = [info.labelInstanceIDs; tbl.(lblName+"_UID")(memberIndices)];
                    info.parentLabelInstanceIDs = [info.parentLabelInstanceIDs; repmat("",numel(memberIndices),1)];
                else
                    for idx = 1:numel(memberIDs)
                        if ~isempty(tbl.(lblName){memberIDs(idx)}.UID)
                            UIDVect =  tbl.(lblName){memberIDs(idx)}.UID;
                            numUIDs = numel(UIDVect);
                            info.labelInstanceIDs = [info.labelInstanceIDs; UIDVect];
                            info.parentLabelInstanceIDs = [info.parentLabelInstanceIDs; repmat("",numUIDs,1)];
                        end
                    end
                end
            end
        end
    end
    
    function info = gatherLabelInstanceIDsAndValues(obj,memberIDs,labelDefIDs,parentLabelInstanceID,correctIDsFlag)
        % Gather all the label instance IDs and values contained in labels with labedDefIDs
        %
        % If labelDefIDs is a sublabel or a group of sublabels that share
        % the same parent, you can specify a parentLabelInstanceID to only
        % gather sublabel instance IDs belonging to that parent instance.
        % In this case memberIDs must be a scalar. If you do not specify
        % parentLabelInstanceID you get sublabel instance IDs for all
        % instance parents.
        if nargin < 5
            correctIDsFlag = false;
        end
        
        if nargin < 2 || isempty(memberIDs)
            memberIDs = getMemberNames(obj);
        else
            memberIDs = validateMemberIDs(obj,memberIDs);
        end
        if nargin < 3 || isempty(labelDefIDs)
            labelDefIDs = getAllLabelDefinitionIDs(obj);
        else
            labelDefIDs = validateLabelDefinitionIDs(obj,labelDefIDs);
        end
        
        isParentLabelInstanceIDSpecified = false;
        if nargin > 3 && ~isempty(parentLabelInstanceID)
            if numel(memberIDs) > 1
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIDsMustBeScalarWhenParentInstSpecified'));
            end
            [memberID,parentLblDefID] = parseInstanceID(obj,parentLabelInstanceID);
            parentLblDefInfo = getLabelDefInfoFromLabelDefID(obj,parentLblDefID);
            
            if ~all(ismember(labelDefIDs,parentLblDefInfo.childrenLabelDefIDs))
                error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelDefNotAChildOfParent'));
            end
            
            if memberID ~= memberIDs
                error(message('shared_signalwavelet:labeling:labeledSignalSet:ParentInstanceIDNotBelongToMember'));
            end
            isParentLabelInstanceIDSpecified = true;
        end
        
        outLabelInstanceIDs = strings(0,0);
        outParentLabelInstanceIDs = strings(0,0);
        outLabelInstanceDefinitionType = strings(0,0);
        outLabelInstanceValues = {};
        outLabelInstanceT1Times = [];
        outLabelInstanceT2Times = [];
        
        if isempty(memberIDs) || isempty(labelDefIDs)
            info.labelInstanceIDs = outLabelInstanceIDs;
            info.parentLabelInstanceIDs = outParentLabelInstanceIDs;
            info.labelInstanceDefinitionType = outLabelInstanceDefinitionType;
            info.labelInstanceValues = outLabelInstanceValues;
            info.labelInstanceT1Times = outLabelInstanceT1Times;
            info.labelInstanceT2Times = outLabelInstanceT2Times;
            return;
        end
        
        for lblIndex = 1:numel(labelDefIDs)
            labelDefID = labelDefIDs(lblIndex);
            
            lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
            if lblInfo.isSublabel
                parentInfo = getLabelDefInfoFromLabelDefID(obj,lblInfo.parentLabelDefID);
                parentLblName = parentInfo.name;
                
                parentLblDef = getLabelDefinitionByName(obj,parentLblName);
                
                if isParentLabelInstanceIDSpecified
                    if lblIndex == 1
                        cachedParentDefID = lblInfo.parentLabelDefID;
                    else
                        if cachedParentDefID ~= lblInfo.parentLabelDefID
                            error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelDefsMustShareSameParent'));
                        end
                    end
                    
                    if parentLblDef.LabelType == "attribute"
                        parentIndex = 1;
                    else
                        parentIndex = (obj.pLabels.(parentLblName){memberIDs}.UID == parentLabelInstanceID);
                    end
                end
                
                sublblName = lblInfo.name;
                sublblDef = getSublabelDefinitionByName(obj,parentLblName,sublblName);
                sublabelType = sublblDef.LabelType;
                
                for idx = 1:numel(memberIDs)
                    parentlInstanceIDs = obj.pLabels.(parentLblName){memberIDs(idx)};
                    sublabels = obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels;
                    if ~isempty(sublabels)
                        sublabelInstanceIDs = obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName);
                        if sublabelType == "attribute"
                            sublabelInstanceUID = string(sublabels.(sublblName+"_UID"));
                            if correctIDsFlag
                                sublabelInstanceUID = replaceLabelDefIDInLabelInstIDs(obj,sublabelInstanceUID,labelDefID);
                                obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName+"_UID") = sublabelInstanceUID;
                            end
                            if isParentLabelInstanceIDSpecified
                                outLabelInstanceIDs = appendData(obj,outLabelInstanceIDs,sublabelInstanceUID(parentIndex));
                                outLabelInstanceDefinitionType = appendData(obj,outLabelInstanceDefinitionType,sublabelType);
                                outParentLabelInstanceIDs = appendData(obj,outParentLabelInstanceIDs,parentLabelInstanceID);
                                val = sublabelInstanceIDs(parentIndex);
                            else
                                outLabelInstanceIDs = appendData(obj,outLabelInstanceIDs,sublabelInstanceUID);
                                if parentLblDef.LabelType == "attribute"
                                    numInstances = numel(sublabelInstanceUID);
                                    parentInstanceIDsWithUID = string(obj.pLabels.(parentLblName+"_UID"){memberIDs(idx)});
                                    NewParentLabeNameWithUID = repmat(parentInstanceIDsWithUID,numInstances,1);
                                    NewSublabelType = repmat(sublabelType,numInstances,1);
                                else
                                    NewParentLabeNameWithUID = parentlInstanceIDs.UID;
                                    NewSublabelType = sublabelType;
                                end
                                outParentLabelInstanceIDs = appendData(obj,outParentLabelInstanceIDs,NewParentLabeNameWithUID);
                                outLabelInstanceDefinitionType = appendData(obj,outLabelInstanceDefinitionType,NewSublabelType);
                                val = sublabelInstanceIDs;
                            end
                            
                            if ~iscell(val)
                                val = num2cell(val);
                            end
                            
                            outLabelInstanceValues = appendData(obj,outLabelInstanceValues,val);
                            newTValues = NaN(numel(val),1);
                            outLabelInstanceT1Times = appendData(obj,outLabelInstanceT1Times,newTValues);
                            outLabelInstanceT2Times = appendData(obj,outLabelInstanceT2Times,newTValues);
                        else
                            if correctIDsFlag
                                for pp = 1:numel(sublabelInstanceIDs)
                                    sublabelInstanceIDs{pp}.UID = replaceLabelDefIDInLabelInstIDs(obj,sublabelInstanceIDs{pp}.UID,labelDefID);
                                    obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName){pp}.UID = sublabelInstanceIDs{pp}.UID;
                                end
                            end
                            if isParentLabelInstanceIDSpecified
                                sublabelInstanceIDs = sublabelInstanceIDs(parentIndex);
                            end
                            for kk = 1:numel(sublabelInstanceIDs)
                                if ~isempty(sublabelInstanceIDs{kk}.UID)
                                    UIDVect = sublabelInstanceIDs{kk}.UID;
                                    numUIDs = numel(UIDVect);
                                    outLabelInstanceIDs = appendData(obj,outLabelInstanceIDs,UIDVect);
                                    newSublabelType = repmat(sublabelType,numUIDs,1);
                                    outLabelInstanceDefinitionType = appendData(obj,outLabelInstanceDefinitionType,newSublabelType);
                                    
                                    if isParentLabelInstanceIDSpecified
                                        newParentLabelInstanceID = repmat(parentLabelInstanceID,numUIDs,1);
                                    else
                                        if parentLblDef.LabelType == "attribute"
                                            parentInstanceIDsWithUID = string(obj.pLabels.(parentLblName+"_UID"){memberIDs(idx)});
                                            newParentLabelInstanceID = repmat(parentInstanceIDsWithUID,numUIDs,1);
                                        else
                                            newParentLabelInstanceID = repmat(parentlInstanceIDs.UID(kk),numUIDs,1);
                                        end
                                    end
                                    outParentLabelInstanceIDs = appendData(obj,outParentLabelInstanceIDs,newParentLabelInstanceID);
                                    
                                    sublabelInstanceIDsValue = sublabelInstanceIDs{kk}.Value;
                                    if ~iscell(sublabelInstanceIDsValue)
                                        sublabelInstanceIDsValue = num2cell(sublabelInstanceIDsValue);
                                    end
                                    outLabelInstanceValues = appendData(obj,outLabelInstanceValues,sublabelInstanceIDsValue);
                                    
                                    if sublabelType == "point"
                                        newT1 = sublabelInstanceIDs{kk}.Location;
                                        newT2 = NaN(numel(newT1),1);
                                    else
                                        newT1 = sublabelInstanceIDs{kk}.ROILimits(:,1);
                                        newT2 = sublabelInstanceIDs{kk}.ROILimits(:,2);
                                    end
                                    outLabelInstanceT1Times = appendData(obj,outLabelInstanceT1Times,newT1);
                                    outLabelInstanceT2Times = appendData(obj,outLabelInstanceT2Times,newT2);
                                end
                            end
                        end
                    end
                end
            else
                if nargin > 3 && ~isempty(parentLabelInstanceID)
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:ParentInstanceIDInputNotApplies2'));
                end
                lblName = lblInfo.name;
                lblDef = getLabelDefinitionByName(obj,lblName);
                lblType = lblDef.LabelType;
                
                if lblType == "attribute"
                    memberIndices = getMemberIndicesByMemberID(obj,memberIDs);
                    labelInstances = obj.pLabels.(lblName+"_UID")(memberIndices);
                    if correctIDsFlag
                        labelInstances = replaceLabelDefIDInLabelInstIDs(obj,labelInstances,labelDefID);
                        obj.pLabels.(lblName+"_UID")(memberIndices) = labelInstances;
                    end
                    outLabelInstanceIDs = appendData(obj,outLabelInstanceIDs,labelInstances);
                    outParentLabelInstanceIDs = appendData(obj,outParentLabelInstanceIDs,repmat("",numel(memberIndices),1));
                    outLabelInstanceDefinitionType = appendData(obj,outLabelInstanceDefinitionType,repmat(lblType,numel(memberIndices),1));
                    
                    if isempty(lblInfo.childrenLabelDefIDs)
                        val =  obj.pLabels.(lblName)(memberIndices);
                    else
                        val = [];
                        for idx = 1:numel(memberIndices)
                            val =  [val; obj.pLabels.(lblName){memberIndices(idx)}.Value];
                        end
                    end
                    if iscell(val)
                        outLabelInstanceValues = appendData(obj,outLabelInstanceValues,val);
                    else
                        outLabelInstanceValues = appendData(obj,outLabelInstanceValues,num2cell(val));
                    end
                    newTValues = NaN(numel(val),1);
                    outLabelInstanceT1Times = appendData(obj,outLabelInstanceT1Times,newTValues);
                    outLabelInstanceT2Times = appendData(obj,outLabelInstanceT2Times,newTValues);
                else
                    for idx = 1:numel(memberIDs)
                        labelInstanceIDs = obj.pLabels.(lblName){memberIDs(idx)};
                        if ~isempty(labelInstanceIDs.UID)
                            labelInstanceUID = obj.pLabels.(lblName){memberIDs(idx)}.UID;
                            if correctIDsFlag
                                labelInstanceUID = replaceLabelDefIDInLabelInstIDs(obj,labelInstanceUID,labelDefID);
                                obj.pLabels.(lblName){memberIDs(idx)}.UID = labelInstanceUID;
                            end
                            
                            numUIDs = numel(labelInstanceUID);
                            outLabelInstanceIDs = appendData(obj,outLabelInstanceIDs,labelInstanceUID);
                            outParentLabelInstanceIDs = appendData(obj,outParentLabelInstanceIDs,repmat("",numUIDs,1));
                            outLabelInstanceDefinitionType = appendData(obj,outLabelInstanceDefinitionType,repmat(lblType,numUIDs,1));
                            labelInstanceIDsValue = labelInstanceIDs.Value;
                            if iscell(labelInstanceIDsValue)
                                outLabelInstanceValues = appendData(obj,outLabelInstanceValues,labelInstanceIDsValue);
                            else
                                outLabelInstanceValues = appendData(obj,outLabelInstanceValues,num2cell(labelInstanceIDsValue));
                            end
                            if lblType == "point"
                                labelInstanceIDsLocation = labelInstanceIDs.Location;
                                outLabelInstanceT1Times = appendData(obj,outLabelInstanceT1Times,labelInstanceIDsLocation);
                                outLabelInstanceT2Times = appendData(obj,outLabelInstanceT2Times,NaN(numel(labelInstanceIDsLocation),1));
                            else
                                outLabelInstanceT1Times = appendData(obj,outLabelInstanceT1Times,labelInstanceIDs.ROILimits(:,1));
                                outLabelInstanceT2Times = appendData(obj,outLabelInstanceT2Times,labelInstanceIDs.ROILimits(:,2));
                            end
                        end
                    end
                end
            end
        end
        
        info.labelInstanceIDs = outLabelInstanceIDs';
        info.parentLabelInstanceIDs = outParentLabelInstanceIDs';
        info.labelInstanceDefinitionType = outLabelInstanceDefinitionType';
        info.labelInstanceValues = outLabelInstanceValues';
        info.labelInstanceT1Times = outLabelInstanceT1Times';
        info.labelInstanceT2Times = outLabelInstanceT2Times';
    end
    
    function correctLabelDefinitionsInLWLSS(obj)
        % Correct the label instance in LWLSS
        
        memberIDs = getMemberNames(obj);
        labelDefIDs = getAllLabelDefinitionIDs(obj);
        
        for lblIndex = 1:numel(labelDefIDs)
            labelDefID = labelDefIDs(lblIndex);
            
            lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
            if lblInfo.isSublabel
                parentInfo = getLabelDefInfoFromLabelDefID(obj,lblInfo.parentLabelDefID);
                parentLblName = parentInfo.name;
                sublblName = lblInfo.name;
                sublblDef = getSublabelDefinitionByName(obj,parentLblName,sublblName);
                sublabelType = sublblDef.LabelType;
                for idx = 1:numel(memberIDs)
                    sublabels = obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels;
                    if ~isempty(sublabels)
                        if sublabelType == "attribute"
                            obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName+"_UID") = ...
                                replaceLabelDefIDInLabelInstIDs(obj,sublabels.(sublblName+"_UID"),labelDefID);
                        else
                            sublabelInstanceIDs = obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName);
                            for pp = 1:numel(sublabelInstanceIDs)
                                sublabelInstanceIDs{pp}.UID = replaceLabelDefIDInLabelInstIDs(obj,sublabelInstanceIDs{pp}.UID,labelDefID);
                                obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName){pp}.UID = sublabelInstanceIDs{pp}.UID;
                            end
                        end
                    end
                end
            else
                lblName = lblInfo.name;
                lblDef = getLabelDefinitionByName(obj,lblName);
                lblType = lblDef.LabelType;
                if lblType == "attribute"
                    memberIndices = getMemberIndicesByMemberID(obj,memberIDs);
                    obj.pLabels.(lblName+"_UID")(memberIndices) = replaceLabelDefIDInLabelInstIDs(obj,obj.pLabels.(lblName+"_UID")(memberIndices),labelDefID);
                else
                    for idx = 1:numel(memberIDs)
                        labelInstanceIDs = obj.pLabels.(lblName){memberIDs(idx)};
                        if ~isempty(labelInstanceIDs.UID)
                            obj.pLabels.(lblName){memberIDs(idx)}.UID = replaceLabelDefIDInLabelInstIDs(obj,obj.pLabels.(lblName){memberIDs(idx)}.UID,labelDefID);
                        end
                    end
                end
            end
        end
    end
    
    function [memberID,labelDefID,UID] = parseInstanceID(~,instanceID)
        % Get the memberID and label definition ID from the instanceID
        validateattributes(instanceID,{'char','string'},{},'parseInstanceID','instanceID');
        instanceID = string(instanceID);
        validateattributes(instanceID,{'string'},{'vector'},'parseInstanceID','instanceID');
        
        strVect = split(instanceID,"_");
        if numel(strVect) ~= 3
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidInstanceID'));
        end
        memberID = strVect(1);
        labelDefID = strVect(2);
        UID = strVect(3); % Can be "" (e.g. in labeler app this is a header label row)
    end
    
    function [val] = getLabelValuesWithoutIDs(obj)
        %getLabelValuesWithoutIDs Get label values from labeled signal set
        %   VAL = getLabelValuesWithoutIDs(LS) returns a table, VAL,
        %   containing the label values with the ID columns from the
        %   leightweight object removed for all members in labeled signal
        %   set, LS.
 
        
        val = obj.pLabels;
                
        %Remove all IDs for parent labels
        for lblIndex = 1:length(obj.pLabelDefinitions)
            lblDef = obj.pLabelDefinitions(lblIndex);
            for memberIdx = 1:size(val,1)
                if lblDef.LabelType == "attribute"
                    IDcol = strcat(lblDef.Name,'_UID');
                    if any(contains(val.Properties.VariableNames,IDcol))
                        val.(IDcol) = [];
                    end
                else
                    val.(lblDef.Name){memberIdx}.UID = [];
                end
                
                %Remove all IDs for sub-parent labels
                for subLblIndex = 1:length(lblDef.Sublabels)
                    subLblDef = lblDef.Sublabels(subLblIndex);
                    if subLblDef.LabelType == "attribute"
                        IDcol = strcat(subLblDef.Name,'_UID');
                        val.(lblDef.Name){memberIdx}.Sublabels.(IDcol) = [];
                    else
                        numRows =numel( val.(lblDef.Name){memberIdx}.Sublabels.(subLblDef.Name));
                        for jj = 1:numRows
                            val.(lblDef.Name){memberIdx}.Sublabels.(subLblDef.Name){jj}.UID = [];
                        end
                    end
                end
                
            end
        end
    end
        
    function orderSet = getLabelDefinitionOrderSet(obj)        
        orderSet = obj.pLabelDefOrderedSet;                
    end
    
end

%--------------------------------------------------------------------------
% Protected methods
%--------------------------------------------------------------------------
methods (Access = protected)
    
    function  memberIdxVect = getMemberIndicesByMemberID(obj,memberIDs)
        % Get the member index corresponding to specified memberIDs
        memberIDs = validateMemberIDs(obj,memberIDs);
        memberIdxVect = find(ismember(string(obj.pLabels.Properties.RowNames),memberIDs(:)) == true);
        if isempty(memberIdxVect)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIDNotFound'));
        end
    end
    
    function memberIDs = validateMemberIDs(obj,memberIDs)
        if ~isempty(memberIDs)
            validateattributes(memberIDs,{'char','string'},{},'validateMemberIDs','memberIDs');
            memberIDs = string(memberIDs);
            validateattributes(memberIDs,{'string'},{'vector'},'validateMemberIDs','memberIDs');
            if numel(unique(memberIDs)) ~= numel(memberIDs)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIDsMustBeUnique'));
            end
            if ~all(ismember(memberIDs,obj.getMemberNames()))
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIDsDoNotExist'));
            end
        end
    end
    
    function instanceIDs = validateInstanceIDs(~,instanceIDs)
        if ~isempty(instanceIDs)
            validateattributes(instanceIDs,{'char','string'},{},'validateInstanceIDs','instanceIDs');
            instanceIDs = string(instanceIDs);
            validateattributes(instanceIDs,{'string'},{'vector'},'validateInstanceIDs','instanceIDs');
        end
    end
    
    function labelDefIDs = validateLabelDefinitionIDs(obj,labelDefIDs)
        if ~isempty(labelDefIDs)
            validateattributes(labelDefIDs,{'char','string'},{},'validateLabelDefinitionIDs','labelDefIDs');
            labelDefIDs = string(labelDefIDs);
            validateattributes(labelDefIDs,{'string'},{'vector'},'validateLabelDefinitionIDs','labelDefIDs');
            if ~all(isKey(obj.pLabelDefIDMap,convertStringsToChars(labelDefIDs)))
                error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelDefIDsDoNotExist'));
            end
        end
    end
    
    function newIDs = parseLabelDefVector(obj,lblDefVect)
        % Parse label definition vector and create unique IDs for the
        % parent labels and sublabels. Add the IDs to the pLabelDefIDMap
        % with all the label definition information.
        newIDs = [];
        for idx = 1:numel(lblDefVect)
            lblDef = lblDefVect(idx);
            sublblDefs = lblDef.Sublabels;
            numSublbls = numel(sublblDefs);
            
            uID = createUIDs(obj,1);
            while any(isKey(obj.pLabelDefIDMap,convertStringsToChars(uID)))
                uID = createUIDs(obj,1);
            end
            
            s = createLabelDefIDMapStruct(obj);
            s.name = lblDef.Name;
            obj.pLabelDefIDMap(uID) = s;
            obj.pLabelDefOrderedSet = [obj.pLabelDefOrderedSet; uID];
            
            newIDs = [newIDs; uID];
            if numSublbls > 0
                newSublblIDs = parseSublabelDefVector(obj,uID,sublblDefs);
                newIDs = [newIDs; newSublblIDs];
            end
        end
    end
    
    function newIDs = parseSublabelDefVector(obj,parentLblDefID,sublabelDefVect)
        % Parse sublabels of parent specified in parentLblDefID and assign
        % IDs. Add the sublabel definition IDs to the pLabelDefIDMap with
        % all the label information.
        numSublbls = numel(sublabelDefVect);
        uIDs = createUIDs(obj,numSublbls);
        while any(isKey(obj.pLabelDefIDMap,convertStringsToChars(uIDs)))
            uIDs = createUIDs(obj,numSublbls);
        end
        
        newIDs = uIDs;
        
        parentLabelInfo = obj.pLabelDefIDMap(parentLblDefID);
        childrenLabelDefIDs = parentLabelInfo.childrenLabelDefIDs;  
        if isempty(childrenLabelDefIDs)            
            parentOrderIdxInit = find(obj.pLabelDefOrderedSet == parentLblDefID,1);
        else
            parentOrderIdxInit = find(obj.pLabelDefOrderedSet == childrenLabelDefIDs(end),1);
        end
        
        for idx = 1:numSublbls
            % Add new sublabel IDs to map and set the parent label def ID
            sublblDef = sublabelDefVect(idx);
            sTmp = createLabelDefIDMapStruct(obj);
            sTmp.name = sublblDef.Name;
            sTmp.parentLabelDefID = parentLblDefID;
            sTmp.isSublabel = true;
            obj.pLabelDefIDMap(uIDs(idx)) = sTmp;
                                
            parentOrderIdx = parentOrderIdxInit + idx - 1;
            
            if numel(obj.pLabelDefOrderedSet) == parentOrderIdx
                obj.pLabelDefOrderedSet = [obj.pLabelDefOrderedSet(1:parentOrderIdx); uIDs(idx)];
            else
                obj.pLabelDefOrderedSet = [obj.pLabelDefOrderedSet(1:parentOrderIdx); uIDs(idx); obj.pLabelDefOrderedSet(parentOrderIdx+1:end)];
            end
            
            % Add sublabel to children list of parent label
            parentLabelInfo = obj.pLabelDefIDMap(parentLblDefID);
            parentLabelInfo.childrenLabelDefIDs = [parentLabelInfo.childrenLabelDefIDs(:); uIDs(idx)];
            obj.pLabelDefIDMap(parentLblDefID) = parentLabelInfo;
        end
    end
    
    function [labelInstanceIDs,labelInstanceValues,labelInstanceDefIDs,parentLabelInstanceIDs] = assignUniqueInstanceIDsToAttributeLabels(obj,memberIDs,labelDefIDs)
        % Assign instance IDs to recently added attribute labels. These
        % instances must have a default or empty value as they just got
        % created.
        if nargin < 3
            labelDefIDs = getAllLabelDefinitionIDs(obj);
        end
        labelInstanceIDs = strings(0,0);
        labelInstanceDefIDs = strings(0,0);
        parentLabelInstanceIDs = strings(0,0);
        labelInstanceValues = {};
        
        sublabelDefIDs = [];
        
        % First assign IDs to parents, then to sublabels as we need to
        % gather the parent instance IDs for each sublabel instance
        for lblIndex = 1:numel(labelDefIDs)
            labelDefID = labelDefIDs(lblIndex);
            
            lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
            if lblInfo.isSublabel
                sublabelDefIDs = [sublabelDefIDs; labelDefID];                
            else
                lblName = lblInfo.name;
                lblDef = getLabelDefinitionByName(obj,lblName);
                lblType = lblDef.LabelType;
                
                if lblType == "attribute"
                    val = getDefaultValueForLabel(obj,lblDef);
                    for idx = 1:numel(memberIDs)
                        newID = createLabelInstanceIDs(obj,1,memberIDs(idx),labelDefID);
                        labelInstanceIDs = [labelInstanceIDs; newID];
                        labelInstanceDefIDs = [labelInstanceDefIDs; labelDefID];
                        parentLabelInstanceIDs = [parentLabelInstanceIDs; ""];
                        labelInstanceValues = [labelInstanceValues; {val}];
                        obj.pLabels(memberIDs(idx),:).(lblName+"_UID") = newID;
                    end
                end
            end
        end
        
        for lblIndex = 1:numel(sublabelDefIDs)
            labelDefID = sublabelDefIDs(lblIndex);
            
            lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
            
            parentInfo = getLabelDefInfoFromLabelDefID(obj,lblInfo.parentLabelDefID);
            parentLblName = parentInfo.name;
            parentLblDef = getLabelDefinitionByName(obj,parentLblName);
            
            sublblName = lblInfo.name;
            sublblDef = getSublabelDefinitionByName(obj,parentLblName,sublblName);
            sublabelType = sublblDef.LabelType;
            
            if sublabelType == "attribute"
                val = getDefaultValueForLabel(obj,sublblDef);
                for idx = 1:numel(memberIDs)
                    if isempty(obj.pLabels.(parentLblName){memberIDs(idx)})
                        targetIndices = [];
                    else
                        targetIndices = find(obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName+"_UID") == "");
                    end
                    if ~isempty(targetIndices)
                        numInstances = numel(targetIndices);
                        newIDs = createLabelInstanceIDs(obj,numInstances,memberIDs(idx),labelDefID);
                        labelInstanceIDs = [labelInstanceIDs; newIDs];
                        labelInstanceDefIDs = [labelInstanceDefIDs; repmat(labelDefID,numInstances,1)];
                        addedValues = cell(numInstances,1);
                        addedValues(:,1) = {val};
                        labelInstanceValues = [labelInstanceValues; addedValues];
                        obj.pLabels.(parentLblName){memberIDs(idx)}.Sublabels.(sublblName+"_UID")(targetIndices) = newIDs;
                        if parentLblDef.LabelType == "attribute"
                            parentLabelInstanceIDs = [parentLabelInstanceIDs; obj.pLabels.(parentLblName+"_UID"){memberIDs(idx)}];
                        else
                            parentLabelInstanceIDs = [parentLabelInstanceIDs; obj.pLabels.(parentLblName){memberIDs(idx)}.UID(targetIndices)];
                        end
                    end
                end
            end
        end
    end
    
    function  s = getRowIndicesOfInstanceID(obj,instanceID)
        % Get row index to add values to a sublabel
        % Find LabelRowIndex and SublabelROwIndex based on an instanceID
        
        s = struct('LabelRowIndex',[],'SublabelRowIndex',[]);
        tbl = obj.pLabels;
        [memberID,labelDefID] = parseInstanceID(obj,instanceID);
        
        lblInfo = getLabelDefInfoFromLabelDefID(obj,labelDefID);
        
        if lblInfo.isSublabel
            % Get parent index and child index
            parentInfo = getLabelDefInfoFromLabelDefID(obj,lblInfo.parentLabelDefID);
            parentLblName = parentInfo.name;
            
            sublblName = lblInfo.name;
            sublblDef = getSublabelDefinitionByName(obj,parentLblName,sublblName);
            sublabelType = sublblDef.LabelType;
            
            if sublabelType == "attribute"
                foundInstanceIDs = tbl.(parentLblName){memberID}.Sublabels.(sublblName+"_UID");
                s.LabelRowIndex = find(foundInstanceIDs == instanceID);
            else
                tblCell = tbl.(parentLblName){memberID}.Sublabels.(sublblName);
                for kk = 1:numel(tblCell)
                    foundInstanceIDs = tblCell{kk}.UID;
                    tmpIndex = find(foundInstanceIDs == instanceID);
                    if ~isempty(tmpIndex)
                        s.LabelRowIndex = kk;
                        s.SublabelRowIndex = tmpIndex;
                    end
                end
            end
        else
            % Get parent index
            lblName = lblInfo.name;
            lblDef = getLabelDefinitionByName(obj,lblName);
            labelType = lblDef.LabelType;
            if labelType == "attribute"
                foundInstanceIDs = tbl.(lblName+"_UID"){memberID};
                s.LabelRowIndex = find(foundInstanceIDs == instanceID);
            else
                foundInstanceIDs = tbl.(lblName){memberID}.UID;
                s.LabelRowIndex = find(foundInstanceIDs == instanceID);
            end
        end
    end
    
    function s = createLabelDefIDMapStruct(~)
        s = struct('name',strings(0,0),...
            'isSublabel',false,...
            'parentLabelDefID',strings(0,0),...
            'childrenLabelDefIDs',strings(0,0));
    end
    
    function newInstanceIDs = replaceLabelDefIDInLabelInstIDs(~,lblInstIDs,lblDefID)
        if isempty(lblInstIDs)
            newInstanceIDs = lblInstIDs;
        else
            newInstanceIDs = replaceBetween(lblInstIDs,"_","_",lblDefID);
        end
    end
    
    function s = formatExceptionString(~,s)
        s = string(erase(s,'shared_signalwavelet:labeling:'));
    end
    %----------------------------------------------------------------------
    % Handle conversion from LSS to LWSSS
    function info = convertLSSToLWLSS(obj,LSS,memberIDs)
        validateattributes(LSS,{'labeledSignalSet'},{'scalar'},'LightWeightLabeledSignalSet','LSS');
        % Add label definitions from a labeled signal set
        lblDefsVect = getLabelDefinitions(LSS);
        info = addLabelDefinitions(obj,lblDefsVect,[],false);
        % Copy the labels table
        obj.pLabels = LSS.Labels;
        obj.pLabels.Properties.RowNames = memberIDs;
        memberIDs = getMemberNames(obj);
        mIdxVect = getMemberIndicesByMemberID(obj,memberIDs);
        for lblIndex = 1:numel(info.newLabelDefIDs)
            lblInfo = getLabelDefInfoFromLabelDefID(obj,info.newLabelDefIDs(lblIndex));
            tmpIDs = [];
            
            for idx = 1:numel(mIdxVect)
                memberIdx = mIdxVect(idx);
                if lblInfo.isSublabel
                    % Label is a sublabel
                    if idx == 1
                        parentLblInfo = getLabelDefInfoFromLabelDefID(obj,lblInfo.parentLabelDefID);
                        parentLblName = parentLblInfo.name;
                        sublblInfo = lblInfo;
                        sublblName = sublblInfo.name;
                        sublblDef = getSublabelDefinitionByName(obj,parentLblName,sublblName);
                        if ~verifyDefinitionCompatibleWithSignalLabeler(obj,sublblDef) 
                            error(message('shared_signalwavelet:labeling:labeledSignalSet:UnsupportedLabelDataType'));
                        end
                    end
                    
                    if sublblDef.LabelType == "attribute"                   
                        if ~verifyInstancesCompatibleWithSignalLabeler(obj,idx,sublblDef,parentLblName)
                            error(message('shared_signalwavelet:labeling:labeledSignalSet:UnsupportedLabelValue'));
                        end
                        numInstances = height(obj.pLabels.(parentLblName){memberIdx}.Sublabels);
                        IDs = createLabelInstanceIDs(obj,numInstances,memberIDs(idx),info.newLabelDefIDs(lblIndex));                        
                        insertIdx = find(obj.pLabels.(parentLblName){memberIdx}.Sublabels.Properties.VariableNames == sublblName);
                        obj.pLabels.(parentLblName){memberIdx}.Sublabels = ...
                            [obj.pLabels.(parentLblName){memberIdx}.Sublabels(:,1:insertIdx) ...
                            table(IDs,'VariableNames',(sublblName+"_UID")) ...
                            obj.pLabels.(parentLblName){memberIdx}.Sublabels(:,insertIdx+1:end)];
                    else                   
                        if ~verifyInstancesCompatibleWithSignalLabeler(obj,idx,sublblDef,parentLblName) 
                            error(message('shared_signalwavelet:labeling:labeledSignalSet:UnsupportedLabelValue'));
                        end
                        
                        numRows = height(obj.pLabels.(parentLblName){memberIdx}.Sublabels);
                        for jj = 1:numRows
                            labelInstanceIDs = obj.pLabels.(parentLblName){memberIdx}.Sublabels.(sublblName){jj};
                            numInstances = height(labelInstanceIDs);
                            IDs = createLabelInstanceIDs(obj,numInstances,memberIDs(idx),info.newLabelDefIDs(lblIndex));                                                        
                            obj.pLabels.(parentLblName){memberIdx}.Sublabels.(sublblName){jj} = ...
                                [labelInstanceIDs table(IDs,'VariableNames',"UID")];
                        end
                    end
                else
                    % Label is a parent label
                    if idx == 1
                        lblName = lblInfo.name;
                        lblDef = getLabelDefinitionByName(obj,lblName);
                        if ~verifyDefinitionCompatibleWithSignalLabeler(obj,lblDef)
                            error(message('shared_signalwavelet:labeling:labeledSignalSet:UnsupportedLabelDataType'));
                        end
                    end
                    if lblDef.LabelType == "attribute"
                        tmpIDs = [tmpIDs; createLabelInstanceIDs(obj,1,memberIDs(idx),info.newLabelDefIDs(lblIndex))];                                               
                        if ~verifyInstancesCompatibleWithSignalLabeler(obj,idx,lblDef)
                            error(message('shared_signalwavelet:labeling:labeledSignalSet:UnsupportedLabelValue'));
                        end
                        if idx == numel(memberIDs)
                            insertIdx = find(obj.pLabels.Properties.VariableNames == lblName);                            
                            obj.pLabels = [obj.pLabels(:,1:insertIdx) ...
                                table(tmpIDs,'VariableNames',(lblName+"_UID")) ...
                                obj.pLabels(:,insertIdx+1:end)];
                        end
                    else
                        if ~verifyInstancesCompatibleWithSignalLabeler(obj,idx,lblDef)
                            error(message('shared_signalwavelet:labeling:labeledSignalSet:UnsupportedLabelValue'));
                        end
                        numInstances = height(obj.pLabels.(lblName){memberIdx});
                        IDs = createLabelInstanceIDs(obj,numInstances,memberIDs(idx),info.newLabelDefIDs(lblIndex));                        
                        
                        if isempty(lblInfo.childrenLabelDefIDs)
                            obj.pLabels.(lblName){memberIdx} = [obj.pLabels.(lblName){memberIdx}(:,1:2) table(IDs,'VariableNames',"UID")];
                        else
                            obj.pLabels.(lblName){memberIdx} = [obj.pLabels.(lblName){memberIdx}(:,1:2) table(IDs,'VariableNames',"UID") obj.pLabels.(lblName){memberIdx}(:,3:end)];
                        end
                    end
                end
            end
        end
        
        if nargout > 0
            info2 = gatherLabelInstanceIDsAndValues(obj);
            info.newInstanceIDs =         info2.labelInstanceIDs;
            info.parentLabelInstanceIDs = info2.parentLabelInstanceIDs;
            info.newInstanceValues =      info2.labelInstanceValues;
            info.newInstanceT1Values =    info2.labelInstanceT1Times;
            info.newInstanceT2Values =    info2.labelInstanceT2Times;
        end
        
    end    
    
    function flag = verifyInstancesCompatibleWithSignalLabeler(obj,midx,lblDef,parentLblDefName)
        lblDataType = lblDef.LabelDataType;
        if nargin == 4
            %lblDef is a sublabel
            lblName = [parentLblDefName lblDef.Name];
        else
            lblName = lblDef.Name;
        end
        
        flag = true;
        val = getLabelValues(obj,midx,lblName);
        if ~isempty(val)
            convertLabelTimesToDouble(obj,val,lblName,lblDef.LabelType);
            
            %Extract values from the returned table/cell of tables
            if istable(val)
                val = val.Value;
            elseif iscell(val) && all(cellfun(@istable,val))
                %Extract the values from each cell of tables
                val = cellfun(@(x) x.Value,val,'UniformOutput',false);
                val = vertcat(val{:});
            end
            
            %If the label is of data type string or categorical, no need to
            %check for non-scalar input as the object only accepts scalar
            %values for string/categorical labels
            if any(strcmp(lblDataType,["string","categorical"]))
                return;
            end
            
            %Check if values are scalar
            if iscell(val)
                flag = all(cellfun(@(x)isscalar(x) || isempty(x),val));
            else
                flag = isscalar(val);
            end
        end
    end
    
    function convertLabelTimesToDouble(obj,val,lblName,lblType)
        limitsVarName = '';
        if strcmp(lblType,'roi')
            limitsVarName = 'ROILimits';
        elseif strcmp(lblType,'point')
            limitsVarName = 'Location';
        end
        
        if ~isempty(val)
            if istable(val)
                %Convert the duration ROILimits or Location values to
                %double if needed
                if isduration(val.(limitsVarName)(1))
                    if numel(lblName) == 1
                        %ROI/point parent label
                        obj.pLabels.(lblName){1}.(limitsVarName) = seconds(obj.pLabels.(lblName){1}.(limitsVarName));
                    else
                        %ROI/point sublabel
                        for idx = 1:numel(obj.pLabels.(lblName(1)){1}.Sublabels.(lblName(2)))
                            obj.pLabels.(lblName(1)){1}.Sublabels.(lblName(2)){idx}.(limitsVarName) = seconds(obj.pLabels.(lblName(1)){1}.Sublabels.(lblName(2)){idx}.(limitsVarName));
                        end
                    end
                end
            elseif iscell(val) && all(cellfun(@istable,val))
                %Multiple label instances, values are returned as a cell of
                %tables
                
                for idx = 1:numel(val)
                    %Convert from duration to double if needed
                    if ~isempty(val{idx}) && isduration(val{idx}.(limitsVarName)(1))
                        %We can just check the first instance since label
                        %values from the same lbl defintions
                        obj.pLabels.(lblName(1)){1}.Sublabels.(lblName(2)){idx}.(limitsVarName) = seconds(obj.pLabels.(lblName(1)){1}.Sublabels.(lblName(2)){idx}.(limitsVarName));
                    end
                end
            end
        end
    end
    %----------------------------------------------------------------------
    % Copy
    %----------------------------------------------------------------------
    function cp = copyElement(obj)
        % Deep copy of labeledSignalSet
        cp = copyElement@signalwavelet.internal.labeling.LabeledSignalSetBase(obj);
        
        % Make a deep copy of the label definitions container
        cp.pLabelDefIDMap = containers.Map('KeyType','char','ValueType','any');
        labelDefMapKeys = keys(obj.pLabelDefIDMap);
        for idx = 1:numel(labelDefMapKeys)
            cp.pLabelDefIDMap(labelDefMapKeys{idx}) = obj.pLabelDefIDMap(labelDefMapKeys{idx});
        end
    end
    
    function newInstanceIDs = replaceMemberIDsInLabelInstanceIDs(~,labelInstanceIDs,memberID)
        if isempty(labelInstanceIDs)
            newInstanceIDs = labelInstanceIDs;
        else
            newInstanceIDs = string(replaceBetween(labelInstanceIDs,1,"_",memberID));
        end
    end
    
    function original = appendData(~,original,new)
        startIdx = numel(original) + 1;
        endIdx = startIdx + numel(new) - 1;
        original(startIdx:endIdx) = new;
    end
    
    function [value,isValid] = validatePropertyInPVPair(~,value)
        isValid = ischar(value);
    end
end

end

