classdef emdOptions %#codegen
    %EMDOPTIONS Create option class for the EMD command
    %
    %   OPT = emdOptions returns the default options for EMD.
    %
    %   OPT = emdOptions('Properties1',Value1,'Properties2',Value2,...) uses
    %   name/value pairs to override the default values for 'Properties1','Properties2',...
    % This function is only for internal use
    
    %   Copyright 2017 The MathWorks, Inc.
    
    properties (Constant)
        defaultInterpolation    =   'spline';
    end
    
    properties (Access = public)
        Interpolation
        SiftStopCriterion = struct('SiftRelativeTolerance', 0.2, 'SiftMaxIterations', 100);
        DecompStopCriterion = struct('MaxNumIMF', 10, 'MaxNumExtrema', 1, 'MaxEnergyRatio', 20);
        Display = 0;
    end
    
    methods
        %----------------------------------------------------------------------
        function this = emdOptions(varargin)
            if(~isempty(varargin))
                if coder.target('MATLAB')
                    this = this.parseInputsMatlab(varargin{:});
                else
                    this = this.parseInputsCodegen(varargin{:});
                end
            else
                % assign default values
                this.Interpolation = this.defaultInterpolation;
            end
        end
        %----------------------------------------------------------------------
        function [this] = parseInputsMatlab(this, varargin)
            p = inputParser;
            addParameter(p,'Interpolation',         this.defaultInterpolation);
            addParameter(p,'SiftRelativeTolerance', this.SiftStopCriterion.SiftRelativeTolerance);
            addParameter(p,'SiftMaxIterations',     this.SiftStopCriterion.SiftMaxIterations);
            addParameter(p,'MaxNumIMF',             this.DecompStopCriterion.MaxNumIMF);
            addParameter(p,'MaxNumExtrema',         this.DecompStopCriterion.MaxNumExtrema);
            addParameter(p,'MaxEnergyRatio',        this.DecompStopCriterion.MaxEnergyRatio);
            addParameter(p,'Display',               this.Display);
            
            % parse input
            if(mod(length(varargin),2)~=0)
                error(message('shared_signalwavelet:emd:general:unpairedNameValue'));
            else
                parse(p,varargin{:});
            end
            
            % assign value
            fieldNames = fields(p.Results);
            for i = 1:length(fields(p.Results))
                if(isfield(this.DecompStopCriterion, fieldNames{i}))
                    this.DecompStopCriterion.(fieldNames{i}) = p.Results.(fieldNames{i});
                elseif(isfield(this.SiftStopCriterion, fieldNames{i}))
                    this.SiftStopCriterion.(fieldNames{i}) = p.Results.(fieldNames{i});
                else
                    this.(fieldNames{i}) = p.Results.(fieldNames{i});
                end
            end
        end
        %----------------------------------------------------------------------
        function [this] = parseInputsCodegen(this, varargin)
            defaultSiftRelativeTolerance  =   this.SiftStopCriterion.SiftRelativeTolerance;
            defaultSiftMaxIterations      =   this.SiftStopCriterion.SiftMaxIterations;
            defaultMaxNumIMF              =   this.DecompStopCriterion.MaxNumIMF;
            defaultMaxNumExtrema          =   this.DecompStopCriterion.MaxNumExtrema;
            defaultMaxEnergyRatio         =   this.DecompStopCriterion.MaxEnergyRatio;
            defaultDisplay                =   this.Display;
            
            parms = struct( 'Interpolation',            uint32(0), ...
                'SiftRelativeTolerance',    uint32(0), ...
                'SiftMaxIterations',        uint32(0), ...
                'MaxNumIMF',                uint32(0), ...
                'MaxNumExtrema',            uint32(0),...
                'MaxEnergyRatio',           uint32(0),...
                'Display',                  uint32(0));
            
            pstruct = eml_parse_parameter_inputs(parms,[],varargin{:});
            this.Interpolation = eml_get_parameter_value(pstruct.Interpolation,...
                this.defaultInterpolation,varargin{:});
            this.SiftStopCriterion.SiftRelativeTolerance = eml_get_parameter_value( pstruct.SiftRelativeTolerance,...
                defaultSiftRelativeTolerance,varargin{:});
            this.SiftStopCriterion.SiftMaxIterations = eml_get_parameter_value( pstruct.SiftMaxIterations,...
                defaultSiftMaxIterations,varargin{:});
            this.DecompStopCriterion.MaxNumIMF = eml_get_parameter_value( pstruct.MaxNumIMF,...
                defaultMaxNumIMF,varargin{:});
            this.DecompStopCriterion.MaxNumExtrema = eml_get_parameter_value( pstruct.MaxNumExtrema,...
                defaultMaxNumExtrema,varargin{:});
            this.DecompStopCriterion.MaxEnergyRatio = eml_get_parameter_value( pstruct.MaxEnergyRatio,...
                defaultMaxEnergyRatio,varargin{:});
            this.Display = eml_get_parameter_value( pstruct.Display, defaultDisplay,varargin{:});
        end
    end
    %----------------------------------------------------------------------
    methods(Static)
        function props = matlabCodegenNontunableProperties(classname)
            props = {'Interpolation'};
        end
    end
end








