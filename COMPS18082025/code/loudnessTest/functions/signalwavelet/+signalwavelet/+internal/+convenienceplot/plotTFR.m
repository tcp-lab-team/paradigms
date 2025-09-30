function varargout = plotTFR(T,F,C,varargin)
%plotTFR Plot Time-Frequency Representation
%   H = PLOTTFR(T,F,C) generates a plot of the input time-frequency
%   representation and sets all relevant rotation and datatip behavior
%   where C specifies a time frequency distribution as a matrix and T and F
%   are vectors of time and frequency values at which the distribution was
%   calculated. T has length equal to the number of columns of C and F has
%   length equal to the number of rows of C. The output, H, is the handle
%   to the axes displayed.
%
%   PLOTTFR(T,F,C,T1,F1) plots of the input time-frequency representation
%   given by T, F, and C and overlays a line specified by T1 and F1. T1
%   specifies the time and F1 the frequency for the line to be plotted over
%   spectrum. This is currently used for instfreq convienence plot.
%
%   PLOTTFR(...,PLOTOPTS) optionally specifies additional properties for
%   the plot through the structure PLOTOPTS. Default values will be used
%   when not provided. Available fieldnames include:
%
%       isFsnormalized: Binary flag indicating whether the input frequency
%                       is to be plotted as normalized. Default is true,
%                       unless a duration or datetime vector T is input. 
%                       Then it is false.
%
%       freqlbl:        Frequency axis label. Default is 'Frequency (Hz)'
%                       where units are based on the scale of input data
%                       computed automatically by getFrequencyEngUnits
%
%       timelbl:        Time axis label. Default is 'Time (s)' where units
%                       are based on the scale of input data computed
%                       automatically by getTimeEngUnits
%
%       cblbl:          Colorbar label. Default is 'Power (dB)'
%
%       title:          Title of axes. Default is Empty.
%
%       cursortimelbl:  Datatip cursor time label. Default is 'Time: '
%
%       cursorfreqlbl:  Datatip cursor freq label. Default is 'Frequency: '
%
%       cursorclbl:     Datatip cursor C label. Default is 'Power: '
%
%       freqlocation:   Axis to plot frequency. This string can be either
%                       'xaxis' or 'yaxis'.  Setting this to 'yaxis'
%                       displays frequency on the y-axis and time on the
%                       x-axis.  Default is 'yaxis'
%
%       threshold:      Threshold. This value needs to be in the same scale
%                       as the input C. For example if C is input in dB,
%                       the threshold must also be specified in dB. Default
%                       value is -Inf.
%
%       legend:         String specifing the legend for the line
%                       plotted over the spectrum. Default is empty
%
%       imageOnlyFlag:  Flag to only use an image to plot TFR. If enabled,
%                       the rotation of the TFR will not be available.
%                       Default is false.

%   Copyright 2018 MathWorks, Inc. This function is for internal use only.
%   It may be removed.

narginchk(3,6);
nargoutchk(0,1);

if nargin > 4
    %plotTFMAP(X,Y,C,X1,Y1,plotOpts)
    T1 = varargin{1};
    F1 = varargin{2};
    T1 = T1(:);
    F1 = F1(:);
else
    T1 = [];
    F1 = [];
end

[plotOpts,T,T1] = parseAndValidateInputs(T,F,C,T1,varargin{:});

%Scale time and frequency in TFR
if isnumeric(T)
    T = T.*plotOpts.timeScale;
end
F = F.*plotOpts.freqScale;

%Scale time and frequency in line, if it exists
if plotOpts.lineFlag
    if isnumeric(T1)
        T1 = T1.*plotOpts.timeScale;
    end
    F1 = F1.*plotOpts.freqScale;
end

% Initial display as image
h = newplot;

% Restore Figure Toolbar buttons
if isnumeric(T)   
    if strcmp(plotOpts.freqlocation,'yaxis')
        hndl = imagesc(T, F, C);
        xlabel(plotOpts.timelbl);
        ylabel(plotOpts.freqlbl);
    else
        hndl = imagesc(F, T, C.');
        xlabel(plotOpts.freqlbl);
        ylabel(plotOpts.timelbl);
    end
    
    %If imageOnly and datetime is input, fix the time axis ticks to show
    %the datetime string. 
    if plotOpts.datetimeLabelFlag
        if strcmp(plotOpts.freqlocation,'yaxis')
            datetick('x','KeepLimits')
        else
            datetick('y','KeepLimits')
        end
    end
    
    hndl.Parent.YDir = 'normal';
    
    %Only set up image2surf listener if imageOnly flag is not enabled
    %Set Rotate btn behavior for the image plot
    [~, btns] = axtoolbar(hndl.Parent, 'default');
    hRotate = btns(5);
    if ~plotOpts.imageOnlyFlag
        hRotate.Visible = 'on';
        setupListeners(hndl,hRotate);
    else
        %If image only is enabled, set up listeners specific for it.
        hRotate.Visible = 'off';
        setupImageOnlyListeners(hndl,plotOpts);
    end
    
    %Add line to be plotted over TFR if input
    if plotOpts.lineFlag
        hold on
        if strcmp(plotOpts.freqlocation,'yaxis')
            ifhndl = plot(h,T1,F1,'r','LineWidth',1);
        else
            ifhndl = plot(h,F1,T1,'r','LineWidth',1);
        end
        hold off
    end
else
    if strcmp(plotOpts.freqlocation,'yaxis')
        hndl = surf(T, F, C,'EdgeColor','none');
        xlabel(plotOpts.timelbl);
        ylabel(plotOpts.freqlbl);
    else
        hndl = surf(F, T, C.','EdgeColor','none');
        xlabel(plotOpts.freqlbl);
        ylabel(plotOpts.timelbl);
    end
    axis xy
    axis tight
    view(0,90);
    if plotOpts.lineFlag
        hold on
        if strcmp(plotOpts.freqlocation,'yaxis')
            ifhndl = plot3(h,T1,F1,repmat(max(hndl.ZData(:))+1,size(T1,1),1),'r','LineWidth',1);
        else
            ifhndl = plot3(h,F1,T1,repmat(max(hndl.ZData(:))+1,size(F1,1),1),'r','LineWidth',1);
        end
        hold off
    end
end

%Set threshold if specified
if ~isempty(plotOpts.threshold) && isreal(plotOpts.threshold)
    Pmax = max(C(:));
    if plotOpts.threshold < Pmax
        set(ancestor(hndl,'axes'),'CLim',[plotOpts.threshold Pmax]);
    elseif ~isequal(plotOpts.threshold, Pmax)
        set(ancestor(hndl,'axes'),'CLim',[Pmax plotOpts.threshold]);
    end
end

%Set up datacursor
hdcm = datacursormode(ancestor(h,'figure'));
if strcmp(plotOpts.freqlocation,'yaxis')
    hdcm.UpdateFcn = {@cursorUpdateFunction,T,F,C,plotOpts,h};
else
    hdcm.UpdateFcn = {@cursorUpdateFunction,F,T,C.',plotOpts,h};
end

% Save Axes Data
h.UserData.XDataOriginal = hndl.XData;
h.UserData.YDataOriginal = hndl.YData;
h.UserData.CData = hndl.CData;
h.UserData.XLimOriginal = h.XLim;
h.UserData.YLimOriginal = h.YLim;

%Set up colorbar
hcbar = colorbar;
hcbar.Label.String = plotOpts.cblbl;

%Set title
title(plotOpts.title);

%Add legend for line if specified
if ~isempty(plotOpts.legend) && plotOpts.lineFlag
    legend(h,ifhndl,plotOpts.legend,'Location','best')
end

varargout{1} = h;


function output_txt = cursorUpdateFunction(~,event,x,y,c,plotOpts,h)
pos = event.Position;
idx = event.DataIndex;

if ~strcmp(event.Target.Type, 'line')
    %the overlaid line is not selected
    if strcmp(h.YScale,'log') || strcmp(h.XScale,'log') 
    x = h.Children.XData;
    y = h.Children.YData;
    c = h.Children.CData;
    end
    [yidx,xidx] = ind2sub(size(c),idx);
    xVal = x(xidx);
    yVal = y(yidx);
else
    xVal = pos(1);
    yVal = pos(2);
    %Get indices for power
    [~,xidx] = min(abs(x - pos(1)));
    [~,yidx] = min(abs(y - pos(2)));
end

    
%For non-converted TFR's
if ~plotOpts.datetimeLabelFlag
    if strcmp(plotOpts.freqlocation,'yaxis')
        %Get time in correct format
        time = xVal;
        freq = yVal;
        if isa(time,'float')
            time = num2str(time,4);
        else
            %Convert durations/datetimes to char
            time = char(time);
        end
        output_txt{1} = [plotOpts.cursortimelbl time];
        output_txt{2} = [plotOpts.cursorfreqlbl num2str(freq,4)];
    else
        freq = xVal;
        time = yVal;
        if isa(time,'float')
            time = num2str(time,4);
        else
            time = string(time);
        end
        output_txt{1} = [plotOpts.cursorfreqlbl num2str(freq,4)];
        output_txt{2} = [plotOpts.cursortimelbl num2str(time,4)];
    end
else
    %Special case for when TFR time is converted to a datenum
    %(imageOnly,datetime input)
    if strcmp(plotOpts.freqlocation,'yaxis')
        time = xVal;
        freq = yVal;
        output_txt{1} = [plotOpts.cursortimelbl datestr(time)];
        output_txt{2} = [plotOpts.cursorfreqlbl num2str(freq,4)];
    else
        freq = xVal;
        time = yVal;
        output_txt{1} = [plotOpts.cursorfreqlbl num2str(freq,4)];
        output_txt{2} = [plotOpts.cursortimelbl datestr(time)];
    end
end

%Set the C label for the datatip
output_txt{3} = [plotOpts.cursorclbl num2str(c(yidx,xidx),4)];

function setupListeners(hndl,hRotate)

hAxes = ancestor(hndl,'Axes');

%Setup rotation listener
if ~isempty(hRotate)
    %If rotation is allowed add a listener for it
    eRotate = addlistener(hRotate,'Value','PostSet',@(src,evt) image2surf(src,hndl));
else
    eRotate = [];
end

%Setup view listener
eView = addlistener(hAxes,'View','PostSet',@(src,evt) image2surf(src,hndl));

if ~isprop(hndl,'TransientUserDataListener')
    pi = addprop(hndl,'TransientUserDataListener');
    pi.Transient = true;
end

%Setup XScale\YScale listener
eXScale = addlistener(hAxes,'XScale','PreSet',@(src,evt) image2surf(src,hndl));
eYScale = addlistener(hAxes,'YScale','PreSet',@(src,evt) image2surf(src,hndl));

set(hndl,'TransientUserDataListener',{eView,eRotate,eXScale,eYScale});

function setupImageOnlyListeners(hndl,plotOpts)

hAxes = ancestor(hndl,'Axes');

%Set up listener for zoom in special case that imageOnly flag is enabled
%and datetime is input
if plotOpts.datetimeLabelFlag
    hZoom = zoom(hAxes);
    hPan = pan(hAxes.Parent);
    set(hZoom,'ActionPostCallback',@(src,evt) updateTimeAxisTicks(src,evt,plotOpts));
    set(hPan,'ActionPostCallback',@(src,evt) updateTimeAxisTicks(src,evt,plotOpts));
end

%Setup XScale\YScale listener
addlistener(hAxes,'XScale','PreSet',@(src,evt) shiftImageLowerBound(src,hndl));
addlistener(hAxes,'YScale','PreSet',@(src,evt) shiftImageLowerBound(src,hndl));
addlistener(hAxes,'XScale','PostSet',@(src,evt) restoreAxisData(src,hndl));
addlistener(hAxes,'YScale','PostSet',@(src,evt) restoreAxisData(src,hndl));


function restoreAxisData(src,h)

if ishghandle(h)
    if strcmp(src.Name,'XScale') && strcmp(h.Parent.XScale,'linear')
        h.XData = h.Parent.UserData.XDataOriginal;
        
        numOfPresentRows = size(h.CData,1);
        numOfinitialRows = size(h.Parent.UserData.CData,1);
        
        if numOfPresentRows ~= numOfinitialRows
            h.CData = h.Parent.UserData.CData((numOfinitialRows-numOfPresentRows+1):end,:);
        else
            h.CData = h.Parent.UserData.CData;
        end
        h.Parent.XLim = h.Parent.UserData.XLimOriginal;
    elseif strcmp(src.Name,'YScale') && strcmp(h.Parent.YScale,'linear')
        h.YData = h.Parent.UserData.YDataOriginal;
        
        numOfInitialCols = size(h.Parent.UserData.CData,2);
        numOfPresentCols = size(h.CData,2);
        
        if numOfInitialCols ~= numOfPresentCols
            h.CData = h.Parent.UserData.CData(:,(numOfInitialCols-numOfPresentCols+1):end);
        else
            h.CData = h.Parent.UserData.CData;
        end
        h.Parent.YLim = h.Parent.UserData.YLimOriginal;
    end
end


function shiftImageLowerBound(src,h)
%Callback to remove the negative first index from images before adjusting
%X/YScale 
if ishghandle(h)
    if strcmp(src.Name,'XScale')
        if any(h.XData <= 0)
            idx = (h.XData <= 0);
            % Remove all negative columns and fix the axis limits
            h.XData(idx) = [];
            h.CData(:,idx) =[];
            h.Parent.XLim(1) = h.XData(1);
        end
    elseif strcmp(src.Name,'YScale')
        if any(h.YData <= 0)
            idx = h.YData <= 0;
            % Remove all negative rows and fix the axis limits
            h.YData(idx) = [];
            h.CData(idx,:) = [];
            h.Parent.YLim(1) = h.YData(1);
        end
    end
end

function updateTimeAxisTicks(~,~,plotOpts)

%update the time axis tick labels whenever zoom/pan occurs
if strcmp(plotOpts.freqlocation,'yaxis')
    datetick('x','KeepLimits')
else
    datetick('y','KeepLimits');
end

function image2surf(src,h)

%Convert if rotation is enabled or view is not top down
if ishghandle(h) && (strcmp(src.Name,'Value') || strcmp(src.Name,'XScale') || strcmp(src.Name,'YScale') || ~isequal(h.Parent.View,[0 90]))
    
    %Get Data from old plot
    X = h.XData;
    Y = h.YData;
    C = h.CData;
        
    %Get previous labels and title
    hAxes = h.Parent;
    v = hAxes.View;
    CLim = hAxes.CLim;
    xLbl = hAxes.XLabel.String;
    yLbl = hAxes.YLabel.String;
    ttl = hAxes.Title.String;
    
    %Get line if exists
    hline = findobj(hAxes,'type','line');
    if ~isempty(hline)
        lineX = hline.XData;
        lineY = hline.YData;
    end
    
    %Get Colorbar object
    hcb = findobj(ancestor(hAxes,'figure'),'type','colorbar');
    for i=1:numel(hcb)
        if isequal(handle(hAxes),handle(hcb(i).Axes))
            cbLbl = hcb(i).Label.String;
            cbTickLbl = hcb(i).TickLabels;
        end
    end
    
    %Get legend if exists
    hleg = findobj(ancestor(hAxes,'figure'),'type','legend');
    if ~isempty(hleg)
        lLbl =  hleg.String;
    else
        lLbl = [];
    end
    
    %Display surf plot of TFMap
    surf(hAxes,X,Y,C,'EdgeColor','none','LineStyle','none');
    set(hAxes, ...
        'XLim', X([1 end]), ...
        'YLim', Y([1 end]), ...
        'CLim', CLim, ...
        'View', v);
    
    %Set title and labels
    title(hAxes,ttl);
    xlabel(hAxes,xLbl);
    ylabel(hAxes,yLbl);
    hAxes.TickDir = 'out';
    
    %Copy colorbar if exists
    if~isempty(hcb)
        hcb = colorbar('peer',hAxes);
        hcb.Label.String = cbLbl;
        hcb.TickLabels = cbTickLbl;
    end
    
    %Copy legend and line if exists
    if ~isempty(hline)
        hold on
        ifhndl = plot3(hAxes,lineX, lineY,repmat(max(C(:))+1,1,length(lineX)),'r','LineWidth',1);
        if ~isempty(lLbl)
            legend(hAxes,ifhndl,lLbl,'Location','best')
        end
        hold off
    end
end

function [plotOpts,T,T1] = parseAndValidateInputs(T,F,C,T1,varargin)

plotOpts = struct(...
    'isFsnormalized', true,...
    'cblbl',getString(message('shared_signalwavelet:convenienceplot:plotTFR:PowerDB')),...
    'title',[],...
    'timelbl',[],...
    'freqlbl',[],...
    'cursortimelbl',[getString(message('shared_signalwavelet:convenienceplot:plotTFR:TimeCursor')) ' '],...
    'cursorfreqlbl',[getString(message('shared_signalwavelet:convenienceplot:plotTFR:FreqCursor')) ' '],...
    'cursorclbl',[getString(message('shared_signalwavelet:convenienceplot:plotTFR:PowerCursor')) ' '],...
    'freqlocation','yaxis',...
    'threshold',-Inf,...
    'legend',[],...
    'lineFlag',false,...
    'imageOnlyFlag',false,...
    'datetimeLabelFlag',false,...
    'freqScale',1,...
    'timeScale',1);

if nargin == 5
    % plotTFMAP(X,Y,C,plotOpts)
    inputplotOpts = varargin{1};
elseif nargin == 6
    % plotTFMAP(X,Y,C,T1,F1)
    plotOpts.lineFlag = true;
    inputplotOpts = [];
elseif nargin == 7
    % plotTFMAP(X,Y,C,T1,F1,plotOpts)
    plotOpts.lineFlag = true;
    inputplotOpts = varargin{3};
else
    inputplotOpts = [];
end

%Copy any fields that match, else use the default values
if ~isempty(inputplotOpts)
    fn = fieldnames(inputplotOpts);
    validstr = fieldnames(plotOpts);
    for ii = 1:length(fn)
        %Matched field in correct case
        matchedfn = validatestring(fn{ii},validstr,'plotTFR','plotOpts');
        if  strcmpi(matchedfn,'freqlocation')
            str = validatestring(inputplotOpts.(fn{ii}),{'yaxis','xaxis'},'plotTFR','freqlocation');
            plotOpts.(matchedfn) = str;
        else
            plotOpts.(matchedfn) = inputplotOpts.(fn{ii});
        end
        
    end
end

%Override isFsnormalized if a duration/datetime time vector is input
if ~isnumeric(T)
    plotOpts.isFsnormalized = false;
end

if size(C,1)<2 || size(C,2)<2
    % Disable converting to a surface for 1-cell high/wide images
    plotOpts.imageOnlyFlag = true;
end
%Convert to numeric values if imageOnly
if plotOpts.imageOnlyFlag && isduration(T)
    T = seconds(T); % Get numeric val in seconds.
    if plotOpts.lineFlag 
        T1 = seconds(T1);
    end
elseif plotOpts.imageOnlyFlag && isdatetime(T)
    %Special case
    %Store T as a serial datenum. Will convert back to a datetime for
    %ticks/cursor. Workaround for imagesc not supporting datetime
    T = datenum(T); 
     if plotOpts.lineFlag 
        T1 = datenum(T1);
    end
    plotOpts.datetimeLabelFlag = true;
end

plotOpts = getLabels(T,F,plotOpts);

function plotOpts = getLabels(T,F,plotOpts)

if plotOpts.isFsnormalized
    %Set labels for normalized frequency and time
    
    if max(F) > 1
        plotOpts.freqScale = 1/pi; % Normalize the freq axis
        plotOpts.timeScale = 2*pi; % Convert time axis to samples
    end
    freqUnitsStr = signalwavelet.internal.convenienceplot.getNormalizedFreqUnits();
    
    if isempty(plotOpts.freqlbl)
        plotOpts.freqlbl = [getString(message('shared_signalwavelet:convenienceplot:plotTFR:NormalizedFreq')) ' (' freqUnitsStr ')'];
    end
    
    if isempty(plotOpts.timelbl)
        plotOpts.timelbl = getString(message('shared_signalwavelet:convenienceplot:plotTFR:Samples'));
    end
    
else
    [~,plotOpts.freqScale,uf] = signalwavelet.internal.convenienceplot.getFrequencyEngUnits(max(abs(F)));
    
    if isempty(plotOpts.freqlbl)
        plotOpts.freqlbl = [getString(message('shared_signalwavelet:convenienceplot:plotTFR:Frequency')) ' (' uf ')'];
    end
    
    if isnumeric(T)&& ~plotOpts.datetimeLabelFlag
        [~,plotOpts.timeScale,ut] = signalwavelet.internal.convenienceplot.getTimeEngUnits(max(abs(T)));
        if isempty(plotOpts.timelbl)
            plotOpts.timelbl = [getString(message('shared_signalwavelet:convenienceplot:plotTFR:Time')) ' (' ut ')'];
        end
    else
        if isempty(plotOpts.timelbl)
            plotOpts.timelbl = getString(message('shared_signalwavelet:convenienceplot:plotTFR:Time'));
        end
    end
end