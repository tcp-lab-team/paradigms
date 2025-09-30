classdef CellOfTimetablesSourceHandler < signalwavelet.internal.labeling.BaseTimetableSourceHandler
%CellOfTimetablesSourceHandler Source handler for signal ensembles stored
%as cell array of timetables.
% 
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

methods(Hidden)
    function obj = CellOfTimetablesSourceHandler(data,tinfo,mnames)
        % We are guaranteed that data is cell array of cell arays of
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
        % CellOfTimetablesSourceHandler supports a cell array containing
        % cell arrays of timetables. 

        % Check that we have a cell array of cell arrays
        flag =  iscell(data) && all(cellfun(@(x) iscell(x), data, 'UniformOutput', true));
        
        % Now check that each cell inside the cell contains numeric
        % timetables
        if flag
            for idx = 1:numel(data)
                
                C = data{idx};
                flag = all(cellfun(@istimetable, C, 'UniformOutput', true));                
                if flag 
                    for k = 1:numel(C)
                        flag = signalwavelet.internal.labeling.BaseTimetableSourceHandler.validateTimetable(C{k});
                        if ~flag
                            break;
                        end
                    end                    
                end    
                
                if ~flag
                    break;
                end                
            end
        end          
        
        if ~flag && errorFlag
            error(message('shared_signalwavelet:labeling:CellOfTimetablesSourceHandler:ExpectedSource'));
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
        
        for idx = 1:numel(data)
            if isrow(data{idx})
                data{idx} = data{idx}.';
            end
        end
        
    end
end
end % classdef


