function varargout = set(obj,varargin)
%SET  Set object property values
%   SET(obj,'PropertyName',PropertyValue) sets the value of the
%   specified property for the object, obj.
%
%   SET(obj,'PropertyName1',Value1,'PropertyName2',Value2,...) sets
%   multiple property values with a single statement.
%
%   Given a structure S, whose field names are object property names,
%   SET(obj,S) sets the properties identified by each field name of S
%   with the values contained in the structure.
%
%   A = SET(obj, 'PropertyName') returns the possible values for the
%   specified property of the System object, obj. The returned array
%   is a cell array of possible value strings or an empty cell array
%   if the property does not have a finite set of possible string
%   values.
%
%   A = SET(obj) returns all property names and their possible values
%   for the object, obj. The return value is a structure whose
%   field names are the property names of obj, and whose values are
%   cell arrays of possible property value strings or empty cell
%   arrays.
%
%   For internal use only. 

%    Copyright 2018 The MathWorks, Inc.

% only support scalar (for now)
if numel(obj) ~= 1
    matlab.system.internal.error('shared_signalwavelet:util:set:nonScalarSet');  
end

switch(nargin)
  case 1
    % S = set(obj)
    nargoutchk(0,1);
    fns = fieldnames(obj);
    st = [];
    for ii = 1:length(fns)
        fn = fns{ii};
        fnprop = findprop(obj,fn);
        if ~isempty(fnprop) && strcmp(fnprop.SetAccess,'public')
          val = {set(obj,fn)}; 
          if isempty(val{1})
            st.(fn) = {};
          else
            st.(fn) = val; 
          end
        end
    end
    varargout = {st};
  case 2    
    if isstruct(varargin{1})
      nargoutchk(0,0);
      % set(obj, struct)
      st = varargin{1};
      stfn = fieldnames(st);
      for ii = 1:length(stfn)
        prop = stfn{ii};
        %validatestring is used to enable case-insensitive and incomplete
        %propery name support needed for backwards compatibility when
        %convering from UDD to MCOS
        try
          nprop = validatestring(prop,fieldnames(obj)); 
        catch
          nprop = prop;
        end
        obj.(nprop) = st.(prop);
      end
    else
      nargoutchk(0,1);
      try
        prop = validatestring(varargin{1},fieldnames(obj)); 
      catch
        prop = varargin{1}; 
      end
      mp = findprop(obj,prop);
      if isempty(mp)
           matlab.system.internal.error(...
          'shared_signalwavelet:util:set:invalidProperty',prop,class(obj));             
      elseif ~strcmp(mp.SetAccess, 'public')
        matlab.system.internal.error(...
          'shared_signalwavelet:util:set:propertyInvalidSetAccess', prop, class(obj));
      end
      varargout = {getAllowedStringValues(obj,prop)};
      if isempty(varargout)
        varargout = {{}};
      end
    end
  otherwise
    nargoutchk(0,0);
    % set(obj, <PV Pairs>)
    if mod(length(varargin),2)      
      error(message('shared_signalwavelet:util:set:invalidPvp'));
    end
    for ii = 1:2:length(varargin)
      % Set the property - if the property is protected or private, the set
      % will error out (as desired) as this function is outside the class.
      try
         prop = validatestring(varargin{ii},fieldnames(obj)); 
      catch
         prop = varargin{ii};
      end
      obj.(prop) =  varargin{ii+1};
    end
end
end