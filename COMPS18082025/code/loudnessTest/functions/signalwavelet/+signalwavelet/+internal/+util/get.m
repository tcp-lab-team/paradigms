 function varargout = get(obj,prop)
    % GET    Get properties.
    %   V = GET(obj, 'PropertyName') returns the value of the specified
    %   property for the object, obj.  If 'PropertyName' is replaced by a
    %   cell array of strings containing property names, GET returns a cell
    %   array of values.
    %
    %   S = GET(obj) returns a structure in which each field name is the
    %   name of a property of obj and each field contains the value of
    %   that property.
    %
    %   For internal use only. 

    %    Copyright 2018 The MathWorks, Inc.
    
    % only support scalar (for now)
    if numel(obj) ~= 1
      matlab.system.internal.error('shared_signalwavelet:util:get:nonScalarGet');
    end
    
    if nargin > 1 && ~ischar(prop) && ~iscellstr(prop) && ~isstring(prop)
      % throw same error as built-in get
      matlab.system.internal.error('shared_signalwavelet:util:get:invalidArgGet');
    end
    if nargin == 1
      % S = get(obj)
      % this 'get' bypasses the hidden prop warning (by spec choice)
      names = fieldnames(obj);
      for ii = 1:length(names)
        out.(names{ii}) = obj.(names{ii});
      end
      if length(names) < 1
        out = struct([]);
      end
      varargout = {out};
    else
      if iscell(prop)
        % S = get(obj,<cell array of props>)
        len = length(prop);
        out = cell(len,1);
        for ii = 1:len
          %validatestring is used to enable case-insensitive and incomplete
          %propery name support
          try
            nprop = validatestring(prop{ii},fieldnames(obj));
          catch
            nprop = prop{ii};
          end
          out{ii} = obj.(nprop);
        end
        varargout = {out};
      elseif isstring(prop)
        % S = get(obj,<string vector of props>)
        len = length(prop);
        out = strings(len,1);
        for ii = 1:len
          %validatestring is used to enable case-insensitive and incomplete
          %propery name support
          try
            nprop = validatestring(prop(ii),fieldnames(obj));
          catch
            nprop = prop(ii);
          end
          out(ii) = obj.(nprop);
        end
        varargout = {out};        
      else
        % S = get(obj,prop)
          try
            nprop = validatestring(prop,fieldnames(obj));
          catch
            nprop = prop;
          end
          varargout = {obj.(nprop)};  
      end
    end
  end