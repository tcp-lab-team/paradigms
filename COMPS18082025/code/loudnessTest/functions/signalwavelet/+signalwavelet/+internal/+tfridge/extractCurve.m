function freqOut = extractCurve(energy,penalty)
% extractCurve : Compute minimum negative-log energy curve
% The curve is computed in the forward and reverse directions

%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Validate the inputs : check the test files
M    = size(energy,1);   % Num of scales
N    = size(energy,2);   % Num of time points
if isa(energy,'single')
    lambda  = single(penalty);
else
    lambda = double(penalty);
end

% Compare all frequency bins to find minimum energy to go from
% from frequency bin j at time "t" to frequency bin k at
% time "t+1". Optionally Penalize moves by a multiple of the distance
% penalty*dist(j,k)

fVal    = zeros(M,N,class(energy));
idx     = zeros(M,N,class(energy));
freq    = zeros(N,1,class(energy));   % Column vector

% Set the first time point equal to the initial energies
fVal(1:M,1) = energy(1:M,1);

% Initial assignment of indices
idx(1:M,1) = (1:M)';
twoLambda   = 2 * lambda;

% find minimum energy+index via dynamic programming
colptr  = 1;

for i = 2:N
    for j = 1:M
        if isa(fVal,'single') 
            best_val = inf('single');
        else
            best_val = inf('double');
        end
        best_idx    = 1;
        penalty     = lambda * (j-1) * (j-1);
        pDelta      = lambda * (2*(j-1)) - lambda;
        
        for k = 1:M
            if best_val > (fVal(k,colptr) + penalty)
                best_val = fVal(k,colptr) + penalty;
                best_idx = k;
            end
            penalty = penalty - pDelta;
            pDelta  = pDelta - twoLambda;
        end        
        fVal(j,colptr+1)    = best_val + energy(j,i);       
        idx(j,colptr+1)     = best_idx;
    end
    colptr = colptr + 1;
end

% start traceback from minimum at last column
minVal      = fVal(1,N);
freq(N)     = 1;
freq(N-1)   = idx(1,N);
lastCol     = N;

for j = 2:M
    if fVal(j,lastCol) < minVal
        minVal     = fVal(j,lastCol);
        freq(N)    = j;
        freq(N-1)  = idx(j,lastCol);
    end
end

% Traceback from the last column and row
idxTraceBack    = freq(N-1);
lastCol         = N-1;
for i = (N-2):-1:1
    freq(i)    = idx(idxTraceBack,lastCol);
    idxTraceBack = freq(i);
    lastCol      = lastCol - 1;
end

freqOut = freq;

end

% LocalWords:  traceback Traceback
