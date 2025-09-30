classdef vmdParser < handle
%vmdParser is a function for parsing value-only inputs, flags, and
%   name-value pairs for the vmd function. This function is for
%   internal use only. It may be removed in the future.

%   Copyright 2019 The MathWorks, Inc.
%#codegen

    properties (Constant,Hidden)
        PenaltyFactorDefault = 1000
        LMUpdateRateDefault = 0.01
        AbsoluteToleranceDefault = 5e-6
        TolFactor = 1e3
    end

    properties (Access = public)   
       % Optimization hyper-parameters
       PenaltyFactor
       LMUpdateRate
       AbsoluteTolerance
       RelativeTolerance
       MaxIterations = 500
       
       % Initial variables
       InitialIMFs
       InitialLM
       CentralFrequencies
       InitializeMethod
       
       %Other parameters
       FFTLength
       NumIMFs = 5
       SignalLength       
       HalfSignalLength
       MirroredSignalLength
       DataType
       NumHalfFreqSamples
       Display = 0
    end
    
    methods
        %-----------------------------------------------------------------------------
        function this = vmdParser(signalLength,signalType,varargin)            
            if coder.target('MATLAB')
                this.parseInputsMatlab(signalLength,signalType,varargin{:});
            else
                this.parseInputsCodegen(signalLength,signalType,varargin{:});
            end
            this.validateInputParams();
        end
        % MATLAB ----------------------------------------------------------------------
        function parseInputsMatlab(this,signalLength,signalType,varargin)
            p = inputParser;
            addParameter(p,'PenaltyFactor',this.PenaltyFactorDefault);
            addParameter(p,'LMUpdateRate',this.LMUpdateRateDefault);
            addParameter(p,'AbsoluteTolerance',this.AbsoluteToleranceDefault);
            addParameter(p,'RelativeTolerance',[]);
            addParameter(p,'MaxIterations',this.MaxIterations);
            addParameter(p,'InitialIMFs',[]);
            addParameter(p,'InitialLM',[]);
            addParameter(p,'CentralFrequencies',[]);
            addParameter(p,'InitializeMethod',[]);
            addParameter(p,'NumIMFs',this.NumIMFs);
            addParameter(p,'Display',this.Display);
             
            % parse input
            if(mod(length(varargin),2)~=0)
                error(message('shared_signalwavelet:vmd:vmd:UnpairedNameValue'));
            else
                parse(p,varargin{:});
            end
            
            if strcmp(signalType,'single')
                isSingle = true;
            else
                isSingle = false;
            end
            % assign value
            fieldNames = fields(p.Results);
            for ii = 1:length(fields(p.Results))
                if (strcmp(fieldNames{ii},'InitialIMFs') || strncmpi(fieldNames{ii},'Cen',3)...
                        || strcmp(fieldNames{ii},'InitialLM')) &&...
                        isa(p.Results.(fieldNames{ii}),'single')
                    isSingle = true;
                end
                this.(fieldNames{ii}) = p.Results.(fieldNames{ii});
            end
            
            if isSingle
                this.DataType = 'single';
            else
                this.DataType = 'double';
            end
            
            this.SignalLength = signalLength;
            this.HalfSignalLength = fix(signalLength/2);
            this.MirroredSignalLength = signalLength*2 + (this.HalfSignalLength...
                - ceil(signalLength/2));
            this.FFTLength = this.MirroredSignalLength;               
            if ~mod(this.FFTLength,2)
                this.NumHalfFreqSamples = this.FFTLength/2+1;
            else
                this.NumHalfFreqSamples = (this.FFTLength+1)/2;
            end
            validateattributes(this.NumIMFs,...
                {'numeric'},{'nonnan','finite','scalar','positive','integer'},'vmd','NumIMFs');
            
            % assign default to empty fields
            if isempty(this.RelativeTolerance)
               this.RelativeTolerance = this.AbsoluteTolerance*this.TolFactor;
            end
            if isempty(this.InitialIMFs)
                this.InitialIMFs = zeros(signalLength,this.NumIMFs,this.DataType);
            elseif ~isa(this.InitialIMFs,this.DataType)
                this.InitialIMFs = cast(this.InitialIMFs,this.DataType);
            end
            if isempty(this.InitialLM)
                this.InitialLM = complex(zeros(this.NumHalfFreqSamples,1,this.DataType));
            elseif ~isa(this.InitialLM,this.DataType)
                this.InitialLM = cast(this.InitialLM,this.DataType);
            end
            
            this.PenaltyFactor = cast(this.PenaltyFactor,this.DataType);
            this.LMUpdateRate = cast(this.LMUpdateRate,this.DataType);
            
            if ~isempty(this.InitializeMethod)
                this.InitializeMethod = validatestring(this.InitializeMethod,...
                    {'random','grid','peaks'},'vmd','InitializeMethod');
            end
            
            this.CentralFrequencies = cast(this.CentralFrequencies,this.DataType);
            if isempty(this.CentralFrequencies)               
                if isempty(this.InitializeMethod)
                    % defaut method 'peaks' to initialize central freqencies
                    this.InitializeMethod = 'peaks';
                else
                    switch this.InitializeMethod
                        % if method is 'peaks', compute the central
                        % frequencies later
                        case 'grid'
                            % grid within [0,0.5]
                            this.CentralFrequencies = cast(((0.5/this.NumIMFs).*...
                                ((1:this.NumIMFs)-1)).',this.DataType); 
                        case 'random'
                            % random selected from U[0,0.5]
                            this.CentralFrequencies = 0.5*rand(this.NumIMFs,1,this.DataType); 
                    end           
                end
            else
                if ~isempty(this.InitializeMethod)
                    error(message('shared_signalwavelet:vmd:vmd:InitCentralFreqError'));
                end
            end                        
        end
        % Codegen parser-----------------------------------------------------------------
        function parseInputsCodegen(this,signalLength,signalType,varargin)      
           % Codegen parser
           % ParitalMatching true
            poptions = struct( ...
                'CaseSensitivity',false, ...
                'PartialMatching','none', ...
                'StructExpand',false, ...
                'IgnoreNulls',true);
            params = {'PenaltyFactor',...
                'LMUpdateRate',...
                'AbsoluteTolerance',...
                'RelativeTolerance',...
                'MaxIterations',...
                'InitialIMFs',...
                'InitialLM',...
                'CentralFrequencies',...
                'InitializeMethod',...
                'NumIMFs',...
                'Display'};           
            pstruct = coder.internal.parseParameterInputs(params,poptions,varargin{:});
            
            % assign values 
            this.SignalLength = signalLength;
            this.HalfSignalLength = fix(signalLength/2);
            this.MirroredSignalLength = signalLength*2 + (this.HalfSignalLength...
                - ceil(signalLength/2));
            this.FFTLength = this.MirroredSignalLength;  
            if ~mod(this.FFTLength,2)
                this.NumHalfFreqSamples = this.FFTLength/2+1;
            else
                this.NumHalfFreqSamples = (this.FFTLength+1)/2;
            end
            this.NumIMFs = coder.internal.getParameterValue(pstruct.NumIMFs,...
                this.NumIMFs,varargin{:});
            validateattributes(this.NumIMFs,...
                {'numeric'},{'nonnan','finite','scalar','positive','integer'},'vmd','NumIMFs');
            
            % decide data type
            InitIMFs = coder.internal.getParameterValue(pstruct.InitialIMFs,...
                [],varargin{:});
            InitLM = complex(coder.internal.getParameterValue(pstruct.InitialLM,...
                [],varargin{:}));
            CF = coder.internal.getParameterValue(pstruct.CentralFrequencies,...
                [],varargin{:});
            
            if isa(InitIMFs,'single') || isa(InitLM,'single') ||...
                    isa(CF,'single') || strcmp(signalType,'single')
                dataType = 'single';
            else
                dataType = 'double';
            end
            
            assert(coder.internal.isConst(dataType));
            
            if isempty(InitIMFs)
                this.InitialIMFs = zeros(signalLength,this.NumIMFs,dataType);
            elseif ~isa(InitIMFs,dataType)
                this.InitialIMFs = cast(InitIMFs,dataType);           
            else
                this.InitialIMFs = InitIMFs;
            end
            
            if isempty(InitLM)
                this.InitialLM = complex(zeros(this.NumHalfFreqSamples,1,dataType));
            elseif ~isa(InitLM,dataType)               
                this.InitialLM = cast(InitLM,dataType);
            else
                this.InitialLM = InitLM;
            end
            
            % assign default to empty fields
            this.PenaltyFactor = cast(coder.internal.getParameterValue(pstruct.PenaltyFactor,...
               this.PenaltyFactorDefault,varargin{:}),dataType);
            this.LMUpdateRate = cast(coder.internal.getParameterValue(pstruct.LMUpdateRate,...
                this.LMUpdateRateDefault,varargin{:}),dataType);
            this.AbsoluteTolerance = cast(coder.internal.getParameterValue(pstruct.AbsoluteTolerance,...
                this.AbsoluteToleranceDefault,varargin{:}),dataType);
            this.RelativeTolerance = cast(coder.internal.getParameterValue(pstruct.RelativeTolerance,...
                this.AbsoluteTolerance*this.TolFactor,varargin{:}),dataType);
            this.MaxIterations = coder.internal.getParameterValue(pstruct.MaxIterations,...
                this.MaxIterations,varargin{:});
            
            FM = coder.internal.getParameterValue(pstruct.InitializeMethod,...
                [],varargin{:});
            
            if ~isempty(FM)
                this.InitializeMethod = validatestring(FM,...
                    {'random','grid','peaks'},'vmd','InitializeMethod');
            else
                this.InitializeMethod = '';
            end
            
            
            this.CentralFrequencies = cast(CF,dataType);
            if isempty(CF)
                if isempty(FM) % defaut method 'peaks' to initialize central freqencies
                    this.InitializeMethod = 'peaks';
                else
                    switch this.InitializeMethod
                        case 'grid'
                            % grid within [0,0.5]
                            this.CentralFrequencies = cast(((0.5/this.NumIMFs).*...
                                ((1:this.NumIMFs)-1)).',dataType);
                        case 'random'
                            % random selected from U[0,0.5]
                            this.CentralFrequencies = cast(0.5*rand(this.NumIMFs,1),dataType); 
                    end           
                end
            else
                if ~isempty(FM)
                    coder.internal.error('shared_signalwavelet:vmd:vmd:InitCentralFreqError');
                end
            end
            
            this.DataType = dataType;
        end
        %-------------------------------------------------------------------------------
        function validateInputParams(this)
        % Validate input parameters
            validateattributes(this.PenaltyFactor,...
                {'single','double'},{'nonnan','finite','scalar','positive','real'},'vmd','PenaltyFactor'); %% nonnegative positive check
            validateattributes(this.LMUpdateRate,...
                {'single','double'},{'nonnan','finite','scalar','nonnegative','real'},'vmd','LMUpdateRate');
            validateattributes(this.AbsoluteTolerance,...
                {'single','double'},{'nonnan','finite','scalar','positive','real'},'vmd','AbsoluteTolerance');
            validateattributes(this.RelativeTolerance,...
                {'single','double'},{'nonnan','finite','scalar','positive','real'},'vmd','RelativeTolerance');
            validateattributes(this.MaxIterations,...
                {'numeric'},{'nonnan','finite','scalar','positive','integer'},'vmd','MaxIterations');            
            validateattributes(this.Display,{'numeric','logical'},{'scalar','nonnan','finite'},'vmd','Display');
            validateattributes(this.InitialIMFs,...
                {'single','double'},{'nonnan','finite','2d','real'}, 'vmd', 'InitialIMFs');
            if size(this.InitialIMFs,1)~=this.SignalLength
                coder.internal.error('shared_signalwavelet:vmd:vmd:InvalidNumInitialIMFRows',this.SignalLength);
            end
            if size(this.InitialIMFs,2)~=this.NumIMFs
                coder.internal.error('shared_signalwavelet:vmd:vmd:InvalidNumInitialIMFColumns',this.NumIMFs);
            end
            
            validateattributes(this.InitialLM,...
                {'single','double'},{'nonnan','finite','vector'}, 'vmd', 'InitialLM');
            
            if length(this.InitialLM)~=this.NumHalfFreqSamples
                coder.internal.error('shared_signalwavelet:vmd:vmd:InvalidInitMultiplierLength',this.NumHalfFreqSamples);
            end
            
            if ~isempty(this.CentralFrequencies)
                validateattributes(this.CentralFrequencies,...
                    {'single','double'},{'nonnan','finite','real','vector','nonnegative','<=',0.5}, 'vmd', 'CentralFrequencies');
                coder.internal.errorIf(length(this.CentralFrequencies)~=this.NumIMFs,...
                    'shared_signalwavelet:vmd:vmd:InvalidInitCentralFreqLength',this.NumIMFs);
            end
        end
    end

    methods(Static,Hidden=true)
       function props = matlabCodegenNontunableProperties(~)
          props = {'DataType'}; 
       end
    end


end
