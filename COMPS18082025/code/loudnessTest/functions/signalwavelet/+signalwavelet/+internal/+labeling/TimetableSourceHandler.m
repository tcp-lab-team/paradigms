classdef TimetableSourceHandler < signalwavelet.internal.labeling.BaseTimetableSourceHandler
%TimetableSourceHandler Source handler for timetable signal ensembles    
% 
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

methods(Hidden)
    function obj = TimetableSourceHandler(data,tinfo,mnames)
        % We are guaranteed that data is a timetable or a cell array of
        % timetables. 
        if nargin == 1
            tinfo = [];
            mnames = [];
        elseif nargin == 2
            mnames = [];
        end
        
        obj.pNumMembers = 0;
        obj.pMemberNameList = strings(0,0);
        obj.pData = {};        
        addMembers(obj,data,tinfo,mnames);                                     
    end
end

%--------------------------------------------------------------------------
methods (Hidden, Static)
    function flag = isDataSupportedBySourceHandler(data,errorFlag)
        if nargin < 2
            errorFlag = false;
        end
        % TimetableSourceHandler supports a timetable input or a cell array of
        % timetables input. Timetables must have numeric variables and time
        % values must be durations, increasing, and unique. 
        flag = istimetable(data) || (iscell(data) && all(cellfun(@istimetable, data)));
        
        if flag
            if istimetable(data)
                data = {data};
            end            
            for idx = 1:numel(data)             
                flag = signalwavelet.internal.labeling.BaseTimetableSourceHandler.validateTimetable(data{idx});
                if ~flag
                    break;
                end
            end                        
        end
        
        if ~flag && errorFlag
            error(message('shared_signalwavelet:labeling:TimetableSourceHandler:ExpectedSource'));
        end
    end       
end

methods (Access = protected)
    function [numMembers,data] = parseInputSource(~,data)
        
        if istimetable(data)
            numMembers = 1;
            data = {data};
        else
            numMembers = numel(data);
        end
        
        if isrow(data)
            data = data.';
        end
    end
end
end % classdef


