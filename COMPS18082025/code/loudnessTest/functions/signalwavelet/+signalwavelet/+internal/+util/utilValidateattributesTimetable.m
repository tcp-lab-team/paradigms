function [] = utilValidateattributesTimetable(xt, attributes) %#codegen
%UTILVALIDATEATTRIBUTESTIMETABLE  Utility function to validate attributes of timetable XT.
% This function is only for internal use.

%   Copyright 2019 The MathWorks, Inc.

Nattr = length(attributes);
for i = 1:Nattr
    localCheckAttribute(xt, attributes{i});
end

end

function [] = localCheckAttribute(xt, attr_name)
% Check timetable attribute given the attribute name
switch attr_name
    case 'sorted'
        if(~issorted(xt))
            error(message('shared_signalwavelet:emd:general:unsortedTimetable'));
        end
    case 'multichannel'
        % validate if the timetable satisfies the definition of
        % multi-channel timetalbe. It should be one of the following types:
        % (1) multiple variables with single column; (2) single variable with
        % multiple columns
        var_name = xt.Properties.VariableNames;
        Nvar = length(var_name);
        if(Nvar>1)
            if(~all(varfun(@isvector,xt,'OutputFormat','uniform')))
                error(message('shared_signalwavelet:emd:general:notMultichannelTimetable'));
            end
        end
    case 'singlechannel'
        % validate if the timetable is single-channel, i.e. single variable
        % with single column
        var_name = xt.Properties.VariableNames;
        Nvar = length(var_name);
        if Nvar==1
            if(~isvector(xt.(var_name{1})))
                error(message('shared_signalwavelet:emd:general:notSinglechannelTimetable'));
            end
        else
            error(message('shared_signalwavelet:emd:general:notSinglechannelTimetable'));
        end
    case 'regular'
        if(~isregular(xt))
            error(message('shared_signalwavelet:emd:general:irregularTimetable'));
        end
    otherwise
        error(message('shared_signalwavelet:emd:general:undefinedTimetableAttributes', attr_name));
end
end