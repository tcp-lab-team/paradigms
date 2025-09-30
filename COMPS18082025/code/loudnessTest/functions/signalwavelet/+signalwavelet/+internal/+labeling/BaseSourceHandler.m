classdef BaseSourceHandler < handle & matlab.mixin.Copyable
%BaseSourceHandler Source handler base class for signal labeling    
% 
%   For internal use only. 
    
%   Copyright 2018-2020 MathWorks, Inc.

%--------------------------------------------------------------------------
%Abstract, protected methods
%--------------------------------------------------------------------------
methods (Hidden, Abstract)    
    s = addMembers(obj,inputData,tinfo,mnames)
    removeMembers(obj,mIdxVect)
    numMembers = getNumMembers(obj)
    nameList = getMemberNameList(obj)   
    tInfo = getTimeInformation(obj)
    % getSourceData returns the public content of the data source, for
    % example, for an audioDataStore case it only returns a cell array of
    % names. This content is made available to the user through the Source
    % property of a labeledSignalSet.
    data = getSourceData(obj)
    % getPrivateSourceData returns the actual data source, for example, for an
    % audioDataStore case it returns the actual dataStore object. This
    % content is not available to the user through the labeledSignalSet.
    data = getPrivateSourceData(obj)
    % getSignalEnsemble get signal for scalar index mIdx
    [s,info] = getSignalEnsemble(obj,mIdx)
end
methods (Hidden, Static, Abstract)
    flag = isDataSupportedBySourceHandler(data,errorFlag)
end

%--------------------------------------------------------------------------
% Sub classes can override these methods
%--------------------------------------------------------------------------
methods (Hidden)
    function setTimeInformation(obj,value) %#ok<INUSD>
        % Sub classes can override this method if they support writeable
        % time information.
        error(message('shared_signalwavelet:labeling:BaseSourceHandler:TimeInformationNotApplies'));                
    end   
    
    function setSampleRate(~,~)
        error(message('shared_signalwavelet:labeling:BaseSourceHandler:SampleRateNotApplies'));          
    end
    
    function setSampleTime(~,~)
        error(message('shared_signalwavelet:labeling:BaseSourceHandler:SampleTimeNotApplies'));      
    end
    
    function setTimeValues(~,~)       
        error(message('shared_signalwavelet:labeling:BaseSourceHandler:TimeValuesNotApplies'));      
    end
         
    function fs = getSampleRate(~) %#ok<STOUT>
        error(message('shared_signalwavelet:labeling:BaseSourceHandler:SampleRateNotApplies'));
    end
    
    function ts = getSampleTime(~) %#ok<STOUT>
        error(message('shared_signalwavelet:labeling:BaseSourceHandler:SampleTimeNotApplies'));
    end
    
    function tv = getTimeValues(~) %#ok<STOUT>
        error(message('shared_signalwavelet:labeling:BaseSourceHandler:TimeValuesNotApplies'));    
    end
end

methods (Access = protected)
    function cp = copyElement(obj)
        % Override this method if the subclass source contains handle
        % classes that need to be copied as well
        
        % BaseSourceHandler only calls the superclass' copyElement method
        cp = copyElement@matlab.mixin.Copyable(obj);        
    end    
end

methods (Hidden, Static)
    function flag = isSourceTimeInfoInherent(~)
        % Sub classes can override this method if the time information of
        % the source is not inherent.
        flag = true;
    end
    
    function flag = isCustomMemberNamesSupported(~)
        flag = false;
    end
    
    function flag = isSupportedInSignalAnalyzer(~)
        flag = false;
    end
    
    function flag = isSupportedInSignalLabeler(~)
        flag = false;
    end
end
end

