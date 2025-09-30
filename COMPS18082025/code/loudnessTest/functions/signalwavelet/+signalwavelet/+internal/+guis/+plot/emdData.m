classdef emdData < wavepack.InputOutputData
    %EMDDATA  Wrap signal, IMFs and residue generated from empirical mode
    %decomposition to utilize control shared plotting infrastructure.
    % This class is only for internal use
    
    %  Copyright 2017 The MathWorks, Inc.
    
    properties (Access = private)
        IOSize
        InputTS
        OutputTS
    end
    
    properties (Access = public)
        TimeVec
    end
    
    methods
        function D = emdData(varargin)
            D = D@wavepack.InputOutputData(varargin{1});
            ni = nargin;
            if ni>0
                Data = varargin{1};
                D.IsTimeData = 1;
                D.Name = [];
                D.IOSize = [size(Data,2), 0];
            end
        end
        
        function [iosize] = getIOSize(this)
            iosize = this.IOSize;
        end
        
        function [] = commit(this)
        end
        
        function [data] = getData(this, ~)
            data = this.Data;
        end
        
        function [name] = getOutputName(this)
            name = this.Name;
        end
        
        function [name] = getInputName(this)
            name = {};
        end
        
        function [] = setSignalData(this)
        end
        
        function [TS] =getSignalData(this,name,~,~)
            ni = nargin;
            if ni<2
                name = [];
            end
            if isempty(name)
                name = this.Name;
            end
            
            ny = size(this.Data,2);
            for i = 1:ny
                thisTS = timeseries(this.Data(:,i));
                TS(i,1) = thisTS;
                TS(i).TimeInfo = this.TimeVec;
                TS(i).Name = this.Name{1};
            end
        end
    end
end