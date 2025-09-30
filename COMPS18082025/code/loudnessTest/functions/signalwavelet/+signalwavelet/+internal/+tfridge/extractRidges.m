function iridge = extractRidges(tfm,penalty,numRidges,numBins)
% extractRidges : Extract the ridges from time frequency matrix.
% tfm - time frequency matrix
% penalty - penalty term (0 or greater)
% numRidges - number of ridges
% numBins - number of bins to remove from each ridge

%   Copyright 2016-2019 The MathWorks, Inc.

%#codegen
gamma   = 1e-8;
tfRow   = size(tfm,1);
tfCol   = size(tfm,2);
curve   = zeros(tfCol,numRidges,class(tfm));

% Obtain energy transform
eAbs = abs(tfm);
sumEabs = sum(eAbs,'all');
E  = -log(eAbs + gamma*sumEabs)+ log(sumEabs);

% If the number of ridges is 1,both tfridge and wsstridge check that
% numRidges is nonempty and positive. 
% numRidges = 1 is the default in both functions

if numRidges == 1
    % Call into compiled code for ridge extraction
    c = signalwavelet.internal.tfridge.callExtractCurve(E,penalty);
    % Make sure result is column vector
    curve(:,1) = c(:);
    
elseif numRidges > 1
    for ni = 1:numRidges
        ctmp = signalwavelet.internal.tfridge.callExtractCurve(E,penalty);
        curve(:,ni) = ctmp(:);
        negLogRealMin = -log(realmin(class(tfm)));
        
        if ni ~= numRidges
            % Remove this curve from the synchrosqueezed transform prior
            % to computing determing the next curve.
            for ii=0:numBins
                % Find lower bound for index. Do not go below 1.
                lb = max(1, curve(:,ni)-ii);
                % Find upper bound. Do not exceed M
                ub = min(tfRow, curve(:,ni)+ii);
                % Replace extracted ridge with -log(realmin) to ensure that the
                % extracted ridge has the minimum energy
                E((0:tfCol-1)'*tfRow+lb) = negLogRealMin;
                if ii>0
                    E((0:tfCol-1)'*tfRow+ub) = negLogRealMin;
                end
            end
        end
    end
end

iridge = curve;
end



% LocalWords:  tfm tfridge wsstridge synchrosqueezed determing CALLEXTRACTCURVE
