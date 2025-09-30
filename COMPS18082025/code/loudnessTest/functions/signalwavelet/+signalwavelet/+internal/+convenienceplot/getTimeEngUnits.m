function [newValue, scaleFactor, unitsStr] = getTimeEngUnits(value)
% Calculate engineering units based on an input time value.

%   Copyright 2018 The MathWorks, Inc.

if (value == 0)
    scaleFactor = 1;
    unitsStr = 's';
elseif (value < 0.000000001)
    scaleFactor = 1000 * 1000 * 1000 * 1000;
    unitsStr = 'ps';
elseif (value < 0.000001)
    scaleFactor = 1000 * 1000 * 1000;
    unitsStr = 'ns';
elseif (value < 0.001)
    scaleFactor = 1000 * 1000;
    unitsStr = [char(956) 's'];
elseif (value < 1)
    scaleFactor = 1000;
    unitsStr = 'ms';
elseif (value < 60)
    scaleFactor = 1;
    unitsStr = 's';
elseif (value < (60 * 60))
    scaleFactor = 1 / 60;
    unitsStr = getString(message('shared_signalwavelet:convenienceplot:getTimeEngUnits:Minutes'));
elseif (value < (60 * 60 * 24))
    scaleFactor = 1 / 3600;
    unitsStr = getString(message('shared_signalwavelet:convenienceplot:getTimeEngUnits:Hours'));
elseif (value < (60 * 60 * 24 * 365))
    scaleFactor = 1 / (3600 * 24);
    unitsStr = getString(message('shared_signalwavelet:convenienceplot:getTimeEngUnits:Days'));
else
    scaleFactor = 1 / (3600 * 24 * 365);
    unitsStr = getString(message('shared_signalwavelet:convenienceplot:getTimeEngUnits:Years'));
end

newValue = value*scaleFactor;