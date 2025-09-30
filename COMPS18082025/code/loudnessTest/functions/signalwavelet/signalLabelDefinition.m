classdef signalLabelDefinition < handle & matlab.mixin.CustomDisplay & matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
%signalLabelDefinition Create signal label definition
%   L = signalLabelDefinition(NAME) creates a signal label definition
%   object, L, with Name property set to NAME and all other properties set
%   to default values. NAME is a character array or a string scalar. Use a
%   vector of signalLabelDefinition objects to create a labeledSignalSet.
%
%   L = signalLabelDefinition(...,'LabelType',LABELTYPE) sets the
%   'LabelType' property of the signal label definition to LABELTYPE.
%   LABELTYPE can be one of 'attribute', 'roi', or 'point'. Define a
%   characteristic of a signal with an 'attribute' label type. Define
%   characteristics of regions of interest (ROI) in a signal with an 'roi'
%   label type. Define characteristics of points of interest in a signal
%   with a 'point' label type. The default is 'attribute'.
%
%   L = signalLabelDefinition(...,'LabelDataType',TYPE) sets the
%   'LabelDataType' property of the signal label definition to TYPE. TYPE
%   can be set to 'numeric', 'timetable', 'table', 'logical', 'string', or
%   'categorical'. The default is 'logical'. When TYPE is categorical, you
%   specify the array of categories using the 'Categories' parameter. A
%   labeledSignalSet object validates label values according to the
%   specified TYPE.
%
%   L = signalLabelDefinition(...,'Categories',CATS) sets the 'Categories'
%   property of the signal label definition to CATS, an array of unique
%   strings or a cell array of unique character arrays, that define the
%   valid category names that the label can take. This property applies
%   only when 'LabelDataType' is set to 'categorical'. The labeledSignalSet
%   object validates label values according to the 'Categories' list.
%
%   L = signalLabelDefinition(...,'ROILimitsDataType',TYPE) sets the
%   'ROILimitsDataType' property of the signal label definition to TYPE.
%   TYPE can be set to 'double', or 'duration'. The default is 'double'. A
%   labeledSignalSet object validates ROI label limit values according to
%   the 'ROILimitsDataType' setting. This property applies only when
%   'LabelType' is set to 'roi'.
%
%   L = signalLabelDefinition(...,'PointLocationsDataType',TYPE) sets the
%   'PointLocationsDataType' property of the signal label definition to
%   TYPE. TYPE can be set to 'double', or 'duration'. The default is
%   'double'. A labeledSignalSet object validates point label location
%   values according to the 'PointLocationsDataType' setting. This property
%   applies only when 'LabelType' is set to 'point'.
%
%   L = signalLabelDefinition(...,'ValidationFunction',FCN) specifies a
%   function handle, FCN, used to validate label values.
%   'ValidationFunction' applies only when 'LabelDataType' is set to
%   'numeric', 'logical', 'table', or 'timetable'. The function handle gets
%   a label value as an input (i.e. a numeric value, a logical, a
%   timetable, or a table) and outputs true if value is valid or false if
%   value is invalid. When omitted, validation reduces to checking that
%   label values are of the correct data type. Validation happens in a
%   labeledSignalSet object when you set label values.
%
%   L = signalLabelDefinition(...,'DefaultValue',DEFAULT) sets the
%   'DefaultValue' property of the signal label definition to DEFAULT. Use
%   this when you want the label to automatically take a default value,
%   DEFAULT. DEFAULT must be of the type specified in 'LabelDataType'.
%
%   L = signalLabelDefinition(...,'Description',DESC) adds a description to
%   the signal label definition. DESC is a character array or a string
%   scalar.
%
%   L = signalLabelDefinition(...,'Tag',TAG) adds a tag identifier, TAG, to
%   the signal label definition. TAG is a character array or a string
%   scalar.
%
%   L = signalLabelDefinition(...,'Sublabels',LBL) adds one or more
%   sublabels to the signal label definition. To specify a single sublabel,
%   set LBL to a single signal label definition object. To specify more
%   than one sublabel, set LBL to a vector of signal label definition
%   objects. Sublabels with type 'attribute' characterize signal regions
%   defined by an 'roi' parent label, or signal points defined by a 'point'
%   parent label.
%
%   signalLabelDefinition properties:
%
%   Name                   - Name of label
%   LabelType              - Type of label
%   LabelDataType          - Data type of label
%   Categories             - Array with valid label category names
%   ValidationFunction     - Validation function handle
%   ROILimitsDataType      - Data type of ROI limits
%   PointLocationsDataType - Data type of point locations
%   DefaultValue           - Default value of label
%   Sublabels              - Array of sublabels
%   Tag                    - Label tag
%   Description            - Label description
%
%   signalLabelDefinition methods:
%
%   labelDefinitionsSummary   - Get summary table of signal label definitions
%   labelDefinitionsHierarchy - Get hierarchical list of label and sublabel names
%
%   % EXAMPLE 1:
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
%   % EXAMPLE 2:
%      % Create a labeledSignalSet with the whale signals and the label
%      % definitions from the previous example. Add label values to 
%      % identify the whale type, the moan and trill regions, and the peaks
%      % of the trills. 
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
%      % View locations and values for the 'TrillPeaks'sublabel of 'TrillRegions'
%      [value, valueWithSublabel] = getLabelValues(LS,1,'TrillRegions')
%      getLabelValues(LS,1,["TrillRegions","TrillPeaks"])
%      
%   See also labeledSignalSet.

%   Copyright 2018 MathWorks, Inc.

properties 
    %Name Character or string scalar specifying the name of the label
    %category.
    Name
    %LabelType Label type set to 'attribute', 'roi', or 'point'.
    LabelType
    %LabelDataType Data type of label set to 'numeric', 'timetable',
    %'table', 'logical', 'string', or 'categorical'.
    LabelDataType
    %DefaultValue Default value for the label. Must be of the same data
    %type as the one defined by the 'LabelDataType' property. The default
    %value specification is optional.
    DefaultValue
    %Sublabels Array of signalLabelDefinition objects that act as
    %sublabels. Sublabel specification is optional.
    Sublabels
    %Tag Character array or string scalar that adds a tag identifier to the
    %label. The tag specification is optional.
    Tag
    %Description Character array or string scalar that describes the label.
    %The description is optional.
    Description
end

properties (Dependent)
    %Categories Cell array of character arrays or string array with valid
    %label category names used only when 'LabelDataType' is categorical.
    Categories
    %ValidationFunction Function handle used to validate label values. This
    %property applies when 'LabelDataType' is 'numeric', 'logical',
    %'table', or 'timetable'.
    ValidationFunction
    %ROILimitsDataType Data type of ROI limit values set to 'double' or
    %'duration'.
    ROILimitsDataType
    %PointLocationsDataType Data type of point locations set to 'double' or
    %'duration'.
    PointLocationsDataType
end

properties (Access = private)
    pCategories
    pValidationFunction = [];
    pROILimitsDataType = "double";
    pPointLocationsDataType = "double";
    pVersion = 1;
end

properties (Access = private)
    PropertyList = {...
        'Name',...
        'LabelType',...
        'LabelDataType',...
        'Categories',...
        'ValidationFunction',...
        'ROILimitsDataType',...
        'PointLocationsDataType',...
        'DefaultValue',...
        'Sublabels',...
        'Tag',...
        'Description'};
end
%--------------------------------------------------------------------------
methods
    function obj = signalLabelDefinition(name,varargin)
        narginchk(1,17);
        parseAndSetInputs(obj,name,varargin{:});
    end        
end

%--------------------------------------------------------------------------
% Set methods
methods
    function set.Name(obj,value)
        if (~ischar(value) && (~(isstring(value) && isscalar(value)))) || ~isvarname(value) || isempty(value)
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidName'));
        end         
        obj.Name = string(value);
    end
    
    function set.LabelType(obj,value)
        c = validatestring(value,getAllowedStringValues(obj,'LabelType'),'signalLabelDefinition','LabelType');
        obj.LabelType = string(c);
    end
    
    function set.LabelDataType(obj,value)
        c = validatestring(value,getAllowedStringValues(obj,'LabelDataType'),'signalLabelDefinition','LabelDataType');
        obj.LabelDataType = string(c);
    end
    
    function set.Categories(obj,value)
        if ~strcmp(obj.LabelDataType,'categorical')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:CategoricalNotApplies'));            
        end
        value = validateCategories(obj,value);
        obj.pCategories = value;
    end
    
    function value = get.Categories(obj)
        if ~strcmp(obj.LabelDataType,'categorical')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:CategoricalNotApplies'));
        end
        value = obj.pCategories;
    end
    
    function set.ROILimitsDataType(obj,value)
        if ~strcmp(obj.LabelType,'roi')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:ROILimitsTypeNotApplies'));            
        end
        value = validatestring(value,getAllowedStringValues(obj,'ROILimitsDataType'),'signalLabelDefinition','ROILimitsDataType');
        obj.pROILimitsDataType = string(value);
    end
    
    function value = get.ROILimitsDataType(obj)
        if ~strcmp(obj.LabelType,'roi')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:ROILimitsTypeNotApplies'));
        end
        value = obj.pROILimitsDataType;
    end    
    
    function set.PointLocationsDataType(obj,value)
        if ~strcmp(obj.LabelType,'point')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:PointLocsTypeNotApplies'));            
        end
        value = validatestring(value,getAllowedStringValues(obj,'PointLocationsDataType'),'signalLabelDefinition','PointLocationsDataType');
        obj.pPointLocationsDataType = string(value);
    end
    
    function value = get.PointLocationsDataType(obj)
        if ~strcmp(obj.LabelType,'point')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:PointLocsTypeNotApplies'));
        end
        value = obj.pPointLocationsDataType;
    end    
    
    function set.ValidationFunction(obj,value)
        if ~any(strcmp(obj.LabelDataType,{'numeric','logical','table','timetable'}))
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:ValidationFcnNotApplies'));            
        end
        validateValidationFunction(obj,value);
        obj.pValidationFunction = value;
    end
    
    function value = get.ValidationFunction(obj)
        if ~any(strcmp(obj.LabelDataType,{'numeric','logical','table','timetable'}))
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:ValidationFcnNotApplies'));
        end
        value = obj.pValidationFunction;
    end    
    
    function set.DefaultValue(obj,value)
        % We check this property being in agreement with the specified data
        % type at the moment the label is added to a labeled signal set.
        if ismissing(value)
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidMissingDefault'))
        end
        if isempty(value)
            obj.DefaultValue = [];
        else
            if ischar(value)
                value = string(value);
            end
            obj.DefaultValue = value;
        end
    end
    
    function set.Sublabels(obj,value)
        if isempty(value)
            obj.Sublabels = signalLabelDefinition.empty;
        else
            if ~isvector(value)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidSublabels'));
            end
            validateattributes(value,{'signalLabelDefinition'},{'vector'},'signalLabelDefinition','sublabels');
            hasSublabels = arrayfun(@(lbl) ~isempty(lbl.Sublabels), value, 'UniformOutput', true);
            if any(hasSublabels)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:SublabelsCannotHaveSublabels'));
            end
            if isrow(value)
                value = value(:);
            end
            % Ensure uniqueness of names
            allNames = [value.Name];
            if numel(allNames) ~= numel(unique(allNames))
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:UniqueSubNames'));
            end
               
            obj.Sublabels = copy(value);
        end            
    end
    
    function set.Tag(obj,value)
        if ~ischar(value) && (~(isstring(value) && isscalar(value)))
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidTag'));
        end
        obj.Tag = string(value);
    end
    
    function set.Description(obj,value)
        if ~ischar(value) && (~(isstring(value) && isscalar(value)))
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidDescription'));
        end
        obj.Description = string(value);
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
            case 'LabelType'
                vals = {'attribute','roi','point'};
            case 'LabelDataType'
                vals = {'numeric','logical','string','categorical','timetable','table'};
            case {'ROILimitsDataType','PointLocationsDataType'}
                vals = {'double','duration'};
            otherwise
                vals = {};
        end
    end     
end

%--------------------------------------------------------------------------
% Public methods
%--------------------------------------------------------------------------
methods
    function T = labelDefinitionsSummary(lblVect,varargin)
        %labelDefinitionsSummary Get summary table of signal label definitions
        %   T = labelDefinitionsSummary(LBLDEFS) returns table, T, with the
        %   properties of the label definitions contained in the array of
        %   signalLabelDefinition objects LBLDEFS.
        %
        %   T = labelDefinitionsSummary(LBLDEFS,LBLNAME) returns table, T,
        %   with the properties of label named LBLNAME. LBLNAME is a
        %   character array or a string scalar.
        %
        %   T = labelDefinitionsSummary(LBLDEFS,LBLNAME,'sublbls') returns
        %   table, T, with the properties of the sublabels defined for
        %   label definition named LBLNAME. When the 'sublbls' flag is
        %   omitted labelDefinitionsSummary shows the properties of the
        %   label definition LBLNAME.
                         
        narginchk(1,3);
        lblName = '';
        if nargin > 1
            lblName = varargin{1};
            if ~(isstring(lblName) && isscalar(lblName())) && ~ischar(lblName)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidNameForSummary'));                          
            end            
            lblName = string(lblName);
            idx = ismember([lblVect.Name],lblName);
            lblVect = lblVect(idx);
            if ~any(idx)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:NameNotFound',lblName));
            end
        end
        if nargin > 2
            validatestring(varargin{2},"sublbls",'signalLabelDefinition','sublabels flag');  
            sublabelVect = lblVect.Sublabels;
            if isempty(sublabelVect)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:NoSublabels',lblName));
            end
        end
                                        
        if nargin < 3                            
            T = getLabelDefinitionsTable(lblVect);                        
        else                       
            T = getLabelDefinitionsTable(sublabelVect);
            T.Sublabels = [];            
        end        
    end    
    
    function str = labelDefinitionsHierarchy(lblVect)
        %labelDefinitionsHierarchy Get hierarchical list of label and sublabel names
        %   STR = labelDefinitionsHierarchy(LBLDEFS) returns a character
        %   array that shows a hierarchical list of label names and the
        %   corresponding sublabel names defined in vector of signal label
        %   definition objects LBLDEFS.
        
        str = '';
        if isempty(lblVect)
            return;
        end
        
        names = [lblVect.Name];        
        for idx = 1:numel(names)
            str = [str sprintf('%s\n  %s',names(idx),'Sublabels: ')] ; %#ok<AGROW>
            sublblNames = [lblVect(idx).Sublabels.Name];
            if isempty(sublblNames)
                str = [str sprintf('%s\n','[]')]; %#ok<AGROW>
            else
                for k = 1:numel(sublblNames)
                    if k == 1
                        str = [str sprintf('%s\n',sublblNames(k))]; %#ok<AGROW>
                    else
                        str = [str sprintf('             %s\n',sublblNames(k))]; %#ok<AGROW>
                    end
                end
            end            
        end
        
    end        
end
%--------------------------------------------------------------------------
methods (Hidden)
    function validateLabels(lblVect,isSublabelFlag)
        % Ensure label definitions are valid. This method is called by
        % labeledSignalSet objects to validate input label definitions. If
        % isSublabelFlag this method assumes lblVect is a vector of
        % sublabels.
               
        if nargin == 1
            isSublabelFlag = false;
        end
        
        if ~isvector(lblVect)
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidLabelDefs'));            
        end
        lblVect = lblVect(:);
        
        % Check unique names
        lblNames = [lblVect.Name];
        if numel(unique(lblNames)) ~= numel(lblNames)
            if isSublabelFlag                
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:UniqueSublabelNames'));
            else
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:UniqueLabelNames'));
            end
        end

        % Check default values and ensure that a set of categories is
        % specified if data type is categorical
        for idx = 1:numel(lblVect)
            lblObj = lblVect(idx);
            hasDefaultValue = ~isempty(lblObj.DefaultValue);
            
            if strcmp(lblObj.LabelDataType,'categorical') && isempty(lblObj.Categories)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:CategoricalNonEmpty',lblObj.Name));                    
            end
            
            if hasDefaultValue
                validateLabelDataValue(lblObj,lblObj.DefaultValue,true);
            end
                            
            if isSublabelFlag
                % We are checking for a set of sublabels
                if ~isempty(lblObj.Sublabels)
                    error(message('shared_signalwavelet:labeling:signalLabelDefinition:SublabelsCannotHaveSublabelsHole',lblObj.Name));                   
                end
            else
                % Check sublabels
                sublbls = lblObj.Sublabels;
                if ~isempty(sublbls)
                    hasMoreThanOneLevelOfHierarchy = arrayfun(@(lbl) ~isempty(lbl.Sublabels), sublbls, 'UniformOutput', true);
                    if any(hasMoreThanOneLevelOfHierarchy)
                        error(message('shared_signalwavelet:labeling:signalLabelDefinition:SublabelsCannotHaveSublabelsHole',lblObj.Name));
                    end
                    
                    % Sublabel names must be unique
                    sublblNames = [sublbls.Name];
                    if numel(unique(sublblNames)) ~= numel(sublblNames)
                        error(message('shared_signalwavelet:labeling:signalLabelDefinition:UniqueSublabelNamesForLabel',lblObj.Name));                        
                    end
                end
            end
        end
    end   
    
    function dataValue = validateLabelDataValue(obj,dataValue,isDefaultValueCheck)
        % Validate if dataValue is valid for this type of label. This
        % method is called by labeledSignalSet objects to verify that label
        % values are compatible with the label type and label data type.
        if nargin == 2
            isDefaultValueCheck = false;
        end
        
        prefixStr = getString(message('shared_signalwavelet:labeling:signalLabelDefinition:ValueForLabel',obj.Name));
        if isDefaultValueCheck            
            prefixStr = getString(message('shared_signalwavelet:labeling:signalLabelDefinition:DefaultValueForLabel',obj.Name));
        end

        if isempty(dataValue)
            dataValue = getMissingValueForLabel(obj);
            return;
        end
        
        if obj.LabelDataType == "categorical"
            if (~ischar(dataValue) && ~iscellstr(dataValue) && ~(isstring(dataValue)) && ~iscategorical(dataValue)) || ...
                    (isDefaultValueCheck && ~ischar(dataValue) && ~isscalar(dataValue))
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidCategoryValue',prefixStr))
            end
            if iscategorical(dataValue)
                if ~isempty(setdiff(string(categories(dataValue)),obj.Categories)) || isordinal(dataValue)
                    error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidCategoryValue',prefixStr))
                end
                dataValue = string(dataValue);
            else
                dataValue = string(dataValue);
                if ~all(ismember(categories(categorical(dataValue)),obj.Categories))
                    error(message('shared_signalwavelet:labeling:signalLabelDefinition:OneOfCategorical',prefixStr,join(obj.Categories,', ')));
                end
            end
        elseif obj.LabelDataType == "string"            
            if (~ischar(dataValue) && ~iscellstr(dataValue) && ~isstring(dataValue)) || (isDefaultValueCheck && ~ischar(dataValue) && ~isscalar(dataValue))
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:MustBeString',prefixStr));                
            end      
            dataValue = string(dataValue);            
        elseif obj.LabelDataType == "numeric"
            if ~isnumeric(dataValue)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:MustBeNumeric',prefixStr));               
            elseif ~isempty(obj.pValidationFunction) && ~obj.pValidationFunction(dataValue)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:NotValidFromValidateFcn',prefixStr,func2str(obj.pValidationFunction)));
            end
        elseif obj.LabelDataType == "logical"
            if ~islogical(dataValue)                
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:MustBeLogical',prefixStr));
            elseif ~isempty(obj.pValidationFunction) && ~obj.pValidationFunction(dataValue)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:NotValidFromValidateFcn',prefixStr,func2str(obj.pValidationFunction)));                
            end            
        elseif obj.LabelDataType == "table"            
            if ~istable(dataValue)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:MustBeTable',prefixStr));
            elseif ~isempty(obj.pValidationFunction) && ~obj.pValidationFunction(dataValue)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:NotValidFromValidateFcn',prefixStr,func2str(obj.pValidationFunction)));
            end
        elseif obj.LabelDataType == "timetable"            
            if ~istimetable(dataValue)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:MustBeTimetable',prefixStr));
            elseif ~isempty(obj.pValidationFunction) && ~obj.pValidationFunction(dataValue)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:NotValidFromValidateFcn',prefixStr,func2str(obj.pValidationFunction)));
            end
        end        
    end      
    
    function value = getMissingValueForLabel(obj) 
        if (obj.LabelDataType == "string")
            value = string(missing);            
        elseif (obj.LabelDataType == "categorical")
            value = categorical(string(missing),obj.Categories);               
        elseif (obj.LabelDataType == "numeric")            
            value = [];
        elseif (obj.LabelDataType == "logical")            
            value = logical.empty;
        elseif (obj.LabelDataType == "table")            
            value = table.empty;
        elseif (obj.LabelDataType == "timetable")            
            value = timetable.empty;
        end        
    end 
    
    function value = validateCategories(~,value)        
        if ~isempty(value) 
            if ~((ischar(value) || isstring(value) || iscellstr(value)) && isvector(value)) || (numel(string(value)) ~= numel(unique(string(value))))
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidCategories'));
            end
            value = string(value);
            if isrow(value)
                value = value(:);
            end
        end
    end   
    
    function flag = compareDefinitions(lbl1,lbl2)
        % See if the two input label definitions are equal
        
        flag = thisCompareDefinitions(lbl1,lbl2);
        if ~flag
            return;
        end
        
        % If flag is true we are guaranteed that we have equal number of
        % sublabels with equal names. Now we need to check the rest of the
        % sublabel properties. 
        
        % Loop over sublabels
        if ~isempty(lbl1.Sublabels)
            sublbl2Names = [lbl2.Sublabels.Name];
            
            for idx = 1:numel(lbl1.Sublabels)
                % Compare sublabels of same name
                sublbl1 = lbl1.Sublabels(idx);
                nameIdx = sublbl2Names == sublbl1.Name;
                sublbl2 = lbl2.Sublabels(nameIdx);
                flag = thisCompareDefinitions(sublbl1,sublbl2);
                if ~flag
                    return;
                end
            end
        end
    end
end

%--------------------------------------------------------------------------
methods (Access = private)
    function parseAndSetInputs(obj,name,varargin)
        obj.Name = name;
        
        p = inputParser;
        p.FunctionName = 'signalLabelDefinition';
        p.addParameter('LabelType',"attribute");
        p.addParameter('LabelDataType',"logical");
        p.addParameter('Categories',[]);
        p.addParameter('ROILimitsDataType',strings(0,0));
        p.addParameter('PointLocationsDataType',strings(0,0));
        p.addParameter('ValidationFunction',[]);
        p.addParameter('DefaultValue',[]);
        p.addParameter('Sublabels',signalLabelDefinition.empty);
        p.addParameter('Tag',"");
        p.addParameter('Description',"");
        parse(p,varargin{:});
        s = p.Results;
        
        obj.LabelType = s.LabelType;
        obj.LabelDataType = s.LabelDataType;
        % Categories should not be specified if LabelDataType was not set
        % to 'categorical'.
        if ~isempty(s.Categories) && ~strcmp(obj.LabelDataType,'categorical')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:CategoricalNotApplies'));            
        end
        if isempty(s.Categories)
            s.Categories = string.empty;
        end
        categories = validateCategories(obj,s.Categories);
        obj.pCategories = categories;        
        
        % ROILimitsDataType should not be specified if LabelType was not
        % set to 'roi'
        if ~isempty(s.ROILimitsDataType) && ~strcmp(obj.LabelType,'roi')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:ROILimitsTypeNotApplies'));            
        end        
        if isempty(s.ROILimitsDataType)
            s.ROILimitsDataType = "double";
        end
        if s.LabelType == "roi"
            obj.ROILimitsDataType = s.ROILimitsDataType;
        end
        
        if ~isempty(s.PointLocationsDataType) && ~strcmp(obj.LabelType,'point')
            error(message('shared_signalwavelet:labeling:signalLabelDefinition:PointLocsTypeNotApplies'));
        end         
        if isempty(s.PointLocationsDataType)
            s.PointLocationsDataType = "double";
        end
        if obj.LabelType == "point"
            obj.PointLocationsDataType = s.PointLocationsDataType;
        end
                
        if ~isempty(s.ValidationFunction)
            obj.ValidationFunction = s.ValidationFunction;
        end
        
        obj.Sublabels = s.Sublabels;
        obj.DefaultValue = s.DefaultValue;
        obj.Tag = s.Tag;
        obj.Description = s.Description;
        
        if ~isempty(obj.DefaultValue)
            if obj.LabelDataType == "categorical" && isempty(obj.Categories)
                error(message('shared_signalwavelet:labeling:signalLabelDefinition:InvalidCategoriesDefault'));
            end
            validateLabelDataValue(obj,obj.DefaultValue,true);
        end
    end        
    
    function T = getLabelDefinitionsTable(lblVect)
        % Create a label definitions table
            
        lblVect = lblVect(:);
        s = struct;
        s.LabelNames = [lblVect.Name]';
        s.LabelTypes = [lblVect.LabelType]';
        s.LabelDataTypes = [lblVect.LabelDataType]';        
        s.DefaultValues = arrayfun(@(lbl) lbl.DefaultValue, lblVect, 'UniformOutput', false);
        s.Tags = [lblVect.Tag]';
        s.Descriptions = [lblVect.Description]';
        
        s.Categories = cell(numel(lblVect),1);
        s.ValidationFunctions = cell(numel(lblVect),1);        
        s.Sublabels = {};
        
        for idx = 1:numel(lblVect)            
            s.Sublabels{idx,1} = [];
            % Add sublabel groups
            if ~isempty(lblVect(idx).Sublabels)
                s.Sublabels{idx,1} = lblVect(idx).Sublabels;                
            end
            if any(strcmp(s.LabelDataTypes{idx},{'numeric','logical','table','timetable'}))
                s.ValidationFunctions{idx} = lblVect(idx).ValidationFunction;
            else
                s.ValidationFunctions{idx} = "N/A";
            end
            if strcmp(s.LabelDataTypes{idx},'categorical')
                s.Categories{idx} = lblVect(idx).Categories;
            else
                s.Categories{idx} = "N/A";
            end
        end
        
        T = table(s.LabelNames,s.LabelTypes,s.LabelDataTypes,s.Categories,s.ValidationFunctions,...
            s.DefaultValues,s.Sublabels,s.Tags,s.Descriptions,...
            'VariableNames',["LabelName","LabelType","LabelDataType","Categories",...
            "ValidationFunction","DefaultValue","Sublabels","Tag","Description"]);
    end    
        
    function validateValidationFunction(~,value)
        if ~isempty(value)
            validateattributes(value,{'function_handle'},{},'signalLabelDefinition','ValidationFunction');
        end
    end
    
    function flag = thisCompareDefinitions(lbl1,lbl2)
        
        flag = lbl1.Name == lbl2.Name;
        if ~flag
            return;
        end
        flag = lbl1.LabelType == lbl2.LabelType;
        if ~flag
            return;
        end
        if lbl1.LabelType == "roi"
            flag = lbl1.pROILimitsDataType == lbl2.pROILimitsDataType;
        end
        if ~flag
            return
        end
        if lbl1.LabelType == "point"
            flag = lbl1.pPointLocationsDataType == lbl2.pPointLocationsDataType;
        end
        if ~flag
            return
        end
        flag = lbl1.LabelDataType == lbl2.LabelDataType;
        if ~flag
            return;
        end
        if lbl1.LabelDataType == "categorical"
            flag = isequal(lbl1.pCategories,lbl2.pCategories);
        end
        if ~flag
            return;
        end
        if any(strcmp(lbl1.LabelDataType,{'numeric','logical','table','timetable'}))
            flag = isequal(lbl1.pValidationFunction,lbl2.pValidationFunction);
        end
        if ~flag
            return;
        end
        flag = isequal(lbl1.DefaultValue,lbl2.DefaultValue);
        if ~flag
            return;
        end
        flag = lbl1.Tag == lbl2.Tag;
        if ~flag
            return;
        end
        flag = lbl1.Description == lbl2.Description;
        if ~flag
            return;
        end
        
        % Check same number of sublanels and same sublabel names
        flag = numel(lbl1.Sublabels) == numel(lbl2.Sublabels);
        if ~flag
            return;
        end
        
        if ~isempty(lbl1.Sublabels)
            flag = isempty(setdiff([lbl1.Sublabels.Name],[lbl2.Sublabels.Name]));
        end
    end
end

%--------------------------------------------------------------------------
% Display object methods
%--------------------------------------------------------------------------
methods (Access = protected)
    function s = getHeader(obj)
        %getHeader Get header for object display               
        if numel(obj) > 1 || numel(obj) == 0
            sz = size(obj);
            hl = getHelpHyperlink('signalLabelDefinition');
            s = sprintf('%s\x00D7%s %s %s\n',num2str(sz(1)),num2str(sz(2)),hl, 'array');            
        else
            s = getHeader@matlab.mixin.CustomDisplay(obj);
        end
    end
    
    function propgrp = getPropertyGroups(obj)
        %getPropertyGroups Group properties in order for object display
        if numel(obj) > 1 || numel(obj) == 0
            propgrp = [];
            return;
        end
        propList = obj.PropertyList;
        if ~strcmp(obj.LabelDataType,'categorical')
            propList(strcmp(propList,'Categories')) = [];
        end
        if ~any(strcmp(obj.LabelDataType,{'numeric','logical','table','timetable'}))
            propList(strcmp(propList,'ValidationFunction')) = [];
        end   
        if ~strcmp(obj.LabelType,'roi')
            propList(strcmp(propList,'ROILimitsDataType')) = [];
        end    
        if ~strcmp(obj.LabelType,'point')
            propList(strcmp(propList,'PointLocationsDataType')) = [];
        end         
        propgrp = matlab.mixin.util.PropertyGroup(propList);
    end
    
    function s = getFooter(obj)
        %getFooter Get footer for object display
         if numel(obj) > 1 || numel(obj) == 0
            s = '';
            return;
        end
        fcnStr = getHelpHyperlink('labeledSignalSet');
        s = sprintf(' %s %s %s','Use', fcnStr, 'to create a labeled signal set.');
    end    
    
    function cp = copyElement(obj)
        % Deep copy of labeledSignalSet    
        validateattributes(obj,{'signalLabelDefinition'},{'vector'},'signalLabelDefinition','input');
        cp = [];
        for idx = 1:numel(obj)
            thisObj = obj(idx);
            thisCp = copyElement@matlab.mixin.Copyable(thisObj);
            if ~isempty(thisObj.Sublabels)
                thisCp.Sublabels = copy(thisObj.Sublabels);
            end
            cp = [cp thisCp]; %#ok<AGROW>
        end
        if ~isrow(obj)
            cp = cp(:);
        end
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