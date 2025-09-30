function [newValue, scaleFactor, unitsStr] = getFrequencyEngUnits(value)
% Calculate engineering units based on an input frequency value.

%   Copyright 2018 The MathWorks, Inc.

if (value == 0)
    scaleFactor = 1;
    unitsStr = 'Hz';
elseif (value < 1 / (60 * 60 * 24 * 365))
    scaleFactor = 60 * 60 * 24 * 365;
    unitsStr = getString(message('shared_signalwavelet:convenienceplot:getFrequencyEngUnits:CyclesPerYear'));
elseif (value < 1 / (60 * 60 * 24))
    scaleFactor = 60 * 60 * 24;
    unitsStr = getString(message('shared_signalwavelet:convenienceplot:getFrequencyEngUnits:CyclesPerDay'));
elseif (value < 1 / (60 * 60))
    scaleFactor = 60 * 60;
    unitsStr = getString(message('shared_signalwavelet:convenienceplot:getFrequencyEngUnits:CyclesPerHour'));
elseif (value < 1 / (60))
    scaleFactor = 60;
    unitsStr = getString(message('shared_signalwavelet:convenienceplot:getFrequencyEngUnits:CyclesPerMinute'));
elseif (value < 1)
    scaleFactor = 1000;
    unitsStr = 'mHz';
elseif (value < 1000)
    scaleFactor = 1;
    unitsStr = 'Hz';
elseif (value < 1000 * 1000)
    scaleFactor = 1 / 1000;
    unitsStr = 'kHz';
elseif (value < (1000 * 1000 * 1000))
    scaleFactor = 1 / (1000 * 1000);
    unitsStr = 'MHz';
elseif (value < (1000 * 1000 * 1000 * 1000))
    scaleFactor = 1 / (1000 * 1000 * 1000);
    unitsStr = 'GHz';
else
    scaleFactor = 1 / (1000 * 1000 * 1000 * 1000);
    unitsStr = 'THz';
end

newValue = value*scaleFactor;