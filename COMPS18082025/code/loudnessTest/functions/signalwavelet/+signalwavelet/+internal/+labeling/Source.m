classdef Source < handle & matlab.mixin.Copyable
%Source Labeling source   
% 
%   For internal use only. 
    
%   Copyright 2018-2020 MathWorks, Inc.

properties (Access = private)
    pSourceHandler  
    pTimeInformation
end

methods (Hidden)
    function obj = Source(inputData)
        %SOURCE

        % Instantiate a source handler based on the data type

        % pTimeInformation keeps time info value until a source handler is
        % instantiated. Once that happens, time information value is
        % derived from the source handler.
        obj.pTimeInformation = "none";
        if isempty(inputData)
            obj.pSourceHandler = [];
        else
            obj.selectSourceHandler(inputData);
        end
    end

    %----------------------------------------------------------------------
    function s = addMembers(obj,inputData,tinfoValue,mnames)
        narginchk(2,4);
        if isempty(inputData)
            error(message('shared_signalwavelet:labeling:Source:EmptyDataAddMembers'));
        end
        if isempty(obj.pSourceHandler)

            % select source handler will check if time info setting is
            % valid         
            cacheTimeInformation = obj.pTimeInformation;
            obj.selectSourceHandler(inputData,tinfoValue);
            if obj.pSourceHandler.isSourceTimeInfoInherent()
                obj.pTimeInformation = 'inherent';                
            elseif any(strcmp(obj.pTimeInformation,["sampleRate","sampleTime","timeValues"])) && (nargin < 3 || isempty(tinfoValue))
                obj.pSourceHandler = [];
                error(message('shared_signalwavelet:labeling:Source:EmptyTinfo'));
            end
            
            s = struct;
            s.NewMemberNameList = obj.getMemberNameList();
            s.NewNumMembers = obj.getNumMembers();
            
            if ~isempty(mnames) && (numel(mnames) ~= s.NewNumMembers)
                error(message('shared_signalwavelet:labeling:labeledSignalSet:MemberNamesNotEqualNumMembersAdded'));
            end
                        
            % Try to set time info - if an error occurs remove the source
            % handler
            try
                if obj.pTimeInformation == "sampleRate"
                    setSampleRate(obj.pSourceHandler,tinfoValue);
                elseif obj.pTimeInformation == "sampleTime"
                    setSampleTime(obj.pSourceHandler,tinfoValue);
                elseif obj.pTimeInformation == "timeValues"
                    setTimeValues(obj.pSourceHandler,tinfoValue);
                end
            catch ME
                obj.pSourceHandler = [];
                obj.pTimeInformation = cacheTimeInformation;
                rethrow(ME);
            end
            obj.pTimeInformation = [];            
        else
            % This will error out if source is not compatible (true flag)
            obj.pSourceHandler.isDataSupportedBySourceHandler(inputData,true);
            
            validateTinfoSupport(obj,obj.pSourceHandler.isSourceTimeInfoInherent(),...
                ~isempty(tinfoValue),obj.getTimeInformation());
            
            if isCustomMemberNamesSupported(obj)
                s = addMembers(obj.pSourceHandler,inputData,tinfoValue,mnames);
            else
                s = addMembers(obj.pSourceHandler,inputData,tinfoValue);
            end
        end
        
        if ~isfield(s,'NewMemberNameList') || ~isfield(s,'NewNumMembers')
            error(message('shared_signalwavelet:labeling:Source:InvalidAddMembersStruct'));            
        end
    end

    function removeMembers(obj,mIdxVect)
        if isempty(obj.pSourceHandler)
            return;
        end
        removeMembers(obj.pSourceHandler,mIdxVect);  
        if obj.getNumMembers == 0
            timeInfo = obj.pSourceHandler.getTimeInformation();
            obj.pSourceHandler = [];
            if timeInfo == "inherent"
                obj.setTimeInformation("none");
            else
                obj.setTimeInformation(timeInfo); 
            end
        end
    end
    
    function numMembers = getNumMembers(obj)  
        if isempty(obj.pSourceHandler)
            numMembers = 0;
            return;
        end
        numMembers = getNumMembers(obj.pSourceHandler);
    end
    
    function nameList = getMemberNameList(obj)
        if isempty(obj.pSourceHandler)
            nameList = strings(0,0);
            return;
        end        
        nameList = getMemberNameList(obj.pSourceHandler);
    end
    
    function setMemberNameList(obj,mNames,mIdx)
        if isempty(obj.pSourceHandler)
            return;
        end
        setMemberNameList(obj.pSourceHandler,mNames,mIdx);
    end
    
    
    function setTimeInformation(obj,value)
        if isempty(obj.pSourceHandler)
            validatestring(value,["none","sampleRate","sampleTime","timeValues"],'Source','setTimeInformation');
            obj.pTimeInformation = value;
            return;
        end
        setTimeInformation(obj.pSourceHandler,value);        
    end
    
    function tInfo = getTimeInformation(obj)
        if isempty(obj.pSourceHandler)
            tInfo = obj.pTimeInformation;
            return;
        end        
        tInfo = getTimeInformation(obj.pSourceHandler);
        tInfo = validatestring(tInfo,["none","inherent","sampleRate","sampleTime","timeValues"],'BaseSourceHandler','getTimeInformation');
    end
    
    function fs = getSampleRate(obj)
        if isempty(obj.pSourceHandler)          
            fs = [];
            return;
        end        
        fs = getSampleRate(obj.pSourceHandler);
    end
    
    function ts = getSampleTime(obj)
        if isempty(obj.pSourceHandler)          
            ts = [];
            return;
        end                                
        ts = getSampleTime(obj.pSourceHandler);
    end
    
    function tv = getTimeValues(obj)
        if isempty(obj.pSourceHandler)          
            tv = [];
            return;
        end        
        tv = getTimeValues(obj.pSourceHandler);
    end
    
    function data = getSourceData(obj)
        if isempty(obj.pSourceHandler)
            data = [];
            return;
        end
        data = getSourceData(obj.pSourceHandler);
    end
    
    function data = getPrivateSourceData(obj)
        if isempty(obj.pSourceHandler)
            data = [];
            return;
        end
        data = getPrivateSourceData(obj.pSourceHandler);
    end    
    
    function [s,info] = getSignalEnsemble(obj,mIdxVect)
        if isempty(obj.pSourceHandler)
            s = [];
            info = struct;
            return
        end
        [s,info] = getSignalEnsemble(obj.pSourceHandler,mIdxVect);  
    end          
    
    function setSampleRate(obj,value)
        if isempty(obj.pSourceHandler)   
            obj.pTimeInformation = "sampleRate";
            return
        end        
        setSampleRate(obj.pSourceHandler,value);  
    end
    
    function setSampleTime(obj,value)
        if isempty(obj.pSourceHandler)          
            obj.pTimeInformation = "sampleTime";
            return
        end                
        setSampleTime(obj.pSourceHandler,value); 
    end
    
    function setTimeValues(obj,value)
        if isempty(obj.pSourceHandler)          
            obj.pTimeInformation = "timeValues";
            return
        end                
        setTimeValues(obj.pSourceHandler,value); 
    end         
    
    function hdlrClass = getSourceHandlerClass(obj)        
        hdlrClass = class(obj.pSourceHandler);
    end
    
    function flag = isCustomMemberNamesSupported(obj)
        %isCustomMemberNamesSupported determines if members
        %names are able to be changed. It is false by default.
        
        if ~isempty(obj.pSourceHandler)
            flag = obj.pSourceHandler.isCustomMemberNamesSupported;
        else
            flag = false;
        end
    end
    
    function flag = isSupportedInSignalAnalyzer(obj)
        %isSignalAnalyzerSupported determines if the object
        %is valid for use in Signal Analyzer. It is false by default.
       
        if ~isempty(obj.pSourceHandler)
            flag = obj.pSourceHandler.isSupportedInSignalAnalyzer;
        else
            flag = false;
        end
    end
    
    function flag = isSupportedInSignalLabeler(obj)
        %isSupportedInSignalLabeler determines if the object is valid for
        %use in Signal Labeler. It is false by default.
        
        if ~isempty(obj.pSourceHandler)
            flag = obj.pSourceHandler.isSupportedInSignalLabeler( obj.pSourceHandler);
        else
            flag = false;
        end
    end
    

end

%--------------------------------------------------------------------------
% Set/get methods
%--------------------------------------------------------------------------
methods        
    function set.pSourceHandler(obj,value)
        if ~isempty(value) && ~isa(value,'signalwavelet.internal.labeling.BaseSourceHandler')
            error(message('shared_signalwavelet:labeling:Source:InvalidSourceHandler'));            
        end
        obj.pSourceHandler = value;
    end    
end

%--------------------------------------------------------------------------
methods (Access = protected)
    function cp = copyElement(obj)
        % Deep copy of Source
        cp = copyElement@matlab.mixin.Copyable(obj);
        if ~isempty(obj.pSourceHandler)
            cp.pSourceHandler = copy(obj.pSourceHandler);
        end
    end    
end

%--------------------------------------------------------------------------
methods (Access = private)
    function selectSourceHandler(obj,data,tinfo)
        import signalwavelet.internal.labeling.*;
        import audio.labeler.internal.model.*;
        import signal.internal.datastore.labeledSignalSetSourceHandler.*;
        
        if nargin < 3
            tinfo = [];
        end
        
        if MatrixSourceHandler.isDataSupportedBySourceHandler(data)
            validateTinfoSupport(obj,MatrixSourceHandler.isSourceTimeInfoInherent(),~isempty(tinfo),obj.pTimeInformation);
            obj.pSourceHandler = MatrixSourceHandler(data,tinfo);
        
        elseif CellOfVectorsSourceHandler.isDataSupportedBySourceHandler(data)
            validateTinfoSupport(obj,CellOfVectorsSourceHandler.isSourceTimeInfoInherent(),~isempty(tinfo),obj.pTimeInformation);
            obj.pSourceHandler = CellOfVectorsSourceHandler(data,tinfo);
        
        elseif TimetableSourceHandler.isDataSupportedBySourceHandler(data)
            validateTinfoSupport(obj,TimetableSourceHandler.isSourceTimeInfoInherent(),~isempty(tinfo),obj.pTimeInformation);
            obj.pSourceHandler = TimetableSourceHandler(data,tinfo);
        
        elseif CellOfTimetablesSourceHandler.isDataSupportedBySourceHandler(data)
            validateTinfoSupport(obj,CellOfTimetablesSourceHandler.isSourceTimeInfoInherent(),~isempty(tinfo),obj.pTimeInformation);
            obj.pSourceHandler = CellOfTimetablesSourceHandler(data,tinfo);
        
        elseif isa(data,'audioDatastore') && AudioDatastoreHandler.isDataSupportedBySourceHandler(data)
            validateTinfoSupport(obj,AudioDatastoreHandler.isSourceTimeInfoInherent(),~isempty(tinfo),obj.pTimeInformation);
            obj.pSourceHandler = AudioDatastoreHandler(data,tinfo);

        elseif isa(data,'signalDatastore') && SignalDatastoreSourceHandler.isDataSupportedBySourceHandler(data)
            validateTinfoSupport(obj,SignalDatastoreSourceHandler.isSourceTimeInfoInherent(),~isempty(tinfo),obj.pTimeInformation);
            obj.pSourceHandler = SignalDatastoreSourceHandler(data,tinfo);
            
        else
            error(message('shared_signalwavelet:labeling:Source:InvalidInputData'));
        end
    end
    
    function validateTinfoSupport(obj,isSourceTimeInfoInherent,isTinfoSpecified,timeInformationSetting)
        if  isTinfoSpecified
            if isSourceTimeInfoInherent
                error(message('shared_signalwavelet:labeling:Source:InvalidTINFOInherent'));
            elseif ~any(strcmp(timeInformationSetting,["sampleRate","sampleTime","timeValues"]))
                if isempty(obj.pSourceHandler)
                    error(message('shared_signalwavelet:labeling:Source:InvalidTINFONone'));
                else
                    error(message('shared_signalwavelet:labeling:Source:TimeInfoNotApplies'));
                end
            end              
        end                
    end
end
end

