classdef imfPlot < handle
   %IMFPLOT  Construct plots to visualize IMFs. The plot allows show and
   %hide axes through a dialog.
   
   %  Copyright 2017-2019 The MathWorks, Inc.
   
   properties (Constant)
      % dialog related
      WIDTH = 250;
      HEIGHT = 270;
   end
   
   properties (Access = private)
      Data
      decompMethod
      
      % plot handles
      hAx
      hPlot
      hMenu
      hTitle
      hFigIMF
      hFigSelector
      hAxSelector
      
      % visbility state and widgets
      VisState
      Widget
   end
   
   methods
      function this = imfPlot(x, IMFs, residual, t, decompMethod)
         % define names for signal components
         if strcmp(decompMethod,'vmd')
            this.decompMethod = getString(message('shared_signalwavelet:convenienceplot:imfPlot:vmdPlotTitile'));
         elseif strcmp(decompMethod,'emd')
            this.decompMethod = getString(message('shared_signalwavelet:convenienceplot:imfPlot:emdPlotTitile'));
         end
         
         numIMF = size(IMFs,2);
         this.Data = signalwavelet.internal.guis.plot.emdData([x, IMFs, residual]);
         s1 = getString(message('shared_signalwavelet:convenienceplot:imfPlot:Signal'));
         s2 = getString(message('shared_signalwavelet:convenienceplot:imfPlot:Residual'));
         if ~isempty(IMFs)
            s3 = sprintf('IMF %d,',1:numIMF);
            this.Data.Name = strsplit(sprintf('%s,%s,%s',s1,s3,s2),',')';
         else
            this.Data.Name = {s1,s2};
         end
         
         IsTime = isdatetime(t) || isduration(t);
         
         % define time vector for emdData
         if IsTime
            dt = t-t(1);
            mdt = mean(diff(seconds(dt)));
            if mdt > 3600*24*356/2
               F = 'years';
            elseif mdt >= 3600*12
               F = 'days';
            elseif mdt >= 1800
               F = 'hours';
            elseif mdt > 180
               F = 'minutes';
            else
               F = 'seconds';
            end
            this.Data.TimeVec = this.convertDatetime(t,F);
         else
            this.Data.TimeVec = tsdata.timemetadata(t);
         end
         
         % only show three IMF components
         this.VisState = ones(length(this.Data.Name),1);
         if numIMF>3
            this.VisState(5:end-1) = 0;
         end
         
         % initialize iodataplot and dialog figure
         this.createDialogFig();
         this.createTsPlot();
         
         % customize right-click events
         this.createMenu();
         
         addlistener(this.hFigIMF,'ObjectBeingDestroyed',@(es,ed)this.cleanup(es,ed));
         
         % update output channel visbility
         this.updateVis();
      end
      
      function showDialogFig(this)
         % show dialog at mouse location
         corrGlobal = get(this.hFigIMF,'Position');
         corrLocal = get(this.hFigIMF, 'CurrentPoint');
         corner = corrLocal+corrGlobal(1:2);
         if ~isvalid(this.hFigSelector)
            this.createDialogFig();
         end
         this.hFigSelector.Position = [corner(1),corner(2)-this.HEIGHT,this.WIDTH,this.HEIGHT];
         this.hFigSelector.Visible = 'on';
         
         % synchronize output visibility
         this.Widget.cbOri.Value = this.VisState(1);
         numIMF = length(this.Data.Name(2:end-1));
         lboxVal = 1:numIMF;
         this.Widget.lbIMF.Value = lboxVal(logical(this.VisState(2:end-1)));
         this.Widget.cbRes.Value = this.VisState(end);
         
         % bring figure to front
         figure(this.hFigSelector);
      end
      
      function createDialogFig(this)
         % define dialog figure
         
         this.hFigSelector = figure('MenuBar','none','ToolBar','none','Color','white',...
            'Name',getString(message('shared_signalwavelet:convenienceplot:imfPlot:strIMFSelector')),...
            'Visible','off',...
            'NumberTitle','off',...
            'Units','pixels',...
            'Resize','on',...
            'HandleVisibility','off',...
            'Position',[0,0,this.WIDTH,this.HEIGHT]);
         
         h = this.hFigSelector;
         
         % button groups
         this.Widget.btnOK = uicontrol(h,'Style','pushbutton',...
            'Position',[60,20,50,20],...
            'String',getString(message('shared_signalwavelet:convenienceplot:imfPlot:strOK')),...
            'BackgroundColor','white',...
            'Tag', 'OK Button',...
            'Callback',@this.cbOk);
         this.Widget.btnCancel = uicontrol(h,'Style','pushbutton',...
            'Position',[180,20,50,20],...
            'String',getString(message('shared_signalwavelet:convenienceplot:imfPlot:strCancel')),...
            'BackgroundColor','white',...
            'Tag', 'Cancel Button',...
            'Callback',@this.cbCancel);
         align([this.Widget.btnOK, this.Widget.btnCancel],...
            'Fixed',15,'bottom');
         
         % label and list box
         this.Widget.lblIMF = uicontrol(h,'Style','text',...
            'String',getString(message('shared_signalwavelet:convenienceplot:imfPlot:strShowSelIMF')),...
            'Position',[20,175, this.WIDTH/2, 25],...
            'HorizontalAlignment','left',...
            'BackgroundColor','white',...
            'ForegroundColor','b',...
            'Tag', 'Select IMF Label');
         
         numIMF = length(this.Data.Name(2:end-1));
         lboxVal = 1:numIMF;
         this.Widget.lbIMF = uicontrol(h,'Style','listbox',...
            'Value',lboxVal(logical(this.VisState(2:end-1))),...
            'Position',[20,60,this.WIDTH-40,120],...
            'String',this.Data.Name(2:end-1),...
            'min',0,'max',numIMF,...
            'BackgroundColor','white',...
            'Tag','Select IMF Listbox');         
         align([this.Widget.lblIMF, this.Widget.lbIMF],'left','Distribute');
         
         this.Widget.cbOri = uicontrol(h,'Style','checkbox',...
            'String', getString(message('shared_signalwavelet:convenienceplot:imfPlot:strShowSignal')),...
            'Value',1,...
            'Position',[20,235,100,25],...
            'BackgroundColor','white',...
            'ForegroundColor','b',...
            'Tag','Select Signal Checkbox');
         
         this.Widget.cbRes = uicontrol(h,'Style','checkbox',...
            'String', getString(message('shared_signalwavelet:convenienceplot:imfPlot:strShowResidual')),...
            'Value',1,...
            'Position',[20,210,100,25],...
            'BackgroundColor','white',...
            'ForegroundColor','b',...
            'Tag','Select Residual Checkbox');
         align([this.Widget.cbOri, this.Widget.cbRes],'left','Distributed');
      end
      
      function createTsPlot(this)
         this.hFigIMF = figure;
         this.hAx = gca;
         
         % create iodataplot to manage multivariate time series
         OutputName = this.Data.Name;
         h = iodataplot(this.hAx,'time',[],OutputName,[],cstprefs.tbxprefs);
         h.AxesGrid.Geometry.VerticalGap = 10;
         h.Tag = 'IMFPlot';
         opt = getoptions(h);
         opt.Orientation = 'single-column';
         opt.TimeUnits = this.Data.TimeVec.Units;
         setoptions(h,opt);
         
         % Link each response to system source
         curData = iodatapack.IODataSource(this.Data,'Name','data');
         r = h.addwave(curData);
         DefinedCharacteristics = curData.getCharacteristics('time');
         r.setCharacteristics(DefinedCharacteristics);
         r.DataFcn = {'getData' curData r};
         
         % Styles and preferences
         r.setstyle([])
         
         % Draw now
         if strcmp(h.AxesGrid.NextPlot, 'replace')
            h.Visible = 'on';
         else
            draw(h)
         end
         this.hPlot = h;
      end
      
      function createMenu(this)
         %create right-click menus for imf plots.
         AxGrid = this.hPlot.AxesGrid;
         this.hMenu = struct(...
            'Signal',[],...
            'Characteristics',[]);
         
         % Create a Characteristics menu
         this.hMenu.Signal = uimenu('Parent', AxGrid.UIContextMenu,...
            'Label',getString(message('shared_signalwavelet:convenienceplot:imfPlot:IMFSel')),...
            'Tag', 'IMF Selector',...
            'Callback',@(es,ed)this.showDialogFig());
         
         this.hMenu.Characteristics = this.hPlot.addMenu('characteristics');
         
         % hPlot.registerCharMenu(hmenu.Signal);
         this.hPlot.registerCharMenu(this.hMenu.Characteristics);
         
         % Grid 
         AxGrid.addMenu('grid','Separator','on');
         
         % Add properties menu
         grp3 = handle(this.hPlot.addMenu('properties'));
         set(grp3(1),'Separator','on');
      end
   end
   
   methods (Access = private)
      function tn = convertDatetime(~, t,F)
         % convert duration/datetime array into emdData time format
         if isdatetime(t)
            sd = datestr(t(1));
            t = t-t(1);
         else
            sd = '';
         end
         tv = feval(F,t);
         tn = tsdata.timemetadata(tv);
         tn.Format = F;
         tn.Units = F;
         tn.StartDate = sd;
      end
      
      function cleanup(this,~,~)
         delete(this.hFigSelector);
         delete(this.hAxSelector);
      end
      
      function cbCancel(this,varargin)
         this.hFigSelector.Visible = 'off';
      end
      
      function cbOk(this,varargin)
         this.updateVis();
         this.hFigSelector.Visible = 'off';
         
      end
      
      function updateVis(this)
         % update output visibility
         this.VisState(1) = this.Widget.cbOri.Value;
         numIMF = length(this.Data.Name(2:end-1));
         this.VisState(2:(numIMF+1)) = 0;
         for i = 1:length(this.Widget.lbIMF.Value)
            this.VisState(1+this.Widget.lbIMF.Value(i)) = 1;
         end
         this.VisState(end) = this.Widget.cbRes.Value;
         for i = 1:length(this.VisState)
            if(this.VisState(i)==1)
               this.hPlot.OutputVisible{i} = 'on';
            else
               this.hPlot.OutputVisible{i} = 'off';
            end
         end
         
         % update title
         this.hTitle = title(this.hAx, {...
                this.decompMethod, ...
                getString(message('shared_signalwavelet:convenienceplot:imfPlot:imfPlotSubtitle',...
                sum(this.VisState(2:end-1)),...
                length(this.VisState(2:end-1))))},...
                'Tag','IMF Title');
         
         % when all VisState are 0, show only the signal
         if(all(this.VisState==0))
            this.VisState(1) = 1;
            this.hPlot.OutputVisible{1} = 'on';
         end
         
         f = this.hPlot.Waves(1).DataSrc.IOData.TimeVec.Format;
         if isempty(f)
            this.hPlot.AxesGrid.BackgroundAxes.XLabel.String = '';
         else
            opt = getoptions(this.hPlot);
            opt.TimeUnits = f;
            setoptions(this.hPlot,opt)
         end
         xlim([this.Data.TimeVec.Start this.Data.TimeVec.End])
      end
   end
   
   methods(Hidden)
      function h = qeGetHandle(this, hName)
         h = this.(hName);
      end
   end
end
