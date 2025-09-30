function [x, t, td] = utilParseTimetable(xt) %#codegen
%UTILPARSETIMETABLE  Utility function to convert timetable XT to duration
%vector T, data matrix X, original time vector TD
% This function is only for internal use.

%   Copyright 2017-2018 The MathWorks, Inc.

% extract time and data
t = xt.Properties.RowTimes;
td = t;
if(isa(t,'duration'))
    t = seconds(t);
else
    % convert datetime to duration
    t = t-t(1);
    t = seconds(t);
end
if ~all(varfun(@isnumeric,xt,'OutputFormat','uniform')) 
     error(message('shared_signalwavelet:emd:general:notNumericDataTimetable'));
end
x = xt{:,:};
end