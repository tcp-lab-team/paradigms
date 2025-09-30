classdef labeledSignalSet < signalwavelet.internal.labeling.LabeledSignalSetBase & matlab.mixin.CustomDisplay
%labeledSignalSet Labeled signal set
%   Use labeledSignalSet to store labeled signals along with the label
%   definitions. Create signal label definitions using a
%   signalLabelDefinition object.
%
%   LS = labeledSignalSet creates an empty labeled signal set. Add signals
%   and label definitions to the set using the addMembers and
%   addLabelDefinitions methods respectively.
%
%   LS = labeledSignalSet(SRC) creates a labeled signal set for input data
%   source, SRC. Add label definitions to the set using the
%   addLabelDefinitions method.
%
%   LS = labeledSignalSet(SRC,LBLDEFS) creates a labeled signal set for
%   input data source, SRC, based on the signal label definitions LBLDEFS.
%   LBLDEFS is a vector of signalLabelDefinition objects that you create
%   using the signalLabelDefinition function.
%
%   Input source, SRC, can be one of the following:
%
%   - N-column numeric matrix.
%
%     The labeled signal set has one member that contains N signals. For
%     example, labeledSignalSet(randn(10,3)) has one member that contains
%     three 10-sample signals.
%
%   - M-element cell array containing numeric matrices: 
%     {Matrix1(p1xq1),...,MatrixM(pMxqM)}. 
%
%     The labeled signal set has M members. Each member contains a number
%     of signals equal to the number of columns of the corresponding
%     matrix. For example, labeledSignalSet({randn(10,3),randn(17,9)}) has
%     two members. The first member contains three 10-sample signals. The
%     second member contains nine 17-sample signals.
%
%   - M-element cell array with each element being a cell array of
%     numeric vectors:
%     {{Vector11(p11x1),...Vector1R(p1Rx1)},...,{VectorM1(pM1x1),...VectorMT(pMTx1)}}
%
%     The labeled signal set has M members. Each signal within a member can
%     have any length. For example,
%     labeledSignalSet({{randn(10,1)},{randn(17,1),randn(27,1)}}) has two
%     members. The first member contains one 10-sample signal. The second
%     member contains a 17-sample signal and a 27-sample signal.
%
%   - Timetable with variables containing numeric values.
%
%     The labeled signal set has one member that contains a number of
%     signals equal to the number of table variables. The time values of
%     the timetable must be of type duration, unique, and increasing. For
%     example,
%     labeledSignalSet(timetable(seconds(1:10)',randn(10,3),randn(10,2)))
%     has one member that contains three signals sampled at 1 Hz for 10
%     seconds, and two signals sampled at 1 Hz for 10 seconds.
%
%   - M-element cell array of timetables.
%
%     The labeled signal set has M members. Each member contains a number
%     of signals equal to the number of variables in the corresponding
%     timetable. For example,
%     labeledSignalSet({timetable(seconds(1:10)',randn(10,3)),timetable(seconds(1:5)',randn(5,13))})
%     has two members. The first member contains three signals sampled at 1
%     Hz for 10 seconds. The second member contains 13 signals sampled at 1
%     Hz for 5 seconds.
%
%   - M-element cell array with each element being a cell array of
%     timetables:
%     {{Timetable11,...,Timetable1R},...,{TimetableM1,...,TimetableMT}}
%
%     The labeled signal set has M members. Each member can have any number
%     of timetables, and each timetable within a member can have any number
%     of variables. For example,
%     labeledSignalSet({{timetable(seconds(1:10)',randn(10,3)),timetable(seconds(1:7)',randn(7,2))},{timetable(seconds(1:3)',randn(3,1))}})
%     has two members. The first member contains three signals sampled at 1
%     Hz for 10 seconds and two signals sampled at 1 Hz for 7 seconds. The
%     second member contains one signal sampled at 1 Hz for 3 seconds.
%
%   - SignalDatastore pointing to M files or M in-memory signals.
%
%     The labeled signal set has M members. Each member contains all the
%     signals returned by the read of the corresponding datastore element.
%     The labeled signal set contains inherent time information provided by
%     the datastore.
%
%   - AudioDatastore pointing to M files.
%
%     The labeled signal set has M members. Each member contains all the
%     signals returned by the read of the corresponding datastore file. The
%     labeled signal set contains inherent time information provided by the
%     datastore.
%
%   LS = labeledSignalSet(SRC,...,'SampleRate',Fs) defines a sample rate,
%   Fs, for labeled signal set, LS. Set 'SampleRate' to a positive numeric
%   scalar to specify the same sample rate for all signals in the labeled
%   set. Set 'SampleRate' to a vector to specify that each member of the
%   labeled set has signals sampled at the same rate, but the sample rates
%   differ from member to member. The vector must have a number of elements
%   equal to the number of members of the set. If a member of a set has
%   signals with different sample rates, then specify the sample rates
%   using timetables. 'SampleRate' is valid only when the data source does
%   not contain inherent time information (e.g. timetables contain inherent
%   time information).
%
%   LS = labeledSignalSet(SRC,...,'SampleTime',Ts) defines a sample time,
%   Ts, for labeled signal set, LS. Set 'SampleTime' to a numeric or
%   duration scalar to specify the same sample time for all signals in the
%   labeled set. Set 'SampleTime' to a numeric or duration vector to
%   specify that each member of the labeled set has signals with the same
%   sample time, but the sample time differs from member to member. The
%   vector must have a number of elements equal to the number of members of
%   the set. If a member of a set has signals with different sample times,
%   then specify the sample times using timetables. 'SampleTime' is valid
%   only when the data source does not contain inherent time information
%   (e.g. timetables contain inherent time information).
%
%   LS = labeledSignalSet(SRC,...,'TimeValues',Tv) defines time values, Tv,
%   for labeled signal set, LS. Set 'TimeValues' to a numeric or duration
%   vector to specify the same time values for all signals in the labeled
%   set. The vector must have the same length as all the signals in the
%   set. Set 'TimeValues' to a numeric or duration matrix or cell array to
%   specify that each member of the labeled set has signals with the same
%   time values, but the time values differ from member to member. If
%   'TimeValues' is a matrix, then it must have a number of columns equal
%   to the number of members of the set. All signals in the set must have a
%   length equal to the number of rows of the matrix. If 'TimeValues' is a
%   cell array, then it must contain a number of vectors equal to the
%   number of members of the set. All signals in a member must have a
%   length equal to the number of elements of the corresponding vector in
%   the cell array. If a member of a set has signals with different time
%   values, then specify the time values using timetables. 'TimeValues' is
%   valid only when the data source does not contain inherent time
%   information (e.g. timetables contain inherent time information). Time
%   values must be unique and increasing.
%
%   LS = labeledSignalSet(SRC,...,'MemberNames',MNAMES) defines member
%   names, MNAMES, for labeled signal set, LS. Set 'MemberNames' to a
%   string array or cell array of character vectors to specify names for
%   each member. MNAMES must have a length equal to the number of members
%   in the set. If you do not specify member names, then labeledSignalSet
%   uses default names. Use the setMemberNames function to change member
%   names.
%
%   LS = labeledSignalSet(...,'Description',DESC) sets a description
%   character array or string scalar, DESC, to labeled signal set, LS.
%
%   labeledSignalSet properties:
%
%   Source           - Data source of labeled signal set (read-only)
%
%   NumMembers       - Number of members in labeled signal set (read-only)
%
%   TimeInformation  - Time information of labeled signal set source. It
%                      is set to 'none' when the signals in the source have
%                      no time information, 'sampleRate' when a sample rate
%                      has been specified, 'sampleTime' when a sample time
%                      has been specified, 'timeValues' when time values
%                      have been specified, and 'inherent' when the source
%                      elements contain inherent time information (e.g. a
%                      timetable contains inherent time information)
%
%   SampleRate       - Sample rate values (read-only)
%
%   SampleTime       - Sample time values (read-only)
%
%   TimeValues       - Vectors of time values (read-only)
%
%   Labels           - Table containing label values with variables for
%                      each label defined in the set, and one row for each
%                      member. The row names of the 'Labels' table are the
%                      member names (read-only)
%
%   Description      - Labeled signal set description
%
%   labeledSignalSet methods:
%
%   labeledSignalSet           - Create a labeledSignalSet object
%   labelDefinitionsSummary    - Get summary table of the labels defined in labeled signal set
%   labelDefinitionsHierarchy  - Get hierarchical list of label and sublabel names
%   head                       - Get first few member rows of 'Labels' table
%   getLabelDefinitions        - Get label definitions in labeled signal set
%   editLabelDefinition        - Edit label definition properties
%   addLabelDefinitions        - Add label definitions to labeled signal set
%   removeLabelDefinition      - Remove label definition from labeled signal set
%   setLabelValue              - Set label value in labeled signal set
%   resetLabelValues           - Reset labels to default values
%   removeRegionValue          - Remove row from ROI label
%   removePointValue           - Remove row from point label
%   getLabeledSignal           - Get labeled signals from labeled signal set
%   getLabelValues             - Get label values from labeled signal set
%   getSignal                  - Get signals from labeled signal set
%   getLabelNames              - Get label names in labeled signal set
%   getMemberNames             - Get member names in labeled signal set
%   setMemberNames             - Set member names in labeled signal set
%   addMembers                 - Add members to labeled signal set
%   removeMembers              - Remove members from labeled signal set
%   subset                     - Get a new labeled signal set with a subset of members
%   merge                      - Merge two or more labeled signal sets
%   
%   % EXAMPLE:
%      % Consider a set of whale sound recordings. The recorded whale sounds 
%      % consist of trills and moans. You want to inspect each signal and 
%      % label it to identify the whale type, trill regions, and moan regions.
%      % For each trill region, you also want to label the signal peaks above
%      % certain threshold.
%      
%      % Define an attribute label to store whale types. The possible whale
%      % categories are humpback, white, and blue whale.
%
%      dWhaleType = signalLabelDefinition('WhaleType',...
%          'LabelType','attribute',...
%          'LabelDataType','categorical',...
%          'Categories', ["blue","humpback","white"],...
%          'Description','Whale type');
%
%      % Define a region of interest label to capture moan regions.
%      % Define another ROI label to capture trill regions.
%
%      dMoans = signalLabelDefinition('MoanRegions',...
%          'LabelType','roi',...
%          'LabelDataType','logical',...
%          'Description','Regions where moans occur');
%      
%      dTrills = signalLabelDefinition('TrillRegions',...
%          'LabelType','roi',...
%          'LabelDataType','logical',...
%          'Description','Regions where trills occur');  
%     
%      % Finally define a point label to capture the trill peaks. Set this
%      % label as a sublabel of the dTrills definition.
%
%      dTrillPeaks = signalLabelDefinition('TrillPeaks',...
%          'LabelType','point',...
%          'LabelDataType','numeric',...
%          'Description','Trill peaks');
%
%      dTrills.Sublabels = dTrillPeaks;
%
%      % Create a labeledSignalSet with the whale signals and the label
%      % definitions. Add label values to identify the whale type, the moan
%      % and trill regions, and the peaks of the trills. 
%
%      load labelwhalesignals.mat
%      lblDefinitions = [dWhaleType,dMoans,dTrills];
%
%      LS = labeledSignalSet({whale1,whale2},lblDefinitions,...
%          'SampleRate',Fs,'Description','Characterize wave song regions');
%
%      % Visualize the label hierarchy and label properties using the 
%      % labelDefinitionsHierarchy, and labelDefinitionsSummary methods.
%
%      labelDefinitionsHierarchy(LS)
%      labelDefinitionsSummary(LS)
%
%      % The signals in the loaded data correspond to songs of two blue
%      % whales. Set the 'WhaleType' values for both signal members of the 
%      % labeled set.
%
%      setLabelValue(LS,1,'WhaleType','blue');
%      setLabelValue(LS,2,'WhaleType','blue');
%
%      % Visualize the 'Labels' property. Notice that the table has the 
%      % newly added 'WhaleType' values for both whale signals.
%      LS.Labels
%
%      % Visualize the whale songs to identify the trill and moan regions
%      figure
%      plot(seconds((0:length(whale1)-1)/Fs),whale1)
%      hold on
%      plot(seconds((0:length(whale2)-1)/Fs),whale2)
%
%      % Add the moan and trill regions to the labeled set. For ROI labels,
%      % specify ROI limits (in seconds for this example) and the label
%      % value.
%      setLabelValue(LS,1,'MoanRegions',[6.1 7.7; 11.4 13.1; 16.5 18.1],[true,true,true]);
%      setLabelValue(LS,2,'MoanRegions',[2.5 3.5; 5.8 8; 15.4 16.7],[true,true,true]);
%
%      trillRegionWhale1 = [1.4 3.1];
%      setLabelValue(LS,1,'TrillRegions',trillRegionWhale1,true);
%      trillRegionWhale2 = [11.1 13];
%      setLabelValue(LS,2,'TrillRegions',trillRegionWhale2,true);
%
%      % Label 3 peaks for each trill region. For point labels, specify
%      % the point locations (in seconds for this example) and their
%      % values.
%
%      whale1PeakLocs = [1.553,1.626,1.7];
%      whale1PeakVals = [0.211,0.254,0.211];
%
%      setLabelValue(LS,1,["TrillRegions","TrillPeaks"],...
%          whale1PeakLocs,whale1PeakVals,'LabelRowIndex',1);
%
%      whale2PeakLocs = [11.214,11.288,11.437];
%      whale2PeakVals = [0.119,0.14,0.15];
%
%      setLabelValue(LS,2,["TrillRegions","TrillPeaks"],...
%          whale2PeakLocs,whale2PeakVals,'LabelRowIndex',1);
%
%      % Explore the label values using the getLabelValues method
%      getLabelValues(LS)
%      getLabelValues(LS,1,'MoanRegions')
%
%      % View locations and values for the 'TrillPeaks' sublabel of 'TrillRegions'
%      [value, valueWithSublabel] = getLabelValues(LS,1,'TrillRegions')
%      getLabelValues(LS,1,["TrillRegions","TrillPeaks"])
%
%   See also signalLabelDefinition.
   
%   Copyright 2018-2020 MathWorks, Inc.

properties (Dependent)
    
    %SampleRate Sample rate values (read-only).
    SampleRate
    %SampleTime Sample time values (read-only).
    SampleTime
    %TimeValues Vectors of time values (read-only).
    TimeValues
    %TimeInformation Time information of labeled signal set source set
    %to 'none', 'sampleRate', 'sampleTime', 'timeValues', or 'inherent'.
    TimeInformation
end

properties (Access = protected)
    % Property list used to display the object
    PropertyList = {...
        'Source',...
        'NumMembers',...
        'TimeInformation',...
        'SampleRate',...
        'SampleTime',...
        'TimeValues',...
        'Labels',...
        'Description'}
end

%--------------------------------------------------------------------------
% Constructor
%--------------------------------------------------------------------------
methods
    function obj = labeledSignalSet(varargin)
        %labeledSignalSet Construct a labeled signal set
        src = [];
        lblDefsVect = signalLabelDefinition.empty;
        if ~isempty(varargin)
            src = varargin{1};
            varargin(1) = [];
        end
        obj.pSource = signalwavelet.internal.labeling.Source(src);
        hasSource = ~isempty(src);
        
        if ~isempty(varargin) && isa(varargin{1},'signalwavelet.internal.labeling.LightWeightLabeledSignalSet')
            % Convert a lightweight labeled signal set to a labeled signal
            % set.
            LWLSS = varargin{1};
            varargin(1) = [];
            lblDefsVect = getLabelDefinitions(LWLSS);
            validateAndSetLabelDefinitions(obj,lblDefsVect);
            if ~isempty(varargin)
                parseAndValidateConstructorInputs(obj,hasSource,varargin{:});
            end
            
            obj.Description = LWLSS.Description;
            tbl = getLabelValuesWithoutIDs(LWLSS);
            %Reset LWLSS row names to the default or input member names
            tbl.Properties.RowNames = getMemberNames(obj);
            obj.pLabels = tbl;
        else            
            if ~isempty(varargin) && isa(varargin{1},'signalLabelDefinition')
                lblDefsVect = varargin{1};
                varargin(1) = [];
            end
            
            validateAndSetLabelDefinitions(obj,lblDefsVect);
            parseAndValidateConstructorInputs(obj,hasSource,varargin{:});
            
            % Create the labels table
            tbl = createLabelValuesTable(obj,lblDefsVect);
            
            if ~isempty(tbl)
                tbl.Properties.RowNames = obj.pSource.getMemberNameList();
            end
            obj.pLabels = tbl;
        end
    end
end

%--------------------------------------------------------------------------
% Public methods
%--------------------------------------------------------------------------
methods
    function setLabelValue(obj,mIdx,lblNames,varargin)
        %setLabelValue Set label value in labeled signal set
        %   setLabelValue(LS,MIDX,LBLNAME,VAL) sets the attribute label
        %   named LBLNAME to value VAL for the MIDX-th member of the
        %   labeled signal set LS. LBLNAME is a character array or a string
        %   scalar. MIDX is a positive, integer, scalar that specifies the
        %   member row number as it appears in the 'Labels' table of
        %   labeled signal set, LS. VAL must be of the data type specified
        %   for LBLNAME. If label, LBLNAME, has a specified default value,
        %   then VAL can be omitted and the default value is set
        %   automatically.
        %
        %   setLabelValue(LS,MIDX,LBLNAME,LIMITS,VAL) adds regions to the
        %   ROI label named LBLNAME. LIMITS is a two-column matrix that
        %   defines the minimum and maximum indices, or times (if the set,
        %   LS, contains time information) over which the regions are
        %   defined. LIMITS must be of the data type specified by the
        %   'ROILimitsDataType' property of the label definition for label
        %   LBLNAME. You add as many new regions as the number of rows in
        %   LIMITS. VAL defines the values of each region and must be of
        %   the data type specified for LBLNAME. The number of elements in
        %   VAL must be the same as the number of rows in LIMITS. When
        %   LIMITS has more than one row, VAL must be a string array or a
        %   cell array of character arrays if the label data type is
        %   'string' or 'categorical'. It must be a vector or a cell array
        %   if the label data type is 'numeric' or 'logical', and must be a
        %   cell array of tables if the label data type is 'table' or
        %   'timetable'. If the label, LBLNAME, has a defined default
        %   value, then VAL can be omitted and the default value is set
        %   automatically to each new region.
        %
        %   setLabelValue(LS,MIDX,LBLNAME,LOCS,VAL) adds points to the
        %   point label named LBLNAME. LOCS is a vector that contains the
        %   indices, or times (if the set, LS, contains time information)
        %   that define the point locations. LOCS must be of the data type
        %   specified by the 'PointLocationsDataType' property of the label
        %   definition for label LBLNAME. You define as many new points as
        %   the number of elements in LOCS. VAL defines the values of each
        %   point and it must contain as many elements as the number of
        %   elements in LOCS. If the label, LBLNAME, has a defined default
        %   value, then VAL can be omitted and the default value is set
        %   automatically to each new point.
        %
        %   setLabelValue(...,'LabelRowIndex',RIDX) specifies the row index
        %   of the ROI or point label. The specified label value replaces
        %   the current value of that row. If this parameter is omitted,
        %   ROI or point values are appended to the existing label values.
        %   This parameter applies only for ROI and point labels.
        %
        %   Setting sublabel values:
        %
        %   If you want to set the value of a sublabel, make LBLNAME a two
        %   element string array or a two-element cell array of character
        %   arrays with the first element containing the parent label name,
        %   and the second element containing the sublabel name. When
        %   targeting a sublabel of an ROI or point parent label you must
        %   also specify the 'LabelRowIndex' of the parent label for which
        %   you want to set the value. The row of the parent must exist
        %   already before you can set a sublabel value to it.
        %
        %   setLabelValue(...,'SublabelRowIndex',SRIDX) specifies the row
        %   index, SRIDX, of the ROI or point sublabel as a positive,
        %   integer, scalar. The specified value replaces the current value
        %   of that sublabel row. This parameter applies only when a
        %   label/sublabel pair has been specified in the LBLNAME input and
        %   when the sublabel is of type ROI or point.
        
        validateMemberIdx(obj,mIdx);
        
        % Extract any pv-pairs
        [s, varargin] = parseAndValidateRowIndices(obj,varargin{:});
        sName = parseAndValidateNameInput(obj,lblNames);
        lblName = sName.LabelName;
        
        if sName.HasSublabelName
            sublblName = sName.SublabelName;
            
            lblDef = getLabelDefinitionByName(obj,lblName);
            sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName);
            
            setSublabelValueInTable(obj,lblDef,sublblDef,[],mIdx,[],s,varargin{:});
        else
            if ~isempty(s.SublabelRowIndex)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:SublabelRowIndexNotApply'));
            end
            
            lblDef = getLabelDefinitionByName(obj,lblName);
            setLabelValueInTable(obj,lblDef,[],mIdx,[],s.LabelRowIndex,varargin{:});
        end
    end
    
    function resetLabelValues(obj,mIdx,lblNames,varargin)
        %resetLabelValues Reset labels to default values
        %   resetLabelValues(LS) resets all label values of all members in
        %   labeled signal set, LS.
        %
        %   resetLabelValues(LS,MIDX) resets all label values for the
        %   MIDX-th member of the labeled signal set LS. MIDX is a
        %   positive, integer, scalar that specifies the member row number
        %   as it appears in the 'Labels' table of labeled signal set, LS.
        %
        %   resetLabelValues(LS,MIDX,LBLNAME) resets the values of label
        %   named LBLNAME, for the MIDX-th member of the labeled signal set
        %   LS. LBLNAME is a character array, or a string scalar containing
        %   a label name. If you want to reset a sublabel, make LBLNAME a
        %   two-element string array or a two-element cell array of
        %   character arrays with the first element containing the parent
        %   label name, and the second element containing the sublabel
        %   name. When targeting a sublabel of an ROI or point parent label
        %   you can specify the parent label row index as shown in the
        %   syntax below. Otherwise the sublabel values of all parent label
        %   rows are reset.
        %
        %   resetLabelValues(...,'LabelRowIndex',RIDX) specifies the row
        %   index, RIDX, of the ROI or point parent label for which you
        %   want to reset the sublabel value. RIDX is a positive, integer,
        %   scalar.
        
        narginchk(1,5);
        numInputArgs = nargin - numel(varargin);
        
        if numInputArgs < 3 && ~isempty(varargin)
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TooManyInputsLabelRowIndex'));
        end
        
        if numInputArgs == 1
            tbl = createLabelValuesTable(obj,obj.pLabelDefinitions);
            if ~isempty(tbl)
                tbl.Properties.RowNames =  obj.pSource.getMemberNameList();
                obj.pLabels = tbl;
            end
            return;
        end
        
        if numInputArgs > 1
            validateMemberIdx(obj,mIdx);
            
            if numInputArgs == 2
                T = createLabelValuesTable(obj,obj.pLabelDefinitions,false,1);
                if isempty(T)
                    return;
                end
                obj.pLabels(mIdx,:) = T;
            else
                sName = parseAndValidateNameInput(obj,lblNames);
                lblName = sName.LabelName;
                sublblName = sName.SublabelName;
                
                % Validate and parse row index. Row index input is valid
                % only when targeting a sublabel whose parent is an ROI or
                % point label. If the parent label is an attribute label
                % and an index has been specified, the parser below errors
                % out, otherwise it returns an index value of 1 that can be
                % used with the attribute label.
                [s, varargin] = parseAndValidateRowIndicesForNameSubName(obj,lblName,sublblName,mIdx,true,false,varargin{:});
                if ~isempty(varargin)
                    error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidNVLabelRowIndex'));
                end
                
                lblRowIdx = s.LabelRowIndex;
                
                if sName.HasSublabelName
                    sublblDef = getSublabelDefinitionByName(obj,lblName,sublblName);
                    % Create a sublabel table
                    T = createLabelValuesTable(obj,sublblDef,true);
                    if isempty(lblRowIdx)
                        if isempty(obj.pLabels.(lblName){mIdx}.Sublabels)
                            % The entry is empty so nothing to reset
                            return;
                        end
                        for idx = 1:numel(obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName))
                            obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName)(idx) = T.(sublblName);
                        end
                    else
                        obj.pLabels.(lblName){mIdx}.Sublabels.(sublblName)(lblRowIdx) = T.(sublblName);
                    end
                else
                    T = createLabelValuesTable(obj,obj.pLabelDefinitions,false,1);
                    obj.pLabels.(lblName)(mIdx) = T.(lblName);
                end
            end
        end
    end
    
    function [T,info] = getLabeledSignal(obj,mIdx)
        %getLabeledSignal Get labeled signals from labeled signal set
        %   [T,INFO] = getLabeledSignal(LS) returns a table, T, containing
        %   all the signals and labeled data in the labeled signal set, LS.
        %   INFO is a structure containing the time information of the
        %   signal set.
        %
        %   [T,INFO] = getLabeledSignal(LS,MIDX) returns a table containing
        %   the labeled signals for the MIDX-th member of the labeled
        %   signal set LS. MIDX is a positive, integer, scalar, that
        %   specifies the member row number as it appears in the 'Labels'
        %   table of labeled signal set, LS. INFO is a structure containing
        %   the time information of the requested signal.
        
        narginchk(1,2);
        
        T = obj.pLabels;
        
        if isempty(T) && obj.NumMembers > 0
            error(message('shared_signalwavelet:labeling:labeledSignalSet:NoLabels'));
        end
        if obj.NumMembers == 0
            error(message('shared_signalwavelet:labeling:labeledSignalSet:NoMembers'));
        end
        
        if nargin == 1
            mIdx = (1:obj.NumMembers);
        end
        if nargin > 1
            validateMemberIdx(obj,mIdx);
            T = T(mIdx,:);
        end
        
        s = cell(numel(mIdx),1);
        for idx = 1:numel(mIdx)
            s{idx} = getSignal(obj,mIdx(idx));
        end
        TS = table(s,'VariableNames',"Signal");
        T = [TS T];
        
        info = struct;
        info.TimeInformation = obj.TimeInformation;
        
        if info.TimeInformation == "sampleRate"
            info.SampleRate = obj.SampleRate;
            if numel(obj.SampleRate) > 1
                info.SampleRate = obj.SampleRate(mIdx);
            end
        end
        if info.TimeInformation == "sampleTime"
            info.SampleTime = obj.SampleTime;
            if numel(obj.SampleTime) > 1
                info.SampleTime = obj.SampleTime(mIdx);
            end
        end
        if info.TimeInformation == "timeValues"
            info.TimeValues = obj.TimeValues;
            if numel(obj.TimeValues) > 1
                info.TimeValues = obj.TimeValues(mIdx);
            end
        end
    end
    
    function [s,info] = getSignal(obj,mIdx)
        %getSignal Get signals from labeled signal set
        %   [S,INFO] = getSignal(LS,MIDX) returns the values for signals
        %   contained in member MIDX. MIDX is a positive, integer, scalar
        %   that specifies the member row number as it appears in the
        %   'Labels' table of labeled signal set, LS. INFO is a structure
        %   containing the time information of S.
        
        narginchk(2,2);
        validateMemberIdx(obj,mIdx);
        [s,info] = obj.pSource.getSignalEnsemble(mIdx);
    end
    
     function setMemberNames(obj,varargin)
        %setMemberNames Set member names in labeled signal set
        %   setMemberNames(LS,MNAMES) sets the member names to MNAMES, a
        %   string array or cell array of characters specifying names for
        %   each member. The length of MNAMES must be equal to the number
        %   of members.
        %
        %   setMemberNames(LS,MNAME,MIDX) sets the member name for
        %   the MIDX-th member of the labeled signal set, LS. MIDX is a
        %   positive integer that specifies the member row number
        %   as it appears in the 'Labels' table of LS.
        
        if obj.NumMembers == 0
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNoMembers'));
        elseif ~obj.pSource.isCustomMemberNamesSupported
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotSupported'));
        end
        
        narginchk(2,3);
        mNames = varargin{1};
        if iscellstr(mNames) || ischar(mNames) %#ok<ISCLSTR>
            mNames = string(mNames);
        end
        mNames = mNames(:);
        
        if nargin == 3
            %setMemberNames(LS, MNAME, MIDX)
            mIdx = varargin{2};
            validateMemberIdx(obj,mIdx);
        else
            mIdx = [];
        end
        
        mNames = validateMemberNames(obj,mNames,mIdx);
        obj.pSource.setMemberNameList(mNames,mIdx);
        
        %Update the Labels table
        if ~isempty(mIdx)
            %Only a single member name was updated
            obj.pLabels.Properties.RowNames(mIdx) = mNames;
        else
            %All member names were specified. 
            obj.pLabels.Properties.RowNames = mNames;
        end
     end
     
    function T = head(obj)
        %head Get first few member rows of 'Labels' table
        %   T = head(LS) returns the first few rows of the 'Labels' table
        %   of labeled signal set, LS.
        
        narginchk(1,1);
        T = head(obj.pLabels);
    end
    
    function T = labelDefinitionsSummary(obj,varargin)
        %labelDefinitionsSummary Get summary table of the labels defined in labeled signal set
        %   T = labelDefinitionsSummary(LS) returns a table, T, with the
        %   properties of labels defined in labeled signal set, LS.
        %
        %   T = labelDefinitionsSummary(LS,LBLNAME) returns a table, T,
        %   with the properties of label named LBLNAME defined in the
        %   labeled signal set, LS.
        %
        %   T = labelDefinitionsSummary(LS,LBLNAME,'sublbls') returns a
        %   table, T, with the properties of the sublabels defined for
        %   label named LBLNAME in labeled signal set, LS.
        
        varargin = convertCharsToStrings(varargin);
        T = labelDefinitionsSummary(obj.pLabelDefinitions,varargin{:});
    end
    
    function str = labelDefinitionsHierarchy(obj)
        %labelDefinitionsHierarchy Get hierarchical list of label and sublabel names
        %   STR = labelDefinitionsHierarchy(LS) returns a character array
        %   with a hierarchical list of label names and the corresponding
        %   sublabel names defined in labeled signal set, LS.
        
        lblDefVect = getLabelDefinitions(obj);
        str = labelDefinitionsHierarchy(lblDefVect);
    end
    
    function LSS = merge(varargin)
        %MERGE Merge two or more labeled signal sets
        %   L = MERGE(L1,...,LN) merges N labeled signal set objects,
        %   L1,...,LN, and produces a labeled signal set, L, containing all
        %   the members and label values of the input sets. All input sets
        %   must share exactly the same time information settings and data
        %   source type. The merged labeled signal set, L, contains a
        %   signal source, label definitions, and label values that are
        %   independent to those of the input labeled signal sets.
        
        narginchk(2,Inf);
        if ~all(cellfun(@(x)isa(x,'labeledSignalSet'), varargin))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidMergeClasses'));
        end
        
        % Compare properties and label definitions of labeled sets
        cnt = 1;
        classCell = {};
        for idx = 1:numel(varargin)
            testL = varargin{idx};
            if testL.NumMembers > 0
                classCell{cnt} = getSourceHandlerClass(testL.pSource); %#ok<AGROW>
                cnt = cnt+1;
            end
            timeInfoStr(idx) = testL.TimeInformation; %#ok<AGROW>
        end
        
        % All source classes must be the same
        if ~isempty(classCell) && numel(unique(classCell)) ~= 1
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidMergeSources'));
        end
        
        % Time info should be all the same, or have values of 'inherent'
        % and 'none' only
        tInfo = unique(timeInfoStr);
        if numel(tInfo) > 1 && (any(strcmp(tInfo,"sampleRate")) || any(strcmp(tInfo,"sampleTime")) || any(strcmp(tInfo,"timeValues")))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidMergeTimeInfo'));
        end
        
        % Validate inputs for unique members
        validateCompatibleMembers(varargin{:});
        
        LSS = varargin{1};
        % This validation fails only when any of the imported label
        % defintions has same name but different values
        validateCompatibleLabelDefinitionsForMerge(varargin{:});
        
        % Add sources to first labeled set and set label values on the
        % table
        LSS = copy(LSS);
        if isempty(classCell)
            % No data, so return
            return;
        end
        
        for idx = 2:numel(varargin)
            previousNumMembers= LSS.NumMembers;
            newLblSet = varargin{idx};
            
            % Add label definitions that are not present in L to new label
            % set
            lblDefs = getLabelDefinitions(LSS);
            lblNames = string([lblDefs.Name]);
            newLblDefs = getLabelDefinitions(newLblSet);
            newLblNames = string([newLblDefs.Name]);
            uniqueLblDefs = newLblDefs(~ismember(newLblNames,lblNames));
            if numel(uniqueLblDefs) > 0
                addLabelDefinitions(LSS,uniqueLblDefs);
            end
            
            lblDefs = getLabelDefinitions(LSS);
            lblNames = string([lblDefs.Name]);
            
            % Add label definitions that are not present in new label set
            % from L
            uniqueLblDefs = lblDefs(~ismember(lblNames,newLblNames));
            if numel(uniqueLblDefs) > 0
                addLabelDefinitions(newLblSet,uniqueLblDefs);
            end
            
            % Now both L and newLblSet should have same label definitions
            
            if newLblSet.NumMembers > 0
                % Get the private data source content from pSource so that
                % we can copy it if it is a handle (like a dataStore)
                src = newLblSet.pSource.getPrivateSourceData();
                mNames = getMemberNames(newLblSet);
                isDefault = isDefaultMemberNames(mNames);
                if isDefault || ~isCustomMemberNamesSupported(newLblSet.pSource)
                    mNames = [];
                end
                
                if isa(src,'handle')
                    src = copy(src);
                end
                if LSS.TimeInformation == "sampleRate"
                    addMembers(LSS,src,newLblSet.SampleRate,mNames);
                elseif LSS.TimeInformation == "sampleTime"
                    addMembers(LSS,src,newLblSet.SampleTime,mNames);
                elseif LSS.TimeInformation == "timeValues"
                    addMembers(LSS,src,newLblSet.TimeValues,mNames);
                else
                    addMembers(LSS,src,[],mNames);
                end
                
                if numel(lblDefs) > 0
                    % Fill in labels and sub labels on L table
                    % Reorder label names
                    
                    newLblDefs = getLabelDefinitions(newLblSet);
                    newLblNames = [newLblDefs.Name];
                    varIdx = arrayfun(@(s)find(strcmp(s,newLblNames) == true),lblNames);
                    LSS.pLabels(previousNumMembers+1:end,:) = newLblSet.pLabels(:,varIdx);
                    
                    for k = 1:numel(lblNames)
                        lblName = lblNames(k);
                        lblDef = getLabelDefinitionByName(LSS,lblName);
                        
                        if isempty(lblDef.Sublabels)
                            continue;
                        end
                        newLblDef = getLabelDefinitionByName(newLblSet,lblName);
                        
                        % Reorder sublabel names
                        sublblNames = [lblDef.Sublabels.Name];
                        newSublblNames = [newLblDef.Sublabels.Name];
                        subVarIdx = arrayfun(@(s)find(strcmp(s,newSublblNames) == true),sublblNames);
                        
                        for jj = previousNumMembers+1:LSS.NumMembers
                            LSS.pLabels.(lblName){jj}.Sublabels = LSS.pLabels.(lblName){jj}.Sublabels(:,subVarIdx);
                        end
                    end
                end
            end
        end
    end
end

%--------------------------------------------------------------------------
% Set/get methods
%--------------------------------------------------------------------------
methods
    function value = get.TimeInformation(obj)
        value = obj.pSource.getTimeInformation();
    end
    
    function set.TimeInformation(obj,value)
        % Only allow setting time information when source is empty
        if obj.NumMembers ~= 0 || obj.pSource.getTimeInformation() == "inherent"
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TimeInfoNotWriteable'));
        end
        value = validatestring(value,getAllowedStringValues(obj,'TimeInformation'),'labeledSignalSet','TimeInformation');
        
        if value == "none"
            obj.pSource.setTimeInformation(value);
        elseif value == "sampleRate"
            obj.pSource.setSampleRate([]);
        elseif value == "sampleTime"
            obj.pSource.setSampleTime([]);
        elseif value == "timeValues"
            obj.pSource.setTimeValues([]);
        end
    end
    
    function set.SampleRate(obj,~)
        if obj.TimeInformation ~= "sampleRate"
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SampleRateNotApplies'));
        else
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SampleRateReadOnly'));
        end
    end
    
    function value = get.SampleRate(obj)
        if obj.TimeInformation ~= "sampleRate"
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SampleRateNotApplies'));
        end
        value = obj.pSource.getSampleRate();
    end
    
    function set.SampleTime(obj,~)
        if obj.TimeInformation ~= "sampleTime"
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SampleTimeNotApplies'));
        else
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SampleTimeReadOnly'));
        end
    end
    
    function value = get.SampleTime(obj)
        if obj.TimeInformation ~= "sampleTime"
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SampleTimeNotApplies'));
        end
        value = obj.pSource.getSampleTime();
    end
    
    function set.TimeValues(obj,~)
        if obj.TimeInformation ~= "timeValues"
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TimeValuesNotApplies'));
        else
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TimeValuesReadOnly'));
        end
    end
    
    function value = get.TimeValues(obj)
        if obj.TimeInformation ~= "timeValues"
            error(message('shared_signalwavelet:labeling:labeledSignalSet:TimeValuesNotApplies'));
        end
        value = obj.pSource.getTimeValues();
    end
    
    function varargout = set(obj,varargin)
        % Override set to allow tab completion of enum properties
        [varargout{1:nargout}] = signalwavelet.internal.util.set(obj,varargin{:});
    end
end

methods (Hidden)
    function vals = getAllowedStringValues(~,prop)
        % Method used by signalset to enable tab completion of enum
        % properties.
        switch prop
            case 'TimeInformation'
                vals = {'sampleRate','sampleTime','timeValues','none'};
            otherwise
                vals = {};
        end
    end
    
    function value = getPrivateSourceData(this)
        value = this.pSource.getPrivateSourceData();
    end
    
    function flag = isSupportedInSignalAnalyzer(this)
        flag = this.pSource.isSupportedInSignalAnalyzer;
    end
    
    function flag = isSupportedInSignalLabeler(this)
        flag = this.pSource.isSupportedInSignalLabeler;
    end
    
    function L = concatenate(varargin)
        %concatenate Concatenate two or more labeled signal sets
        %   L = concatenate(L1,...,LN) concatenates N labeled signal set
        %   objects, (L1,...,LN), and produces labeled signal set, L,
        %   containing all the members and label values of the N input
        %   sets. All input sets must share exactly the same time
        %   information settings, label definitions, and data source type.
        %   The concatenated labeled signal set, L, contains a signal
        %   source, label definitions, and label values that are
        %   independent of the input labeled signal sets.
        
        narginchk(2,Inf);
        if ~all(cellfun(@(x)isa(x,'labeledSignalSet'), varargin))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidConcatClasses'));
        end
        
        L = varargin{1};
        lblDefs = getLabelDefinitions(L);
        lblNames = [lblDefs.Name];
        
        % Compare properties and label definitions of labeled sets
        cnt = 1;
        classCell = {};
        for idx = 1:numel(varargin)
            testL = varargin{idx};
            if testL.NumMembers > 0
                classCell{cnt} = getSourceHandlerClass(testL.pSource); %#ok<AGROW>
                cnt = cnt+1;
            end
            timeInfoStr(idx) = testL.TimeInformation; %#ok<AGROW>
        end
        
        % All source classes must be the same
        if ~isempty(classCell) && numel(unique(classCell)) ~= 1
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidConcatSources'));
        end
        
        % Time info should be all the same, or have values of 'inherent'
        % and 'none' only
        tInfo = unique(timeInfoStr);
        if numel(tInfo) > 1 && (any(strcmp(tInfo,"sampleRate")) || any(strcmp(tInfo,"sampleTime")) || any(strcmp(tInfo,"timeValues")))
            error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidConcatTimeInfo'));
        end
        
        % Validate inputs for compatible label definitions
        validateCompatibleLabelDefinitions(L,varargin{:});
        
        % Add sources to first labeled set and set label values on the
        % table
        L = copy(L);
        if isempty(classCell)
            % No data, so return
            return;
        end
        
        for idx = 2:numel(varargin)
            previousNumMembers= L.NumMembers;
            newLblSet = varargin{idx};
            if newLblSet.NumMembers > 0
                % Get the private data source content from pSource so that
                % we can copy it if it is a handle (like a dataStore)
                src = newLblSet.pSource.getPrivateSourceData();
                mNames = getMemberNames(newLblSet);
                isDefault = isDefaultMemberNames(mNames);
                if isDefault || ~isCustomMemberNamesSupported(newLblSet.pSource)
                    mNames = [];
                end
                
                if isa(src,'handle')
                    src = copy(src);
                end
                if L.TimeInformation == "sampleRate"
                    addMembers(L,src,newLblSet.SampleRate,mNames);
                elseif L.TimeInformation == "sampleTime"
                    addMembers(L,src,newLblSet.SampleTime,mNames);
                elseif L.TimeInformation == "timeValues"
                    addMembers(L,src,newLblSet.TimeValues,mNames);
                else
                    addMembers(L,src,[],mNames);
                end
                
                if numel(lblDefs) > 0
                    % Fill in labels and sub labels on L table
                    % Reorder label names
                    
                    newLblDefs = getLabelDefinitions(newLblSet);
                    newLblNames = [newLblDefs.Name];
                    varIdx = arrayfun(@(s)find(strcmp(s,newLblNames) == true),lblNames);
                    L.pLabels(previousNumMembers+1:end,:) = newLblSet.pLabels(:,varIdx);
                    
                    for k = 1:numel(lblNames)
                        lblName = lblNames(k);
                        lblDef = getLabelDefinitionByName(L,lblName);
                        
                        if isempty(lblDef.Sublabels)
                            continue;
                        end
                        newLblDef = getLabelDefinitionByName(newLblSet,lblName);
                        
                        % Reorder sublabel names
                        sublblNames = [lblDef.Sublabels.Name];
                        newSublblNames = [newLblDef.Sublabels.Name];
                        subVarIdx = arrayfun(@(s)find(strcmp(s,newSublblNames) == true),sublblNames);
                        
                        for jj = previousNumMembers+1:L.NumMembers
                            L.pLabels.(lblName){jj}.Sublabels = L.pLabels.(lblName){jj}.Sublabels(:,subVarIdx);
                        end
                    end
                end
            end
        end
    end
end

%--------------------------------------------------------------------------
% Protected methods
%--------------------------------------------------------------------------
methods (Access = protected)
    function parseAndValidateConstructorInputs(obj,hasSource,varargin)
        
        p = inputParser;
        p.FunctionName = 'labeledSignalSet';
        p.addParameter('SampleRate',[]);
        p.addParameter('SampleTime',[]);
        p.addParameter('TimeValues',[]);
        p.addParameter('Description',[]);
        p.addParameter('MemberNames',[]);
        parse(p,varargin{:});
        s = p.Results;
        
        if sum([~isempty(s.SampleRate) ~isempty(s.SampleTime) ~isempty(s.TimeValues)]) > 1
            error(message('shared_signalwavelet:labeling:labeledSignalSet:SimultaneousFsTsTv'));
        end
        
        % Set method of source handler validates time info values
        if ~isempty(s.SampleRate)
            if ~hasSource
                error(message('shared_signalwavelet:labeling:labeledSignalSet:NoSource'));
            end
            obj.pSource.setSampleRate(s.SampleRate);
        end
        if ~isempty(s.SampleTime)
            if ~hasSource
                error(message('shared_signalwavelet:labeling:labeledSignalSet:NoSource'));
            end
            obj.pSource.setSampleTime(s.SampleTime);
        end
        if ~isempty(s.TimeValues)
            if ~hasSource
                error(message('shared_signalwavelet:labeling:labeledSignalSet:NoSource'));
            end
            obj.pSource.setTimeValues(s.TimeValues);
        end
        
        % If time information has not been specified, then no ROI label
        % definition can have ROILimitsDataType set to duration. Same if
        % time information is set to sampleRate.
        idx = [];
        if ~isempty(obj.pLabelDefinitions)
            idx = [obj.pLabelDefinitions.LabelType] == 'roi';
        end
        if any(idx)
            roiDefs = obj.pLabelDefinitions(idx);
            if (obj.TimeInformation == "none" ||obj.TimeInformation == "sampleRate") && any([roiDefs.ROILimitsDataType] == "duration")
                error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidTimeTypeForROINoTimeInfo'));
            end
        end
        % If time information has not been specified, then no Point label
        % definition can have PointLocationsDataType set to duration.
        idx = [];
        if ~isempty(obj.pLabelDefinitions)
            idx = [obj.pLabelDefinitions.LabelType] == 'point';
        end
        if any(idx)
            pointDefs = obj.pLabelDefinitions(idx);
            if (obj.TimeInformation == "none" ||obj.TimeInformation == "sampleRate") && any([pointDefs.PointLocationsDataType] == "duration")
                error(message('shared_signalwavelet:labeling:labeledSignalSet:InvalidTimeTypeForPointNoTimeInfo'));
            end
        end
        
        if ~isempty(s.MemberNames)
            setMemberNames(obj,s.MemberNames);
        end
        obj.Description = s.Description;
    end
    
    function mNames = validateMemberNames(obj,mNames,mIdx)
       validateattributes(mNames,{'string','char'},{'vector','nonempty'},'labeledSignalSet','MNAMES');
       numMembers = obj.NumMembers;   
       
       if ~isempty(mIdx) && ~isscalar(mNames)  
           error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotScalar'));
       elseif isempty(mIdx) && length(mNames) ~= numMembers
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotEqualNumMembers'));
       elseif any(mNames == "")
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesEmpty'));
       end
         
       mNames = matlab.lang.makeValidName(mNames);
            
       if isscalar(mNames)
           allMNames = [getMemberNames(obj); mNames];
       else
           allMNames = mNames;
       end
       
       if length(unique(allMNames)) ~= length(allMNames)
           %Non-unique string was input
            error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotUnique'));
       end
    end
end

%--------------------------------------------------------------------------
% Display control, Copy
%--------------------------------------------------------------------------
methods (Access = protected)
    
    function propgrp = getPropertyGroups(obj)
        %getPropertyGroups Group properties in order for object display
        
        propList = obj.PropertyList;
        if strcmpi(obj.TimeInformation,'none') || strcmpi(obj.TimeInformation,'inherent')
            propList(strcmp(propList,'SampleRate')) = [];
            propList(strcmp(propList,'SampleTime')) = [];
            propList(strcmp(propList,'TimeValues')) = [];
        elseif strcmpi(obj.TimeInformation,'samplerate')
            propList(strcmp(propList,'SampleTime')) = [];
            propList(strcmp(propList,'TimeValues')) = [];
        elseif strcmpi(obj.TimeInformation,'sampletime')
            propList(strcmp(propList,'SampleRate')) = [];
            propList(strcmp(propList,'TimeValues')) = [];
        elseif strcmpi(obj.TimeInformation,'TimeValues')
            propList(strcmp(propList,'SampleRate')) = [];
            propList(strcmp(propList,'SampleTime')) = [];
        end
        propgrp = matlab.mixin.util.PropertyGroup(propList);
    end
    
    function s = getFooter(obj)
        %getFooter Get footer for object display
        if numel(obj) > 1 || numel(obj) == 0
            s = '';
            return;
        end
        fcnStr = getHelpHyperlink('labelDefinitionsHierarchy');
        s = sprintf(' %s %s %s\n','Use', fcnStr, 'to see a list of labels and sublabels.');
        
        fcnStr = getHelpHyperlink('setLabelValue');
        s = [s sprintf(' %s %s %s\n','Use', fcnStr, 'to add data to the set.')];
    end
end

end % classdef

%--------------------------------------------------------------------------
% Helper functions
%--------------------------------------------------------------------------
function str = getHelpHyperlink(fcnName)
%getHelpHyperlink Get command line help hyperlink
if isMATLABInNormalMode()
    str = sprintf('<a href="matlab:help(''%s'')">%s</a>',fcnName,fcnName);
else
    str = fcnName;
end
end

%------------------------------------------------------------------------
function flag = isMATLABInNormalMode()
% isMATLABInNormalMode True if we have java and desktop
flag = all([usejava('jvm') usejava('swing') usejava('awt') ...
    usejava('desktop')]);
end
%------------------------------------------------------------------------
function flag = isDefaultMemberNames(mNames)
flag = true;    
for idx = 1:length(mNames)
    currentName = char(mNames(idx));
    if length(currentName) < 9
        flag = false;
        break;
    end
    
    if ~strcmp(currentName(1:7),'Member{') || ~strcmp(string(currentName(end)),'}') || ~isstrprop(currentName(8:end-1),'digit')
        flag = false;
        break;
    end    
end
end