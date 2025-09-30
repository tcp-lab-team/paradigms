classdef LabeledSignalSetBase < handle & matlab.mixin.Copyable
%LABELEDSIGNALSETBASE Labeled signal set base class
%
%   For internal use only. 

%   Copyright 2018-2020 MathWorks, Inc.
    
properties
    
    %Description Character array or string scalar with labeled signal set
    %description.
    Description
end

properties (Dependent, SetAccess = protected)
    %NumMembers Number of members in labeled signal set (read-only).
    NumMembers
end

properties (Dependent)
    %Source Matrix, cell-array, timetable, or audioDatastore that contain
    %signals that define the members in the labeled signal set (read-only).
    Source
    %Labels Table with a variable for each signalLabelDefinition object and
    %one row for each member of the set. The row names of the 'Labels'
    %table are the member names (read-only).
    Labels
end

properties (Access = protected)
    % Handle to the source handler object
    pSource
    % Label definitions vector
    pLabelDefinitions
    % Table with label values
    pLabels
    % AssignIDToLabelValues
    pAssignIDToLabelValues = false;
end

%--------------------------------------------------------------------------
% Constructor
%--------------------------------------------------------------------------
methods   
    function L = vertcat(varargin) %#ok<STOUT>
        error(message('shared_signalwavelet:labeling:labeledSignalSet:CatNotSupported'));
    end
    
    function L = horzcat(varargin) %#ok<STOUT>
        error(message('shared_signalwavelet:labeling:labeledSignalSet:CatNotSupported'));
    end
end

%--------------------------------------------------------------------------
% Public methods
%--------------------------------------------------------------------------
methods
    function lblDefs = getLabelDefinitions(obj)
        %getLabelDefinitions Get label definitions of labeled signal set
        %   LBLDEFS = getLabelDefinitions(LS) returns a vector of
        %   signalLabelDefinition objects that define the labels of the
        %   labeled signal set, LS. LBLDEFS is a copy of the label
        %   definitions inside labeled signal set, LS. Changing LBLDEFS
        %   does not affect the labeled set. To modify the label
        %   definitions use the editLabelDefinition, addLabelDefinitions,
        %   and removeLabelDefinition methods.
        
        lblDefs = copy(obj.pLabelDefinitions);
    end
    
    function editLabelDefinition(obj,lblNames,propName,propValue)
        %editLabelDefinition Edit label definition properties
        %   editLabelDefinition(LS,LBLNAME,PROPNAME,VAL) changes the
        %   property PROPNAME of the label definition with name, LBLNAME,
        %   to value VAL. LBLNAME is a character array, or a string scalar
        %   containing a label name. If you want to edit a sublabel
        %   definition, make LBLNAME a two-element string array or a
        %   two-element cell array of character arrays with the first
        %   element containing the parent label name, and the second
        %   element containing the sublabel name. The label definition
        %   properties that can be edited are 'Name', 'DefaultValue, 'Tag',
        %   'Description', and 'Categories'. All other properties of the
        %   label definition affect the label data so they are not
        %   editable. To change any other property of the label definition,
        %   remove the definition using removeLabelDefinition, and add a
        %   new one with the desired property values using
        %   addLabelDefinitions. When you edit the 'DefaultValue' property,
        %   all existing label values remain unchanged. The new default
        %   value affects only values for new members, new regions, or new
        %   points. You can edit only the 'Categories' property when the
        %   'LabelDataType' of the target label or sublabel definition is
        %   'Categorical'. Note that new specified categories are appended
        %   to the existing values, they do not replace the existing
        %   categories as that would make the existing label values
        %   invalid.
        
        narginchk(4,4);
        sName = parseAndValidateNameInput(obj,lblNames);
        lblName = sName.LabelName;
        lblDef = getLabelDefinitionByName(obj,lblName);
        propName = validatestring(propName,["Name","DefaultValue","Tag","Description","Categories"],'labeledSignalSet','PROPNAME');
        
        if sName.HasSublabelName
            sublblName = sName.SublabelName;
            sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName);
            
            if strcmp(propName,"Name")
                oldName = sublblDef.Name;
                if strcmp(oldName, propName)
                    return;
                end
                if any(strcmp(propValue,[lblDef.Sublabels.Name]))
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:UniqueEditedNameSublbl',lblName));
                end
                % Update the property of the label definition
                sublblDef.Name = propValue;
                
                % Update the labels table
                for idx = 1:obj.NumMembers
                    if ~isempty(obj.pLabels.(lblName){idx})
                        % Ensure we always have cell array of names as varnames
                        varNames = convertStringsToChars(obj.pLabels.(lblName){idx}.Sublabels.Properties.VariableNames);
                        nameIdx = strcmp(varNames,oldName);
                        varNames{nameIdx} = char(propValue);
                        if obj.pAssignIDToLabelValues && sublblDef.LabelType == "attribute"
                            nameIdx = strcmp(varNames,oldName+"_UID");
                            varNames{nameIdx} = char(propValue+"_UID");
                        end
                        obj.pLabels.(lblName){idx}.Sublabels.Properties.VariableNames = varNames;
                    end
                end
            elseif strcmp(propName,"DefaultValue")
                % Validate default value and then set it
                if isempty(propValue)
                    sublblDef.(propName) = [];
                else
                    propValue = validateLabelDataValue(sublblDef,propValue,true);
                    sublblDef.(propName) = propValue;
                end
            elseif strcmp(propName,"Categories")
                % First validate to make sure we can concatenate the
                % categories, then set the categories.
                propValue = validateCategories(sublblDef,propValue);
                if ~isempty(propValue)
                    newCats = unique([sublblDef.Categories; propValue],'stable');
                    sublblDef.Categories = newCats;
                end
            else
                sublblDef.(propName) = propValue;
            end
        else
            if strcmp(propName,"Name")
                oldName = lblDef.Name;
                if strcmp(oldName, propValue)
                    return;
                end
                % Proposed new name must be unique
                if any(strcmp(propValue,[obj.pLabelDefinitions.Name]))
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:UniqueEditedName'));
                end
                % Update the property of the label definition
                lblDef.Name = propValue;
                % Update the labels table
                varNames = convertStringsToChars(obj.pLabels.Properties.VariableNames);
                idx = strcmp(varNames,oldName);
                varNames{idx} = char(propValue);
                if obj.pAssignIDToLabelValues && lblDef.LabelType == "attribute"
                    nameIdx = strcmp(varNames,oldName+"_UID");
                    varNames{nameIdx} = char(propValue+"_UID");
                end
                obj.pLabels.Properties.VariableNames = varNames;
            elseif strcmp(propName,"DefaultValue")
                % Validate default value and then set it
                if isempty(propValue)
                    lblDef.(propName) = [];
                else
                    propValue = validateLabelDataValue(lblDef,propValue,true);
                    lblDef.(propName) = propValue;
                end
            elseif strcmp(propName,"Categories")
                % First validate to make sure we can concatenate the
                % categories, then set the categories.
                propValue = validateCategories(lblDef,propValue);
                if ~isempty(propValue)
                    newCats = unique([lblDef.Categories; propValue],'stable');
                    lblDef.Categories = newCats;
                end
            else
                lblDef.(propName) = propValue;
            end
        end
    end
    
    function addLabelDefinitions(obj,lblDefsVect,lblName)
        %addLabelDefinitions Add label definitions to labeled signal set
        %   addLabelDefinitions(LS,LBLDEFS) adds labels defined in the
        %   vector of signal label definitions LBLDEFS to labeled signal
        %   set, LS.
        %
        %   addLabelDefinitions(LS,LBLDEFS,LBLNAME) adds the labels defined
        %   in vector LBLDEFS as sublabels of label named LBLNAME.
        
        narginchk(2,3);
        if nargin == 3
            % We want to add a sublabel to a label named lblName
            
            lblName = validateLabelName(obj,lblName);
            sublblDefsVect = lblDefsVect;
            numMembers = obj.NumMembers;
            
            lblDef = getLabelDefinitionByName(obj,lblName);
            hasPriorSublabels = ~isempty(lblDef.Sublabels);
            validateAndSetSublabelDefinitions(obj,sublblDefsVect,lblName);
            
            if hasPriorSublabels
                % Append a sublabel table to the current sublabels table
                tbl = createLabelValuesTable(obj,sublblDefsVect,true);
                for mIdx = 1:numMembers
                    numLblRows = height(obj.pLabels.(lblName){mIdx});
                    newTbl = repmat(tbl,numLblRows,1);
                    obj.pLabels.(lblName){mIdx}.Sublabels = [obj.pLabels.(lblName){mIdx}.Sublabels newTbl];
                end
            else
                if lblDef.LabelType == "attribute"
                    % Attribute label values are not in tables unless it
                    % has sublabels. Create a table with values and
                    % sublabels and copy the values to the new table.
                    values = obj.pLabels.(lblName);
                    tbl = createLabelValuesTable(obj,lblDef);
                    obj.pLabels.(lblName) = tbl.(lblName);
                    for mIdx = 1:numMembers
                        val = readValue(obj,values(mIdx));
                        setLabelValueInTable(obj,lblDef,[],mIdx,[],[],val);
                    end
                else
                    % ROI and Point labels are always stored in tables so
                    % just append the sublabels table containing the
                    % sublabel definitions.
                    tbl = createLabelValuesTable(obj,sublblDefsVect,true);
                    tbl = table(tbl,'VariableNames',"Sublabels");
                    for mIdx = 1:numMembers
                        numLblRows = height(obj.pLabels.(lblName){mIdx});
                        obj.pLabels.(lblName){mIdx} = ...
                            [obj.pLabels.(lblName){mIdx} repmat(tbl,numLblRows,1)];
                    end
                end
            end
        else
            % Adding a label (no sublabels)
            
            % Validate label definitions and append to existing ones
            validateAndSetLabelDefinitions(obj,lblDefsVect);
            
            % Create a default table for the new definitions and append to
            % existing table
            tbl = createLabelValuesTable(obj,lblDefsVect);
            obj.pLabels = [obj.pLabels tbl];
        end
        
        % Set member names in case this is the first time the table is not
        % empty.
        if ~isempty(obj.pLabels)
            obj.pLabels.Properties.RowNames =  obj.pSource.getMemberNameList();
        end
    end
    
    function removeLabelDefinition(obj,lblName)
        %removeLabelDefinition Remove label definition from labeled signal set
        %   removeLabelDefinition(LS,LBLNAME) removes the label definition
        %   named LBLNAME from labeled signal set, LS. LBLNAME is a
        %   character array, or a string scalar containing a label name. If
        %   you want to remove a sublabel, make LBLNAME a two-element
        %   string array or a two-element cell array of character arrays
        %   with the first element containing the parent label name, and
        %   the second element containing the sublabel name.
        
        narginchk(2,2);
        s = parseAndValidateNameInput(obj,lblName);
        lblName = s.LabelName;
        
        if s.HasSublabelName
            numMembers = obj.NumMembers;
            
            sublblName = s.SublabelName;
            lblDef = getLabelDefinitionByName(obj,lblName);
            lblDefVect = obj.pLabelDefinitions;
            sublblDefVect = lblDef.Sublabels;
            
            lblDefIdx = ([lblDefVect.Name] == lblName);
            sublblDefIdx = ([sublblDefVect.Name] == sublblName);
            
            %Remove sublabel def objects from the label definition
            newSublabelDefVect = obj.pLabelDefinitions(lblDefIdx).Sublabels;
            newSublabelDefVect(sublblDefIdx) = [];
            
            if isempty(newSublabelDefVect)
                
                obj.pLabelDefinitions(lblDefIdx).Sublabels = newSublabelDefVect;
                
                if lblDef.LabelType == "attribute"
                    % Need to create a table entry for the label without any
                    % sublabels and make sure we copy the values over.
                    values = obj.pLabels.(lblName);
                    tbl = createLabelValuesTable(obj,lblDef);
                    obj.pLabels.(lblName) = tbl.(lblName);
                    for mIdx = 1:numMembers
                        val = readValue(obj,values{mIdx}.Value);
                        setLabelValueInTable(obj,lblDef,[],mIdx,[],[],val);
                    end
                else
                    % ROI and Point labels are always stored in tables so
                    % just remove the empty sublabels table
                    for mIdx = 1:numMembers
                        obj.pLabels.(lblName){mIdx}.Sublabels = [];
                    end
                end
            else
                % Just remove the sublabel variable from the sublabels
                % table. Do this before we assign the new sublabel vector
                % to the label definition.
                namesToRemove = sublblName;
                if obj.pAssignIDToLabelValues
                    namesToRemove = getSublabelVarNamesIncludingUID(obj,lblDef,sublblName);
                end
                
                for mIdx = 1:numMembers
                    obj.pLabels.(lblName){mIdx}.Sublabels(:,namesToRemove) = [];
                end
                
                obj.pLabelDefinitions(lblDefIdx).Sublabels = newSublabelDefVect;
            end
        else
            lblDefVect = obj.pLabelDefinitions;
            idx = ([lblDefVect.Name] == lblName);
            lblDefVect(idx) = [];
            
            % Remove the label variable from the table - do this before we
            % assign the new lblDefVect to obj.pLabelDefinitions
            if obj.pAssignIDToLabelValues
                obj.pLabels(:,getVarNamesIncludingUID(obj,lblName)) = [];
            else
                obj.pLabels(:,lblName) = [];
            end
            
            % Assign the new lblDefVect to obj.pLabelDefinitions
            obj.pLabelDefinitions = lblDefVect;
        end
    end
    
    function removeRegionValue(obj,mIdx,lblNames,varargin)
        %removeRegionValue Remove row from ROI label
        %   removeRegionValue(LS,MIDX,LBLNAME) removes all the rows of the
        %   ROI label named LBLNAME, for the MIDX-th member of the labeled
        %   signal set LS. MIDX is a positive, integer, scalar that
        %   specifies the member row number as it appears in the 'Labels'
        %   table of labeled signal set, LS. When LBLNAME is a character
        %   array or a string scalar the function targets a parent label.
        %   When LBLNAME is a two-element string array or a two-element
        %   cell array of character arrays with the first element
        %   containing the name of a parent label, and the second element
        %   containing the sublabel name of an ROI label, this syntax
        %   removes all the regions of the sublabel.
        %
        %   removeRegionValue(LS,MIDX,LBLNAME,'LabelRowIndex',RIDX) removes
        %   a row of the ROI label named LBLNAME, for member specified in
        %   MIDX. MIDX is a positive, integer, scalar that specifies the
        %   member row number as it appears in the 'Labels' table of the
        %   labeled signal set, LS. The row to be removed is determined by
        %   the 'LabelRowIndex' positive, integer, scalar value, RIDX. When
        %   LBLNAME is a two-element string array or a two-element cell
        %   array of character arrays with the first element containing the
        %   name of a parent label, and the second element containing the
        %   sublabel name of an ROI label, this syntax removes all the
        %   regions of the sublabel contained by RIDX row of the parent
        %   label.
        %
        %   removeRegionValue(LS,MIDX,LBLNAME,'SublabelRowIndex',SRIDX)
        %   removes the sublabel row specified by the 'SublabelRowIndex'
        %   positive, integer, scalar value, SRIDX, when LBLNAME is a two
        %   element string array or a two-element cell array of character
        %   arrays with the first element containing the name of a parent
        %   attribute label, and the second element containing the sublabel
        %   name of an ROI label.
        %
        %   removeRegionValue(LS,MIDX,LBLNAME,'LabelRowIndex',RIDX,'SublabelRowIndex',SRIDX)
        %   removes the sublabel row specified by the 'SublabelRowIndex'
        %   value, SRIDX, contained by the ROI or point label row specified
        %   by the 'LabelRowIndex', RIDX, value. LBLNAME is a two-element
        %   string array or a two-element cell array of character arrays
        %   with the first element containing the name of a parent ROI or
        %   point label, and the second element containing the sublabel
        %   name of an ROI label.
        
        narginchk(3,7)
        
        numInputArgs = nargin - numel(varargin);
        if numInputArgs < 3 && ~isempty(varargin)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TooManyInputsLabelSublabelRowIndex'));
        end
        
        removeRowValue(obj,'roi',mIdx,lblNames,varargin{:});
    end
    
    function removePointValue(obj,mIdx,lblNames,varargin)
        %removePointValue Remove row from point label
        %   removePointValue(LS,MIDX,LBLNAME) removes all the rows of the
        %   point label named LBLNAME, for the MIDX-th member of the
        %   labeled signal set LS. MIDX is a positive, integer, scalar that
        %   specifies the member row number as it appears in the 'Labels'
        %   table of labeled signal set, LS. When LBLNAME is a character
        %   array or a string scalar the function targets a parent label.
        %   When LBLNAME is a two-element string array or a two-element
        %   cell array of character arrays with the first element
        %   containing the name of a parent label, and the second element
        %   containing the sublabel name of a point label, this syntax
        %   removes all the points of the sublabel.
        %
        %   removePointValue(LS,MIDX,LBLNAME,'LabelRowIndex',RIDX) removes
        %   a row of the point label named LBLNAME, for member specified in
        %   MIDX. MIDX is a positive, integer, scalar that specifies the
        %   member row number as it appears in the 'Labels' table of the
        %   labeled signal set, LS. The row to be removed is determined by
        %   the 'LabelRowIndex' positive, integer, scalar value, RIDX. When
        %   LBLNAME is a two-element string array or a two-element cell
        %   array of character arrays with the first element containing the
        %   name of a parent label, and the second element containing the
        %   sublabel name of a point label, this syntax removes all the
        %   points of the sublabel contained by RIDX row of the parent
        %   label.
        %
        %   removePointValue(LS,MIDX,LBLNAME,'SublabelRowIndex',SRIDX)
        %   removes the sublabel row specified by the 'SublabelRowIndex'
        %   positive, integer, scalar value, SRIDX, when LBLNAME is a two
        %   element string array or a two-element cell array of character
        %   arrays with the first element containing the name of a parent
        %   attribute label, and the second element containing the sublabel
        %   name of a point label.
        %
        %   removePointValue(LS,MIDX,LBLNAME,'LabelRowIndex',RIDX,'SublabelRowIndex',SRIDX)
        %   removes the sublabel row specified by the 'SublabelRowIndex'
        %   value, SRIDX, contained by the ROI or point label row specified
        %   by the 'LabelRowIndex', RIDX, value. LBLNAME is a two-element
        %   string array or a two-element cell array of character arrays
        %   with the first element containing the name of a parent ROI or
        %   point label, and the second element containing the sublabel
        %   name of a point label.
        
        narginchk(3,7)
        
        numInputArgs = nargin - numel(varargin);
        if numInputArgs < 3 && ~isempty(varargin)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TooManyInputsLabelSublabelRowIndex'));
        end
        
        removeRowValue(obj,'point',mIdx,lblNames,varargin{:});
    end
    
    function [val,sublblTbl] = getLabelValues(obj,mIdx,lblNames,varargin)
        %getLabelValues Get label values from labeled signal set
        %   VAL = getLabelValues(LS) returns a table, VAL, containing the
        %   label values for all members in labeled signal set, LS.
        %
        %   VAL = getLabelValues(LS,MIDX) returns a table, VAL, containing
        %   the label values for the MIDX-th member of the labeled signal
        %   set LS. MIDX is a positive integer, scalar that specifies the
        %   member row number as it appears in the 'Labels' table of
        %   labeled signal set, LS.
        %
        %   [VAL,SUBLBLTBL] = getLabelValues(LS,MIDX,LBLNAME) returns the
        %   value of label named LBLNAME. LBLNAME is a character array, or
        %   a string scalar containing a label name. If label LBLNAME has
        %   sublabels, SUBLBLTBL is a table with the structure of the label
        %   value and its sublabel variables. If label LBLNAME has no
        %   sublabels SUBLBLTBL is empty. If you want to get the values of
        %   a sublabel, make LBLNAME a two-element string array or a two
        %   element cell array of character arrays with the first element
        %   containing the parent label name, and the second element
        %   containing the sublabel name. In this case SUBLBLTBL is empty
        %   as sublabels do not contain more sublabels.
        %
        %   [...] = getLabelValues(...,'LabelRowIndex',RIDX) specifies the
        %   row index, RIDX, of the ROI or point parent label for which you
        %   want to get the value. RIDX is a positive, integer, scalar.
        %
        %   [...] = getLabelValues(...,'SublabelRowIndex',SRIDX), when
        %   targeting an ROI or point sublabel, specifies the sublabel row
        %   index, SRIDX, for which you want to get the value. SRIDX is a
        %   positive, integer, scalar.
        
        narginchk(1,7);
        numInputArgs = nargin - numel(varargin);
        if numInputArgs < 3 && ~isempty(varargin)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TooManyInputsLabelRowIndex'));
        end
        
        sublblTbl = [];
        if numInputArgs == 1
            val = obj.pLabels;
            return;
        end
        
        if numInputArgs > 1
            if isempty(obj.pLabelDefinitions)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:NoLabels'));
            end
            validateMemberIdx(obj,mIdx);
            val = obj.pLabels(mIdx,:);
            if numInputArgs > 2
                sName = parseAndValidateNameInput(obj,lblNames);
                lblName = sName.LabelName;
                sublblName = sName.SublabelName;
                hasSublabelName = sName.HasSublabelName;
                lblDef = getLabelDefinitionByName(obj,lblName);
                
                % Need a different type of validation for this case as row
                % idx applies to both single name input or name/sublabel
                % name input.
                [s,varargin] = parseAndValidateRowIndicesForNameSubName(obj,lblName,sublblName,mIdx,false,true,varargin{:});
                if ~isempty(varargin)
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidNVLabelSublabelRowIndex'));
                end
                
                if isempty(s.LabelRowIndex)
                    rowIndexHasBeenSpecified = false;
                    lblRowIdx = 1;
                else
                    lblRowIdx = s.LabelRowIndex;
                    rowIndexHasBeenSpecified = true;
                end
                
                % Read value ensures that value is extracted from the cell
                % array if input is a cell array.
                val = readValue(obj,val.(lblName));
                if rowIndexHasBeenSpecified
                    val = val(lblRowIdx,:);
                end
                
                if hasSublabelName
                    val = readValue(obj,val.Sublabels.(sublblName));
                    if ~isempty(s.SublabelRowIndex)
                        val = readValue(obj,val(s.SublabelRowIndex,:));
                    end
                else
                    if ~isempty(lblDef.Sublabels)
                        sublblTbl = val;
                        if lblDef.LabelType == "attribute"
                            val = readValue(obj,val{:,1});
                        else
                            val = readValue(obj,val(:,[1 2]));
                        end
                    end
                end
            end
        end
    end
    
    function addMembers(obj,src,tinfo,mnames)
        %addMembers Add members to labeled signal set
        %   addMembers(LS,SRC) adds members to labeled signal set, LS,
        %   based on the input data source SRC.
        %
        %   When 'Source' property of LS consists of a cell array of
        %   matrices, add one member by setting SRC to a matrix. Add
        %   multiple members by setting SRC to a cell array of matrices.
        %
        %   When 'Source' property of LS consists of a cell array
        %   containing cell arrays of vectors, add one new member by
        %   setting SRC to a cell array of vectors. Add multiple members by
        %   setting SRC to a cell array containing cell arrays of vectors.
        %
        %   When 'Source' property of LS consists of a cell array of
        %   timetables, add one new member by setting SRC to a timetable.
        %   Add multiple members by setting SRC to a cell array of
        %   timetables.
        %
        %   When 'Source' property of LS consists of an audioDatastore,
        %   add members by setting SRC as another audio datastore that
        %   points to new files.
        %
        %   addMembers(LS,SRC,TINFO) sets the time information for the new
        %   members to TINFO. When 'TimeInformation' property of LS is
        %   'sampleRate', TINFO specifies sample rate values. When
        %   'TimeInformation' is 'sampleTime', TINFO specifies sample time
        %   values. When 'TimeInformation' is 'timeValues', TINFO specifies
        %   time values. Input TINFO does not apply for any other value of
        %   'TimeInformation'. When adding multiple members, specifying one
        %   value in TINFO sets the same value to all members. If you want
        %   to specify a different value for each new member, then set
        %   TINFO to have multiple values.
        %
        %   When you omit TINFO and the 'TimeInformation' property of LS
        %   equals 'sampleRate', 'sampleTime', or 'timeValues', the added
        %   members inherit the time information when 'SampleRate' or
        %   'SampleTime' properties are scalar values, or when 'TimeValues'
        %   property is a vector. Otherwise, you must specify the time
        %   information for the new members using the TINFO input.
        %
        %   When no source has been specified, or when the labeled signal
        %   set source is empty, you can change the 'TimeInformation'
        %   property to 'sampleRate', 'sampleTime', or 'timeValues' in
        %   order to make LS interpret TINFO correctly. An error occurs if
        %   you specify TINFO and 'TimeInformation' is 'none' or
        %   'inherent'.
        %
        %   addMembers(LS,SRC,TINFO,MNAMES) sets member names for the new
        %   members to MNAMES, a string array or cell array of character
        %   vectors. MNAMES must have a length equal to the number of new
        %   members. If member names are not specified, default names will
        %   be used.
        
        narginchk(2,4);
        
        if nargin == 2
            tinfo = [];
            mnames = [];
        elseif nargin == 3
            mnames = [];
        else
            if iscellstr(mnames) || ischar(mnames) %#ok<ISCLSTR>
                mnames = string(mnames);
            end
            mnames = mnames(:);
        end
        if ~isempty(mnames)
            validateattributes(mnames,{'string','char'},{'vector'},'addMembers','MNAMES');
            mnames = matlab.lang.makeValidName(mnames);
            allMNames = [getMemberNames(obj); mnames];
            
            if length(unique(allMNames)) ~= length(allMNames)
                %Non-unique string was input
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotUnique'));
            end
        end
        if ~obj.pSource.isCustomMemberNamesSupported && ~isempty(mnames)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotSupported'));
        end
        
        % Output structure s contains number of added members and names of
        % added members
        s = obj.pSource.addMembers(src,tinfo,mnames);
        tbl = createLabelValuesTable(obj,obj.pLabelDefinitions,false,s.NewNumMembers);
        if ~isempty(tbl)
            tbl.Properties.RowNames = s.NewMemberNameList;
        end
        obj.pLabels = [obj.pLabels; tbl];
    end
    
    function removeMembers(obj,mIdxVect)
        %removeMembers Remove members from labeled signal set
        %   removeMembers(LS,MIDXVECT) removes the members specified in
        %   vector MIDXVECT from labeled signal set, LS. Each element in
        %   MIDXVECT is a positive integer that specifies a member row
        %   number as it appears in the 'Labels' table of labeled signal
        %   set, LS.
        
        narginchk(2,2);
        mIdxVect = validateMemberIdxVect(obj,mIdxVect);
        obj.pSource.removeMembers(mIdxVect);
        obj.pLabels(mIdxVect,:) = [];
        obj.pLabels.Properties.RowNames = obj.pSource.getMemberNameList();
    end
    
    function LS = subset(obj,mIdxVect)
        %subset Get a new labeled signal set with a subset of members
        %   LSNEW = subset(LS,MIDXVECT) returns a new labeled signal set
        %   containing the members specified in vector MIDXVECT. Each
        %   element of MIDXVECT is a positive integer that specifies a
        %   member row number as it appears in the 'Labels' table of the
        %   labeled signal set, LS.
        
        narginchk(2,2);
        mIdxVect = validateMemberIdxVect(obj,mIdxVect);
        
        mIdxToRemove = 1:obj.NumMembers;
        mIdxToRemove(mIdxVect) = [];
        
        LS = copy(obj);
        removeMembers(LS,mIdxToRemove);
    end
    
    function lblNames = getLabelNames(obj,lblName)
        %getLabelNames Get label names in labeled signal set
        %   LBLNAMES = getLabelNames(LS) returns a string array, LBLNAMES,
        %   containing the label names in labeled signal set, LS.
        %
        %   SUBLBLNAMES = getLabelNames(LS,LBLNAME) returns string array,
        %   SUBLBLNAMES, containing the sublabel names for label named
        %   LBLNAME in labeled signal set, LS.
        
        narginchk(1,2);
        
        if isempty(obj.pLabelDefinitions)
            lblNames = strings(0,0);
            return;
        end
        
        if nargin == 1
            lblNames = [obj.pLabelDefinitions.Name];
        else
            lblDef = getLabelDefinitionByName(obj,lblName);
            sublabels = lblDef.Sublabels;
            lblNames = [];
            if ~isempty(sublabels)
                lblNames = [sublabels.Name];
            end
        end
        if isrow(lblNames)
            lblNames = lblNames(:);
        end
    end
    
    function mNames = getMemberNames(obj)
        %getMemberNames Get member names in labeled signal set
        %   MNAMES = getMemberNames(LS) returns a string array, MNAMES,
        %   containing the member names in the order in which they are
        %   stored in the labeled signal set, LS.
        
        narginchk(1,1);
        mNames = obj.pSource.getMemberNameList();
    end
end

methods (Hidden)
    function outputID = getLabelDefIDFromLabelDefName(obj,lblName,parentName)
        % Get label ID given a label name
        % If a parentName is specified, then we find the sublabel definition
        % ID named lblName whos parent ID is parentName.
        %
        % NOTE - this method is expensive as it loops through all label ids
        % looking for the name. It is mostly used for testing purposes.
        
        validateattributes(lblName,{'char','string'},{});
        lblName = string(lblName);
        validateattributes(lblName,{'string'},{'nonempty','scalar'},'getLabelDefIDFromLabelDefName');
        foundID = strings(0,0);
        outputID = strings(0,0);
        IDs = getAllLabelDefinitionIDs(obj);
        
        if nargin > 2
            validateattributes(parentName,{'char','string'},{});
            parentName = string(parentName);
            validateattributes(parentName,{'string'},{'nonempty','scalar'},'getLabelDefIDFromLabelDefName');
            nameToSearch = parentName;
        else
            nameToSearch = lblName;
        end
        
        for idx = 1:numel(IDs)
            ID = IDs(idx);
            lblInfo = getLabelDefInfoFromLabelDefID(obj,ID);
            if ~lblInfo.isSublabel && (lblInfo.name == nameToSearch)
                foundID = ID;
                break;
            end
        end
        
        if nargin > 2 && ~isempty(foundID)
            nameToSearch = lblName;
            foundLabelDefInfo = getLabelDefInfoFromLabelDefID(obj,foundID);
            IDs = foundLabelDefInfo.childrenLabelDefIDs;
            for idx = 1:numel(IDs)
                ID = IDs(idx);
                lblInfo = getLabelDefInfoFromLabelDefID(obj,ID);
                if lblInfo.name == nameToSearch
                    outputID = ID;
                    break;
                end
            end
        else
            outputID = foundID;
        end
    end
    
    function lblDef = getLabelDefinitionByName(obj,lblName)
        % Get label definition object that has Name equal to lblName
        lblDefVect = obj.pLabelDefinitions;
        idx = ([lblDefVect.Name] == lblName);
        lblDef = lblDefVect(idx);
    end
    
    function sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName)
        % Get sublabel definition object with name sublblName from the
        % label definition that has Name equal to lblName
        lblDefVect = obj.pLabelDefinitions;
        idx = ([lblDefVect.Name] == lblName);
        lblDef = lblDefVect(idx);
        sublabelsVect = lblDef.Sublabels;
        idx = ([sublabelsVect.Name] == sublblName);
        sublblDef = sublabelsVect(idx);
    end
    
    function flag = validateCompatibleLabelDefinitions(~,varargin)
        % This function errors our if nargout == 0, otherwise it returns a
        % success flag.
        flag = true;
        L = varargin{1};
        lblDefs = getLabelDefinitions(L);
        lblNames = [lblDefs.Name];
        
        for idx = 2:numel(varargin)
            testL = varargin{idx};
            
            testLblDefs = getLabelDefinitions(testL);
            testLblNames = [testLblDefs.Name];
            
            if (numel(lblNames) ~= numel(testLblNames)) || (numel(lblNames) > 0 && ~isempty(setdiff(lblNames,testLblNames)))
                if nargout > 0
                    flag = false;
                    return;
                else
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidConcatLabelDefinitions'));
                end
            end
            
            for k = 1:numel(testLblNames)
                % Compare label definitions with equal names
                testName = testLblNames(k);
                testLblDef = testLblDefs(k);
                nameIdx = (lblNames == testName);
                lblDef = lblDefs(nameIdx);
                if ~compareDefinitions(lblDef,testLblDef)
                    if nargout > 0
                        flag = false;
                        return;
                    else
                        error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidConcatLabelDefinitions'));
                    end
                end
            end
        end
    end
    
    function flag = validateCompatibleLabelDefinitionsForMerge(this,varargin)
        % This function compares label definitions that have same name in
        % input LSS. If the label definitions with same name
        % are not exactly equal, the function errors out. If nargout == 0, 
        % otherwise it returns a success/failure flag.
        flag = true;
        lblDefs = getLabelDefinitions(this);
        lblNames = [lblDefs.Name];
        
        for idx = 1:numel(varargin)
            if isa(varargin{idx},'signalLabelDefinition')
                testLblDefs = varargin{idx};
            else
                testLblDefs = getLabelDefinitions(varargin{idx});
            end
            testLblNames = [testLblDefs.Name];
            
            for k = 1:numel(testLblNames)
                % Compare label definitions with equal names
                testName = testLblNames(k);
                testLblDef = testLblDefs(k);
                if ~isempty(lblNames)
                    nameIdx = (lblNames == testName);
                    lblDef = lblDefs(nameIdx);
                    if ~isempty(lblDef)
                        if ~compareDefinitions(lblDef,testLblDef)
                            if nargout > 0
                                flag = false;
                                return;
                            else
                                error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidMergeLabelDefinitions'));
                            end
                        end
                    end
                end
            end
        end
    end
    
    function flag = verifyDefinitionCompatibleWithSignalLabeler(this,lblDefs)
        flag = true;
        if nargin < 2
            lblDefs = this.getLabelDefinitions();
        end
        for idx = 1:numel(lblDefs)
            lblDef = lblDefs(idx);
            lblDataType = lblDef.LabelDataType;
            %If the label defintion has data type of timetable or table, do not allow conversion to a LWLSS
            if any(strcmp(lblDataType,["timetable","table"]))
                flag = false;
                return;
            end
            
            %If the lbldef has duration ROILimits/PointLocations, convert to
            %double
            if strcmp(lblDef.LabelType,'roi') && strcmp(lblDef.ROILimitsDataType,'duration')
                lblDef.ROILimitsDataType = 'double';
            elseif strcmp(lblDef.LabelType,'point') && strcmp(lblDef.PointLocationsDataType,'duration')
                lblDef.PointLocationsDataType = 'double';
            end
        end
    end
    
    function flag = validateCompatibleMembers(varargin)
        flag = true;
        L = varargin{1};
        memberNames = string(getMemberNames(L));
        
        for idx = 2:numel(varargin)
            newMemberNames = string(getMemberNames(varargin{idx}));
            if any(ismember(memberNames,newMemberNames))
                if nargout > 0
                    flag = false;
                    return;
                else
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidMergeMembers'));
                end
            end
        end
    end
end

%--------------------------------------------------------------------------
% Set/get methods
%--------------------------------------------------------------------------
methods
    
    function set.Source(~,~)
        error(message('shared_signalwavelet:labeling:labeledSignalSet:SourceReadOnly'));
    end
    function value = get.Source(obj)
        % Get the public data source content from pSource
        value = obj.pSource.getSourceData();
    end
    
    function value = get.NumMembers(obj)
        value = obj.pSource.getNumMembers();
    end
    
    function set.Description(obj,value)
        if isempty(value)
            obj.Description = "";
            return
        end
        [flag, desc] = validateStringInput(obj,value);
        if flag
            obj.Description = desc;
        else
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidDescriptionType'));
        end
    end
    
    function set.Labels(~,~)
        error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelsReadOnly'));
    end
    
    function value = get.Labels(obj)
        value = obj.pLabels;
    end
    
    function varargout = set(obj,varargin)
        % Override set to allow tab completion of enum properties
        [varargout{1:nargout}] = signalwavelet.internal.util.set(obj,varargin{:});
    end
end


%--------------------------------------------------------------------------
% Protected methods
%--------------------------------------------------------------------------
methods (Access = protected)
    function removeRowValue(obj,lblType,mIdx,lblNames,varargin)
        sName = parseAndValidateNameInput(obj,lblNames);
        lblName = sName.LabelName;
        sublblName = sName.SublabelName;
        
        if isempty(sublblName)
            lblDef = getLabelDefinitionByName(obj,lblName);
            if lblDef.LabelType ~= lblType
                error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelMustBeROIorPoint',lblName,lblType));
            end
        else
            sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName);
            if sublblDef.LabelType ~= lblType
                error(message('shared_signalwavelet:labeling:labeledSignalSet:SublabelMustBeROIorPoint',sublblName,lblType));
            end
        end
        
        validateMemberIdx(obj,mIdx);
        
        [s, varargin] = parseAndValidateRowIndicesForNameSubName(obj,lblName,sublblName,mIdx,false,true,varargin{:});
        if ~isempty(varargin)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidNVLabelSublabelRowIndex'));
        end
        
        lblRowIdx = s.LabelRowIndex;
        sublblRowIdx = s.SublabelRowIndex;
        
        % When no indices have been specified, this is equivalent to
        % reseting the label or sublabel as this removes all the rows.
        if isempty(lblRowIdx) && isempty(sublblRowIdx)
            resetLabelValues(obj,mIdx,lblNames);
            return
        end
        
        if sName.HasSublabelName
            if isempty(obj.pLabels.(lblName){mIdx}.Sublabels)
                % The entry is empty so nothing to reset
                return;
            end
            
            if ~isempty(lblRowIdx) && isempty(sublblRowIdx)
                resetLabelValues(obj,mIdx,[lblName,sublblName],'LabelRowIndex',lblRowIdx);
            elseif isempty(lblRowIdx) && ~isempty(sublblRowIdx)
                obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){:}(sublblRowIdx,:) = [];
            else
                % Both indices specified
                obj.pLabels.(lblName){mIdx}(lblRowIdx,:).Sublabels{:,sublblName}{:}(sublblRowIdx,:) = [];
            end
        else
            obj.pLabels.(lblName){mIdx}(lblRowIdx,:) = [];
        end
    end
    
    function [value,isValid] = validatePropertyInPVPair(~,value)
        isValid = true;
        
        if ~ischar(value) && ~(isstring(value) && isscalar(value))
            isValid = false;
            return;
        end
        
        newValue = string(value);
        validStrings = ["LabelRowIndex","SublabelRowIndex"];
        strIdx = strcmpi(newValue,validStrings);
        if any(strIdx)
            value = string(validStrings(strIdx));
        else
            isValid = false;
        end
    end
    
    function [s, varargin] = parseAndValidateRowIndices(obj,varargin)
        s = struct;
        s.LabelRowIndex = [];
        s.SublabelRowIndex = [];
        
        removeIdx = [];
        for idx = 1:numel(varargin)
            inputVal = varargin{idx};
            [inputVal,isValid] = validatePropertyInPVPair(obj,inputVal);
            if ~isValid
                continue;
            end
            if inputVal == "LabelRowIndex"
                if numel(varargin) > idx
                    validateattributes(varargin{idx+1},{'numeric'},{'scalar','integer','positive'},'labeledSignalSet','RowIndex');
                    s.LabelRowIndex = varargin{idx+1};
                    removeIdx = [removeIdx [idx idx+1]]; %#ok<AGROW>
                else
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:SpecifyLabelRowIndex'));
                end
            elseif inputVal == "SublabelRowIndex"
                if numel(varargin) > idx
                    validateattributes(varargin{idx+1},{'numeric'},{'scalar','integer','positive'},'labeledSignalSet','SublabelRowIndex');
                    s.SublabelRowIndex = varargin{idx+1};
                    removeIdx = [removeIdx [idx idx+1]]; %#ok<AGROW>
                else
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:SpecifySublabelRowIndex'));
                end
            end
        end
        varargin(removeIdx) = [];
    end
    
    function [s,varargin] = parseAndValidateRowIndicesForNameSubName(obj,lblName,sublblName,mIdx,onlyNameSubNameFlag,allowSublblIdx,varargin)
        % Validate row indices
        %
        % onlyNameSubNameFlag true means that we ensure that row index can
        % be specified only when a name/sublabel pair has been specified.
        %
        % allowSublblIdx false ensures that a sublabel index has not been
        % specified.
        
        [s, varargin] = parseAndValidateRowIndices(obj,varargin{:});
        lblRowIdx = s.LabelRowIndex;
        sublblRowIdx = s.SublabelRowIndex;
        
        
        rowIndexHasBeenSpecified = ~isempty(lblRowIdx);
        subRowIndexHasBeenSpecified = ~isempty(sublblRowIdx);
        
        if subRowIndexHasBeenSpecified && ~allowSublblIdx
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SublabelRowIndexNotApply1'));
        end
        
        lblDef = getLabelDefinitionByName(obj,lblName);
        if ~isempty(sublblName)
            if rowIndexHasBeenSpecified
                if lblDef.LabelType == "attribute"
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:RowIdxAppliesWhenLabelOrLabelSublabel'));
                end
            end
        elseif rowIndexHasBeenSpecified && onlyNameSubNameFlag
            error(message('shared_signalwavelet:labeling:labeledSignalSet:RowIdxAppliesWhenLabelSublabel'));
        elseif rowIndexHasBeenSpecified && lblDef.LabelType == "attribute"
            error(message('shared_signalwavelet:labeling:labeledSignalSet:RowIdxAppliesWhenLabelOrLabelSublabel'));
        end
        
        if subRowIndexHasBeenSpecified
            if isempty(sublblName) || ...
                    obj.getSublabelDefinitionByName(lblName,sublblName).LabelType == "attribute"
                error(message('shared_signalwavelet:labeling:labeledSignalSet:SubRowIdxAppliesWhenLabelSublabel'));
            end
            
            if ~rowIndexHasBeenSpecified && lblDef.LabelType ~= "attribute"
                error(message('shared_signalwavelet:labeling:labeledSignalSet:RowSubRowRequired'));
            end
        end
        
        if rowIndexHasBeenSpecified
            if lblRowIdx > height(obj.pLabels.(lblName){mIdx})
                error(message('shared_signalwavelet:labeling:labeledSignalSet:RowExceedsLabelElements',lblName,num2str(mIdx)));
            end
            if subRowIndexHasBeenSpecified
                if sublblRowIdx > height(obj.pLabels.(lblName){mIdx}(lblRowIdx,:).Sublabels{:,sublblName}{:})
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:SubRowExceedsLabelElements',sublblName,num2str(mIdx)));
                end
            end
        else
            if subRowIndexHasBeenSpecified
                if sublblRowIdx > height(obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){:})
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:SubRowExceedsLabelElements',sublblName,num2str(mIdx)));
                end
            end
        end
    end
    
    function value = parseAndValidateAttributeValueInput(obj,lblDef,varargin)
        % Parser for functions setLabelValueInTable and
        % setSublabelValueInTable. This function takes varargin input as it
        % needs to validate the varargin input of the set value functions
        % for the case when the label is of type attribute.
        if numel(varargin) > 1
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TooManyInputsForAttributeLabel'));
        end
        
        if isempty(varargin)
            value = getDefaultValueForLabel(obj,lblDef);
            if isDefaultValueMissing(obj,value)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:SpecifyValueWhenNoDefault'));
            end
        else
            value = varargin{1};
        end
        
        if iscell(value) || (isstring(value) && numel(value) > 1)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:CellsStringVectsInvalidForAttributes'));
        end
        
        if ~iscell(value) && ~isstring(value) && ~iscategorical(value)
            % Deal with tables using a cell array so that we can count the
            % number of elements and index into the array
            value = {value};
        end
        
        value = validateLabelDataValues(obj,lblDef,value);
    end
    
    function [regionLimits,values] = parseAndValidateROIValueInput(obj,lblDef,varargin)
        % Parser for functions setLabelValueInTable and
        % setSublabelValueInTable. This function takes varargin input as it
        % needs to validate the varargin input of the set value functions
        % for the case when the label is of type 'roi'.
        
        if numel(varargin) > 2
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TooManyInputsForROILabel'));
        end
        
        if isempty(varargin)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MustSpecifyRegion'));
        end
        regionLimits = varargin{1};
        if isnumeric(regionLimits) && ismatrix(regionLimits) && numel(regionLimits) == 2
            regionLimits = regionLimits(:)'; % if only one vector make it a row
        end
        validateattributes(regionLimits,lblDef.ROILimitsDataType,{'ncols',2,'finite'},'labeledSignalSet','LIMITS');
        
        if ~issorted(regionLimits,2,'ascend')
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidROILimits'));
        end
        
        if numel(varargin) < 2
            values = getDefaultValueForLabel(obj,lblDef,size(regionLimits,1));
            if isDefaultValueMissing(obj,values)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:SpecifyValueWhenNoDefault'));
            end
        else
            values = varargin{2};
            if lblDef.LabelDataType == "numeric" && isempty(values)
                values = {values};
            end
        end
        
        if istable(values) || istimetable(values)
            % Deal with tables using a cell array so that we can count the
            % number of elements and index into the array
            values = {values};
        end
        
        if ~iscell(values) && ~isvector(values) && ~ischar(values)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidMultipleRegions'));
        elseif strcmp(lblDef.LabelDataType,"string") && iscell(values) && all(cellfun(@(x) (~isscalar(x)&&~ischar(x))&&~isempty(x),values))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:CellsVectsInvalidForString'));
        elseif strcmp(lblDef.LabelDataType,"categorical") && iscell(values) && all(cellfun(@(x) (~isscalar(x)&&~ischar(x))&&~isempty(x),values))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:CellsVectsInvalidForCategorical'));
        end
        
        if ~ischar(values) && isrow(values)
            values = values.';
        end
        
        values = validateLabelDataValues(obj,lblDef,values);
        
        numValues = numel(values);
        if size(regionLimits,1) ~= numValues
            error(message('shared_signalwavelet:labeling:labeledSignalSet:NumValuesAndRegionsNotMatch'));
        end
    end
    
    function [pointLocs,values] = parseAndValidatePointValueInput(obj,lblDef,varargin)
        % Parser for functions setLabelValueInTable and
        % setSublabelValueInTable. This function takes varargin input as it
        % needs to validate the varargin input of the set value functions
        % for the case when the label is of type point.
        
        if numel(varargin) > 2
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TooManyInputsForPointLabel'));
        end
        
        if isempty(varargin)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MustSpecifyLocation'));
        end
        pointLocs = varargin{1};
        validateattributes(pointLocs,lblDef.PointLocationsDataType,{'vector','finite'},'labeledSignalSet','LOCS');
        if isrow(pointLocs)
            pointLocs = pointLocs.';
        end
        
        if numel(varargin) < 2
            values = getDefaultValueForLabel(obj,lblDef,size(pointLocs,1));
            if isDefaultValueMissing(obj,values)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:SpecifyValueWhenNoDefault'));
            end
        else
            values = varargin{2};
            if lblDef.LabelDataType == "numeric" && isempty(values)
                values = {values};
            end
        end
        
        if istable(values) || istimetable(values)
            % Deal with tables using a cell array so that we can count the
            % number of elements and index into the array
            values = {values};
        end
        
        if ~iscell(values) && ~isvector(values) && ~ischar(values)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidMultiplePoints'));
        elseif strcmp(lblDef.LabelDataType,"string") && iscell(values) && all(cellfun(@(x) (~isscalar(x)&&~ischar(x))&&~isempty(x),values))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:CellsVectsInvalidForString'));
        elseif strcmp(lblDef.LabelDataType,"categorical") && iscell(values) && all(cellfun(@(x) (~isscalar(x)&&~ischar(x))&&~isempty(x),values))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:CellsVectsInvalidForCategorical'));
        end
        
        if ~ischar(values) && isrow(values)
            values = values.';
        end
        
        values = validateLabelDataValues(obj,lblDef,values);
        
        numValues = numel(values);
        if size(pointLocs,1) ~= numValues
            error(message('shared_signalwavelet:labeling:labeledSignalSet:NumValuesAndLocationsNotMatch'));
        end
    end
    
    function s = parseAndValidateNameInput(obj,nameInputs)
        %parseAndValidateNameInput Check if input has one or two names.
        %First name is a label name, second, if available, is a sublabel
        %name.
        s = struct('LabelName',strings(0),'SublabelName',strings(0),'HasSublabelName',false);
        
        if signalwavelet.internal.util.validateScalarString(nameInputs)
            lblName = validateLabelName(obj,nameInputs);
            s.LabelName = lblName;
            
        elseif (isstring(nameInputs) && isvector(nameInputs) && numel(nameInputs) == 2)...
                || (iscellstr(nameInputs) && numel(nameInputs) == 2)
            
            lblNames = string(nameInputs);
            lblName = validateLabelName(obj,lblNames(1));
            sublblName = validateSublabelName(obj,lblNames(1),lblNames(2));
            
            s.LabelName = lblName;
            s.SublabelName = sublblName;
            s.HasSublabelName = true;
        else
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidLabelSublabelName'));
        end
    end
    
    function validateAndSetLabelDefinitions(obj,lblDefVect)
        % Check that lblVect is valid and set the property
        
        validateattributes(lblDefVect,{'signalLabelDefinition'},{},'labeledSignalSet','label definitions');
        if isempty(lblDefVect)
            obj.pLabelDefinitions = copy(lblDefVect);
            return;
        end
        
        % Validate all labels
        validateattributes(lblDefVect,{'signalLabelDefinition'},{'vector'},'labeledSignalSet','label definitions');
        validateLabels(lblDefVect);
        
        % Ensure we store an independent copy of the definitions
        lblDefVect = copy(lblDefVect(:));
        
        if ~isempty(obj.pLabelDefinitions)
            % Check uniqueness of names of all previous and new labels
            newLblVect = [obj.pLabelDefinitions; lblDefVect];
            if ~isLabelNamesUnique(obj,newLblVect)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:UniqueLabels'));
            end
        end
        obj.pLabelDefinitions = [obj.pLabelDefinitions; lblDefVect];
    end
    
    function validateAndSetSublabelDefinitions(obj,sublblDefVect,lblName)
        % Check that lblVect is valid and set the sublabels property of
        % label named lblName
        
        % Validate all sublabels
        validateattributes(sublblDefVect,{'signalLabelDefinition'},{'vector'},'labeledSignalSet','label definitions');
        validateLabels(sublblDefVect,true);
        
        lblDef = getLabelDefinitionByName(obj,lblName);
        
        % Ensure we store an independent copy of the definitions
        sublblDefVect = copy(sublblDefVect(:));
        
        if ~isempty(lblDef.Sublabels)
            % Check uniqueness of names of all previous and new sublabels
            newSublblVect = [lblDef.Sublabels; sublblDefVect];
            if ~isLabelNamesUnique(obj,newSublblVect)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:UniqueSublabels'));
            end
        end
        lblDef.Sublabels = [lblDef.Sublabels; sublblDefVect];
    end
    
    function validateAndSetLabelValues(obj,lblValues)
        % Validate a table of label values based on label definitions
        obj.pLabels = lblValues;
    end
    
    function [flag,str] = validateStringInput(~,name)
        [flag,str] = signalwavelet.internal.util.validateScalarString(name);
    end
    
    function lblName = validateLabelName(obj,lblName)
        % Validate and convert name to string
        [flag,lblName] = validateStringInput(obj,lblName);
        if ~flag
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidLabelName'));
        end
        
        % Check if label name is in the label group
        if isempty(obj.pLabelDefinitions) || ~any(ismember([obj.pLabelDefinitions.Name],lblName))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:LabelDoesNotExist',lblName));
        end
    end
    
    function sublabelName = validateSublabelName(obj,lblName,sublabelName)
        % Validate and convert name to string
        lblName = validateLabelName(obj,lblName);
        
        [flag,sublabelName] = validateStringInput(obj,sublabelName);
        if ~flag
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidSublabelName'));
        end
        sublabelName = string(sublabelName);
        lblDef = getLabelDefinitionByName(obj,lblName);
        
        if isempty(lblDef.Sublabels)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:NoSublabelsAvailable',lblName));
        end
        
        % Check if label name is in the label group
        if ~any(ismember([lblDef.Sublabels.Name],sublabelName))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SublabelDoesNotExist',sublabelName));
        end
    end
    
    function value = validateLabelDataValues(~,lbl,value)
        if iscellstr(value) %#ok<ISCLSTR>
            value = string(value);
        elseif ischar(value)
            value = string(value);
        end
        
        % Call signalLabel validation method
        % Pass entire vector if possible to improve performance of these
        % checks. Pass one value at a time if we have a cell array or if we
        % need to do validation with a validation function.
        if iscell(value) || (any(strcmp(lbl.LabelDataType,{'numeric','logical','table','timetable'})) && ~isempty(lbl.ValidationFunction))
            for idx = 1:numel(value)
                if iscell(value)
                    val = value{idx};
                    value{idx} = validateLabelDataValue(lbl,val);
                else
                    val = value(idx);
                    value(idx) = validateLabelDataValue(lbl,val);
                end
            end
        else
            value = validateLabelDataValue(lbl,value);
        end
    end
    
    function validateMemberIdx(obj,mIdx)
        validateattributes(mIdx,{'numeric'},{'scalar','integer','positive'},'labeledSignalSet','MIDX');
        numMembers = obj.NumMembers;
        if mIdx > numMembers
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIndexExceedsNumMembers'));
        end
    end
    
    function mIdxVect = validateMemberIdxVect(obj,mIdxVect)
        validateattributes(mIdxVect,{'numeric'},{'vector','integer','positive'},'labeledSignalSet','MIDXVECT');
        mIdxVect = sort(mIdxVect);
        if numel(mIdxVect) ~= numel(unique(mIdxVect))
            
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIndexVectorNotUnique'));
        end
        numMembers = obj.NumMembers;
        if any(mIdxVect > numMembers)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberIndexVectorExceedsNumMembers'));
        end
    end
        
    function flag = isLabelNamesUnique(~,lblDefVect)
        lblDefVect = lblDefVect(:);
        lblNames = [lblDefVect.Name];
        flag = numel(unique(lblNames)) == numel(lblNames);
    end
    
    function T = createLabelValuesTable(obj,lblDefVect,sublabelFlag,numRows)
        % Create an empty/default table based on the vector of label
        % definitions lblDefVect. If sublabelFlag is true, then it creates
        % a sublabel table that does not have a sublabels variable.
        
        lblDefVect = lblDefVect(:);
        
        if nargin > 2 && sublabelFlag
            numRows = 1;
        elseif nargin < 4
            numRows = obj.NumMembers;
        end
        
        numLabels = size(lblDefVect,1);
        if numLabels == 0
            T = table('Size',[numRows, 0]);
            return;
        end
        
        T = [];
        for idx = 1:numLabels
            lbl = lblDefVect(idx);
            lblType = lbl.LabelType;
            hasSublabels = ~isempty(lbl.Sublabels);
            
            if lblType == "attribute"
                if hasSublabels
                    % Attributes always have an existing row (unlike ROI
                    % and point labels who have no rows until values start
                    % being added). So set the table to have 1 row and set
                    % the Value variable to the default value of the label.
                    % Then get the Sublabel table and set the sublabels
                    % variable.
                    val = table('Size',[1,2],'VariableTypes',["cell","table"],'VariableNames',["Value","Sublabels"]);
                    defaultVal = getDefaultValueForLabel(obj,lbl);
                    defaultVal = formatValueForTable(obj,defaultVal,lbl);
                    val.Value = defaultVal;
                    
                    sublabelTable = createLabelValuesTable(obj,lbl.Sublabels,true);
                    val.Sublabels = sublabelTable;
                    
                    lblData = cell(numRows,1);
                    lblData(:,1) = {val};
                else
                    val = getDefaultValueForLabel(obj,lbl);
                    if iscategorical(val)
                        lblData = repmat(val,numRows,1);
                    elseif isstring(val)
                        lblData = strings(numRows,1);
                        lblData(:,1) = val;
                    else
                        lblData = cell(numRows,1);
                        lblData(:,1) = {val};
                    end
                end
                if obj.pAssignIDToLabelValues
                    % Add a UID column and placeholder empty strings
                    uIDs = strings(numRows,1);
                    newTable = table(lblData,uIDs,'VariableNames',[lbl.Name lbl.Name+"_UID"]);
                else
                    newTable = table(lblData,'VariableNames',lbl.Name);
                end
                T = [T newTable]; %#ok<AGROW>
            elseif lblType == "roi"
                if hasSublabels
                    if obj.pAssignIDToLabelValues
                        val = table('Size',[0,4],'VariableTypes',["cell","cell","string","table"],'VariableNames',["ROILimits","Value","UID","Sublabels"]);
                        sublblNames = getSublabelVarNamesIncludingUID(obj,lbl);
                    else
                        val = table('Size',[0,3],'VariableTypes',["cell","cell","table"],'VariableNames',["ROILimits","Value","Sublabels"]);
                        sublblNames = [lbl.Sublabels.Name];
                    end
                    val.Sublabels = table.empty(0,numel(sublblNames));
                    val.Sublabels.Properties.VariableNames = sublblNames;
                else
                    if obj.pAssignIDToLabelValues
                        val = table('Size',[0,3],'VariableTypes',["cell","cell","string"],'VariableNames',["ROILimits","Value","UID"]);
                    else
                        val = table('Size',[0,2],'VariableTypes',["cell","cell"],'VariableNames',["ROILimits","Value"]);
                    end
                end
                lblData = cell(numRows,1);
                lblData(:,1) = {val};
                T = [T table(lblData,'VariableNames',lbl.Name)]; %#ok<AGROW>
            elseif lblType == "point"
                if hasSublabels
                    if obj.pAssignIDToLabelValues
                        val = table('Size',[0,4],'VariableTypes',["cell","cell","string","table"],'VariableNames',["Location","Value","UID","Sublabels"]);
                        sublblNames = getSublabelVarNamesIncludingUID(obj,lbl);
                    else
                        val = table('Size',[0,3],'VariableTypes',["cell","cell","table"],'VariableNames',["Location","Value","Sublabels"]);
                        sublblNames = [lbl.Sublabels.Name];
                    end
                    val.Sublabels = table.empty(0,numel(sublblNames));
                    val.Sublabels.Properties.VariableNames = sublblNames;
                else
                    if obj.pAssignIDToLabelValues
                        val = table('Size',[0,3],'VariableTypes',["cell","cell","string"],'VariableNames',["Location","Value","UID"]);
                    else
                        val = table('Size',[0,2],'VariableTypes',["cell","cell"],'VariableNames',["Location","Value"]);
                    end
                end
                lblData = cell(numRows,1);
                lblData(:,1) = {val};
                T = [T table(lblData,'VariableNames',lbl.Name)]; %#ok<AGROW>
            end
        end
    end
    
    function newInstanceIDs = setLabelValueInTable(obj,lblDef,lblDefID,mIdx,mID,lblRowIdx,varargin)
        % Set label values in Labels table
        % varargin contains the values
        % mID - member ID, and lblDefID label def ID are used to create
        % unique instance IDs for ROI and point labels when
        % pAssignIDToLabelValues flag is true.
        newInstanceIDs = strings(0,0);
        
        lblType = lblDef.LabelType;
        lblName = lblDef.Name;
        hasSublabels = ~isempty(lblDef.Sublabels);
        
        if lblType == "attribute"
            if ~isempty(lblRowIdx)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:RowIdxAppliesForROIorPoint'));
            end
        else
            lblRowIndexWasSpecified = false;
            numLabelRows = size(obj.pLabels.(lblName){mIdx},1);
            if isempty(lblRowIdx)
                if numLabelRows == 0
                    lblRowIdx = 0;
                else
                    lblRowIdx = numLabelRows + 1; % Append rows
                end
            else
                lblRowIndexWasSpecified = true;
                if lblRowIdx > numLabelRows
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:RowExceedsLabelElements',lblName,mIdx));
                end
            end
        end
        
        % Create sublabel tables for ROI and point labels as tables for
        % these types are created on the fly for each new value. Attribute
        % labels with sublabels always have a table. In all cases, if a row
        % index has been specified, then we are trying to modify an
        % existing label. In this case a sublabel table already exists for
        % any type of label.
        if hasSublabels && lblDef.LabelType ~= "attribute" && ~lblRowIndexWasSpecified
            sublabelTable = createLabelValuesTable(obj,lblDef.Sublabels,true);
        end
        
        switch lblType
            case "attribute"
                value = parseAndValidateAttributeValueInput(obj,lblDef,varargin{:});
                % Always add values other than strings as cell arrays
                value = formatValueForTable(obj,value,lblDef);
                
                if hasSublabels
                    obj.pLabels.(lblName){mIdx}.Value = value;
                else
                    obj.pLabels{mIdx,lblName} = value;
                end
            case "roi"
                [regionLimits,values] = parseAndValidateROIValueInput(obj,lblDef,varargin{:});
                numValues = numel(values);
                
                if lblRowIndexWasSpecified
                    if numValues > 1
                        error(message('shared_signalwavelet:labeling:labeledSignalSet:OneLabelValueAtATime'));
                    end
                    obj.pLabels.(lblName){mIdx}.ROILimits(lblRowIdx,:) = regionLimits;
                    obj.pLabels.(lblName){mIdx}.Value(lblRowIdx) = formatValueForTable(obj,values,lblDef);
                else
                    % Always add values other than strings as cell arrays
                    val = formatValueForTable(obj,values,lblDef);
                    
                    if hasSublabels
                        sublabelTable = repmat(sublabelTable,numValues,1);
                        if obj.pAssignIDToLabelValues
                            % Set value and assign unique IDs
                            newInstanceIDs = createLabelInstanceIDs(obj,numValues,mID,lblDefID);
                            newTbl = table(regionLimits,val,newInstanceIDs,sublabelTable,'VariableNames',["ROILimits","Value","UID","Sublabels"]);
                        else
                            % Set value
                            newTbl = table(regionLimits,val,sublabelTable,'VariableNames',["ROILimits","Value","Sublabels"]);
                        end
                    else
                        if obj.pAssignIDToLabelValues
                            % Set value and assign unique IDs
                            newInstanceIDs = createLabelInstanceIDs(obj,numValues,mID,lblDefID);
                            newTbl = table(regionLimits,val,newInstanceIDs,'VariableNames',["ROILimits","Value","UID"]);
                        else
                            newTbl = table(regionLimits,val,'VariableNames',["ROILimits","Value"]);
                        end
                    end
                    
                    if lblRowIdx == 0
                        obj.pLabels.(lblName){mIdx} = newTbl;
                    else
                        obj.pLabels.(lblName){mIdx}(lblRowIdx:lblRowIdx+numValues-1,:) = newTbl;
                    end
                end
                
            case "point"
                [pointLocs,values] = parseAndValidatePointValueInput(obj,lblDef,varargin{:});
                numValues = numel(values);
                
                if lblRowIndexWasSpecified
                    if  numValues > 1
                        error(message('shared_signalwavelet:labeling:labeledSignalSet:OneLabelValueAtATime'));
                    end
                    obj.pLabels.(lblName){mIdx}.Location(lblRowIdx,:) = pointLocs;
                    obj.pLabels.(lblName){mIdx}.Value(lblRowIdx) = formatValueForTable(obj,values,lblDef);
                else
                    % Always add values other than strings as cell arrays
                    val = formatValueForTable(obj,values,lblDef);
                    
                    if hasSublabels
                        sublabelTable = repmat(sublabelTable,numValues,1);
                        if obj.pAssignIDToLabelValues
                            % Set value and assign unique IDs
                            newInstanceIDs = createLabelInstanceIDs(obj,numValues,mID,lblDefID);
                            newTbl = table(pointLocs,val,newInstanceIDs,sublabelTable,'VariableNames',["Location","Value","UID","Sublabels"]);
                        else
                            newTbl = table(pointLocs,val,sublabelTable,'VariableNames',["Location","Value","Sublabels"]);
                        end
                    else
                        if obj.pAssignIDToLabelValues
                            % Set value and assign unique IDs
                            newInstanceIDs = createLabelInstanceIDs(obj,numValues,mID,lblDefID);
                            newTbl = table(pointLocs,val,newInstanceIDs,'VariableNames',["Location","Value","UID"]);
                        else
                            newTbl = table(pointLocs,val,'VariableNames',["Location","Value"]);
                        end
                    end
                    
                    if lblRowIdx == 0
                        obj.pLabels.(lblName){mIdx} = newTbl;
                    else
                        obj.pLabels.(lblName){mIdx}(lblRowIdx:lblRowIdx+numValues-1,:) = newTbl;
                    end
                end
        end
    end
    
    function newInstanceIDs = setSublabelValueInTable(obj,lblDef,sublblDef,sublblDefID,mIdx,mID,s,varargin)
        % Set sublabel values in Labels table
        newInstanceIDs = strings(0,0);
        labelRowIndex = s.LabelRowIndex;
        sublabelRowIndex = s.SublabelRowIndex;
        
        lblType = lblDef.LabelType;
        lblName = lblDef.Name;
        sublblType = sublblDef.LabelType;
        sublblName = sublblDef.Name;
        
        if lblType == "attribute" && ~isempty(labelRowIndex)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:RowIdxAppliesForROIorPoint'));
        end
        
        if lblType == "roi" || lblType == "point"
            if isempty(labelRowIndex)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:SpecifyRowIndexWhenSettingSublabel'));
            end
            numLabelRows = height(obj.pLabels.(lblName){mIdx});
            if labelRowIndex > numLabelRows
                error(message('shared_signalwavelet:labeling:labeledSignalSet:RowExceedsLabelElements',lblName,mIdx));
            end
        else
            labelRowIndex = 1;
        end
        
        if sublblType == "attribute"
            if ~isempty(sublabelRowIndex)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:SubRowIdxAppliesForROIorPoint'));
            end
        else
            sublbllRowIndexWasSpecified = false;
            numSublabelRows = height(obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){labelRowIndex});
            if isempty(sublabelRowIndex)
                if numSublabelRows == 0
                    sublabelRowIndex = 0;
                else
                    sublabelRowIndex = numSublabelRows + 1; % Append
                end
            else
                sublbllRowIndexWasSpecified = true;
                if sublabelRowIndex > numSublabelRows
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:SubRowExceedsLabelElements',sublblName,mIdx));
                end
            end
        end
        
        switch sublblType
            case "attribute"
                value = parseAndValidateAttributeValueInput(obj,sublblDef,varargin{:});
                % Always add values other than strings as cell arrays
                value = formatValueForTable(obj,value,sublblDef);
                obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName)(labelRowIndex) = value;
                
            case "roi"
                [regionLimits,values] = parseAndValidateROIValueInput(obj,sublblDef,varargin{:});
                numValues = numel(values);
                
                if sublbllRowIndexWasSpecified && numValues > 1
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:OneSublabelValueAtATime'));
                end
                
                % Always add values other than strings as cell arrays
                val = formatValueForTable(obj,values,sublblDef);
                
                if obj.pAssignIDToLabelValues
                    % Set values and assign unique IDs
                    if sublbllRowIndexWasSpecified
                        % Get the UID, do not assing a new one as the
                        % label value already exists.
                        newInstanceIDs = obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){labelRowIndex}(sublabelRowIndex:sublabelRowIndex+numValues-1,:).UID;
                    else
                        newInstanceIDs = createLabelInstanceIDs(obj,numValues,mID,sublblDefID);
                    end
                    newTbl = table(regionLimits,val,newInstanceIDs,'VariableNames',["ROILimits","Value","UID"]);
                else
                    % Set values
                    newTbl = table(regionLimits,val,'VariableNames',["ROILimits","Value"]);
                end
                
                if sublabelRowIndex == 0
                    obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){labelRowIndex} = newTbl;
                else
                    obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){labelRowIndex}(sublabelRowIndex:sublabelRowIndex+numValues-1,:) = newTbl;
                end
                
            case "point"
                [pointLocs,values] = parseAndValidatePointValueInput(obj,sublblDef,varargin{:});
                numValues = numel(values);
                
                if sublbllRowIndexWasSpecified && numValues > 1
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:OneSublabelValueAtATime'));
                end
                
                % Always add values other than strings as cell arrays
                val = formatValueForTable(obj,values,sublblDef);
                
                if obj.pAssignIDToLabelValues
                    % Set value and assign unique IDs
                    if sublbllRowIndexWasSpecified
                        % Get the UID, do not assing a new one as the
                        % label value already exists.
                        newInstanceIDs = obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){labelRowIndex}(sublabelRowIndex:sublabelRowIndex+numValues-1,:).UID;
                    else
                        newInstanceIDs = createLabelInstanceIDs(obj,numValues,mID,sublblDefID);
                    end
                    newTbl = table(pointLocs,val,newInstanceIDs,'VariableNames',["Location","Value","UID"]);
                else
                    newTbl = table(pointLocs,val,'VariableNames',["Location","Value"]);
                end
                
                if sublabelRowIndex == 0
                    obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){labelRowIndex} = newTbl;
                else
                    obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName){labelRowIndex}(sublabelRowIndex:sublabelRowIndex+numValues-1,:) = newTbl;
                end
        end
    end
    
    function value = getDefaultValueForLabel(obj,lbl,numValues)
        % getDefaultValueForLabel
        % Get default value from DefaultValue property of label. If empty,
        % then set the correct missing value based on the label data type.
        % The value is returned as a logical, numeric, or string (function
        % converts char to string).
        if nargin < 3
            numValues = 1;
        end
        
        if ~isempty(lbl.DefaultValue)
            value = lbl.DefaultValue;
            if lbl.LabelDataType == "categorical"
                value = createCategoricalValue(obj,lbl,value);
            elseif ischar(value)
                value = string(value(:)');
            end
            value = repmat(value,numValues,1);
        else
            value = getMissingValueForLabel(lbl);
        end
    end
    
    function value = readValue(~,value)
        %readValue If value is a cell array with a single element, extract
        %the value from it, otherwise return the value as is.
        if iscell(value) && numel(value) == 1
            value = value{:};
        end
    end
    
    function value = formatValueForTable(~,value,lblDef)
        if isrow(value)
            value = value.';
        end
        
        if ~isstring(value) && ~iscell(value) && ~iscategorical(value)
            if isempty(value)
                % We want a cell with an empty element not an empty cell
                % array
                value = {value};
            else
                value = mat2cell(value,ones(numel(value),1));
            end
        end
        
        if lblDef.LabelDataType == "categorical"
            value = categorical(string(value),lblDef.Categories);
        end
    end
    
    function value = createCategoricalValue(~,lblDef,value)
        value = categorical(string(value),lblDef.Categories);
    end
    
    function flag = isDefaultValueMissing(~,value)
        flag = false;
        if isstring(value) || iscategorical(value)
            if ismissing(value)
                flag = true;
            end
        elseif isempty(value)
            flag = true;
        end
    end
    
    function uIDs = createUIDs(~,N)
        uIDs = regexprep(matlab.lang.internal.uuid(N,1),'-','');
    end
    
    function instanceIDs = createLabelInstanceIDs(obj,N,memberID,labelDefID)
        % Label instance IDs are formed as follows:
        % memberID_labelDefID_uniqueID
        instanceIDs = strings(N,1);
        prefix = memberID + "_" + labelDefID + "_";
        uIDs = createUIDs(obj,N);
        for idx = 1:N
            instanceIDs(idx) = prefix + uIDs(idx);
        end
    end
    
    function names = getVarNamesIncludingUID(obj,lblName)
        % Get names for all label definitions, or target only label named
        % lblName
        names = strings(0,0);
        if nargin > 1
            lblDefs = getLabelDefinitionByName(obj,lblName);
        else
            lblDefs = getLabelDefinitions(obj);
        end
        lblNames = [lblDefs.Name];
        for idx = 1:numel(lblNames)
            names = [names; lblNames(idx)]; %#ok<AGROW>
            if lblDefs(idx).LabelType == "attribute"
                names = [names; lblNames(idx) + "_UID"]; %#ok<AGROW>
            end
        end
    end
    
    function names = getSublabelVarNamesIncludingUID(~,labelDef,sublblName)
        % Get names for all sublabels in labelDef or target only one label
        % definition named sublblName
        names = strings(0,0);
        sublblDefs = labelDef.Sublabels;
        sublblNames = [sublblDefs.Name];
        
        if nargin > 2
            lblIdx = (sublblNames == sublblName);
            sublblDefs = sublblDefs(lblIdx);
            sublblNames = sublblNames(lblIdx);
        end
        
        for idx = 1:numel(sublblNames)
            names = [names; sublblNames(idx)]; %#ok<AGROW>
            if sublblDefs(idx).LabelType == "attribute"
                names = [names; sublblNames(idx) + "_UID"]; %#ok<AGROW>
            end
        end
    end
    
    %----------------------------------------------------------------------
    % Copy
    %----------------------------------------------------------------------
    function cp = copyElement(obj)
        % Deep copy of labeledSignalSet
        cp = copyElement@matlab.mixin.Copyable(obj);
        cp.pLabelDefinitions = copy(obj.pLabelDefinitions);
        cp.pSource = copy(obj.pSource);
    end
end



end