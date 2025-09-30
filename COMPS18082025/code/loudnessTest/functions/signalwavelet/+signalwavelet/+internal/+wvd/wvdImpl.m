function [wvdMatReal,freqVec] = wvdImpl(dataOpts,opts)
% wvdImpl Calculate wvd or spwvd.
%   For internal use only.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

isWvd = (dataOpts.Type == "wvd"); % WVD or SPWVD?

x = dataOpts.Data;

freqVec = cast(linspace(0,1,opts.NumFrequencyPoints)','like',real(x([])));
N2 = length(x); % Signal length after length has increased.
N = length(x)/2; % The input signal length (+1 if odd input).

nTime = opts.NumTimePoints;
nhTime = floor(nTime/2); % ~1/2 the num. time points.
nFreq = opts.NumFrequencyPoints;
nhFreq = ceil(nFreq/2); % ~1/2 the num. freq. points.

if isWvd
    nhFreqWin = 0;
    nFreqWin = 0;
    g2 = zeros(length(opts.TimeWindow),1,'like',x);
    G1 = zeros(length(opts.FrequencyWindow),1,'like',x);
    maxLag = floor(N/2);
else
    funcName = "wvd";
    [G1,g2,maxLag,nFreqWin,nhFreqWin] = ...
        signalwavelet.internal.wvd.getSpwvdWindowParams(opts,funcName,dataOpts);
end

% Create a time-lag function kMat = K[m,n].
nVec = 0:N-1;
mVec = 0:maxLag;
M = size(mVec,2);

% create MxN matrix to allow the addition of 1xN vector with Mx1 vector.
nVecMN = repmat(nVec,M,1);
mVecMN = repmat(floor(mVec'/2),1,N);
posLagMat = mod(nVecMN + repmat(floor(mVec'/2)+~rem((mVec'+1),2),1,N),N2)+1;
negLagMat = mod(nVecMN - mVecMN,N2)+1;

if isWvd
    mnMat = x(posLagMat) .* conj(x(negLagMat));
else
    % mnMat = g2(mVec+1) .* x(posLagMat) .* conj(x(negLagMat)); Repmat is
    % used to enable variable size unbounded code generation
    mnMat = repmat(g2(mVec+1),1,size(nVec,2)) .*  x(posLagMat) .* conj(x(negLagMat));
    
    % If SPWVD, apply freq. smoothing window in the ambiguity function domain.
    % This is because interference terms map to the origin of the AF domain.
    
    % Take FT n->l to transform to the ambiguity domain.
    afMat = fft(mnMat,[],2); % FT in dim 2 b/c time is const. on each row.
    
    % Apply the Doppler window: G1[l] .* AF[m,l] (row-wise multiply).
    noDoppSupportIxs = 1+(nhFreqWin+1):1+(nhTime-nhFreqWin-1-(rem(nFreqWin,2)-1));
    posDoppIxs = 1:(nhFreqWin+1); % Support in positive Doppler axis.
    negDoppIx = nhFreqWin - ~mod(nFreqWin,2); % Support in negative Doppler axis.
    afWinMat = complex(zeros(length(mVec),nhTime,'like',x));
    afMatRow = size(afMat,1);
    
    afWinMat(:,posDoppIxs) = repmat(G1(posDoppIxs).',afMatRow,1) .* afMat(:,posDoppIxs);
    afWinMat(:,end-negDoppIx:end) = repmat(G1(end-negDoppIx:end).',afMatRow,1) .* afMat(:,end-negDoppIx:end);
    afWinMat(:,noDoppSupportIxs) = 0;
    
    % Take inverse FT l->n to return to the time-lag domain.
    mnMat = ifft(afWinMat,[],2);
end

% Due to the symmetry of the instantaneous autocorrelation function, the
% time-lag representation is also symmetric. Therefore we can retain just
% one half of mnMat without loss of information.
kMat = complex(zeros(2*nFreq,nhTime,'like',x));
kMat(mVec+1,:)  = mnMat(mVec+1,1:nhTime);

% Use time-lag function symmetry to obtain (-) lag vals from (+) vals.
mEvenIxs = 1:nhFreq-1;
mOddIxs = 0:nhFreq-1;

% Use time-lag function symmetry to obtain (-) lag vals from (+) vals.
kMat(2*nFreq-2*mEvenIxs+1,:) = conj(kMat(2*mEvenIxs+1,:));
kMat(2*nFreq-2*mOddIxs,:) = conj(kMat(2*mOddIxs+2,:));

% Transform to the time-frequency domain with FT m->k.
wvdMat = complex(zeros(nFreq,nTime,'like',x));

% Even lag values are conjugate symmetric. Here we calculate
% WVD[k,2n] = FT{K[2m,n]}.
nEven = 0:2:nTime-1;
mEven = 0:2:2*nFreq-1;
wvdMat(:,nEven+1) = fft(kMat(mEven+1,:));

% For odd lag values, K is not symmetric. Expressing the WVD matrix as
% W[k,2n+1] = Imag[DFT{Khat[m,2n+1]}]*csc(pi*k/N)
% reduces computational load.
mOdd = 1:2:2*nFreq-1;
kMatPrimeOdd = kMat(mOdd+1,:);
nFreqOdd = numel(mOdd);
nhFreqOdd = ceil(nFreqOdd/2);
timeIxs = 0:nhTime-1;
kMatHat = complex(zeros(nFreqOdd,nhTime,'like',x));
kMatHat(1,timeIxs+1) = imag(kMatPrimeOdd(1,timeIxs+1));
freqIxs1 = 1:nhFreqOdd;
freqIxs2 = (nhFreqOdd+1):nFreqOdd-1;

% Calculate (1/2j) * [ K[2m+1,n] - K*[2*Nf-2m-1,n] ] for nonzero m.
kMatHat(freqIxs1+1,timeIxs+1) = 1/(2*1j) * ( ...
    kMatPrimeOdd(freqIxs1+1,timeIxs+1) - ...
    conj(kMatPrimeOdd(nFreqOdd-freqIxs1+1,timeIxs+1)));

kMatHat(freqIxs2+1,timeIxs+1) = conj(kMatHat(nFreqOdd-freqIxs2+1,timeIxs+1));
tfMat = fft(kMatHat);
k = cast((1:nFreq-1),'like',real(x([])));
A = cos((pi/nFreq).*k); % A, B are used to form the cosecant.
B = sin((pi/nFreq).*k);
nOddVec  = 1:2:nTime-1;

% wvdMat(k+1,nOddVec+1) = ((A.^2+B.^2)./B)' .* tfMat(k+1,timeIxs+1); Repmat is
% used to enable variable size unbounded code generation
wvdMat(k+1,nOddVec+1) = repmat(((A.^2+B.^2)./B)',1,size(tfMat,2)) .* tfMat(k+1,timeIxs+1);

% At frequency sample k=0, sum the time-lag array along lag dimension.
wvdMat(1,nOddVec(1:nhTime)+1) = sum(kMat(mOdd+1,timeIxs+1),1);

% Symmetry ensures WVD reality. Force reality because very small imaginary
% values sometimes appear in the result.
wvdMatReal = real(wvdMat);

end

% LocalWords:  wvd spwvd af autocorrelation mn vals DFT Khat Vec Ixs
