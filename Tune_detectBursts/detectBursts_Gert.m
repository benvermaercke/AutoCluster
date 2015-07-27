function [burstTimes, burstVector timeLine YmaxSmoothReshape threshold T S_orig] =  detectBursts(X,Y,header, varargin)
%function [burstTimes, burstVector] = detectBursts(X,Y,header,varargin)
%
% X = timestamps from CSC file 
% Y = Y data from CSC file
% header = header from CSC file (obtained by readCSCfile)
% 
% variable input
% DetectBursts(X,Y,header,thresholdFactor)
%   thresholdFactor: factor for multiplyin std for setting burst detection
%   threshold; default = 4
% DetectBursts(X,Y,header,[],plotIt)
%   plotIt: 0: don't plot data; 1: plot data; default = 0
% DetectBursts(X,Y,header,[],[],frequencyBand)
%   frequencyBand: frequency band where bursts are detected, default:
%   [6:10]  (6 -10 Hz)
%
% output:
% burstTimes : matrix with begin and end times of detected bursts
% burstVector: matrix of raw data: first line: timestamps; second line:
% smoothed sum of power in frequencyband; third line: 1 or 0 indicating if
% power in frequency band is above threshold, i.e. if there is a burst
% detected

%default values
thresholdFactor = 4;
plotIt = 0;
frequencyBand = 6:10;

if nargin < 3
    error('Not enough input arguments')
end
if nargin >=4
    if isempty(varargin{1})
        thresholdFactor = 4;
    else
        thresholdFactor=varargin{1};
    end
    
    if nargin >=5
        if isempty(varargin{2})
            plotIt = 0;
        else
            plotIt = varargin{2};
        end
        
        if nargin >= 6
            if isempty(varargin{3})
                frequencyBand = 6:10;
            else
                frequencyBand = varargin{3};
            end
        end
    end
end



%% Find envelope of maximum amplitude in  small time bins
samplingFreq = header.SamplingFrequency;
lengthWindow = 0.010; %ms

BinSize = round(lengthWindow*samplingFreq);

Y(length(Y)+1:ceil(length(Y)/BinSize)*BinSize)=0;
%Yreshape = reshape(Y,BinSize,ceil(length(Y)/BinSize));
Yreshape = reshape(abs(Y),BinSize,ceil(length(Y)/BinSize));
YmaxSmoothReshape =max(Yreshape,[],1);

X(length(X)+1:ceil(length(X)/BinSize)*BinSize)=0;
Xreshape = reshape(X,BinSize,ceil(length(X)/BinSize));
timeLine = Xreshape(1,:);

%% calculate frequency spectrum using spectrogram function
L = 2/lengthWindow;                     % Length of signal window

[S_orig bla T]=spectrogram(YmaxSmoothReshape,L,L-1,frequencyBand,1/lengthWindow);

% T=T-min(T);
% T=T/max(T);
% T=T*range(timeLine)+min(timeLine);

T=T-min(T);

[max(T)*samplingFreq range(timeLine)]
T=T*samplingFreq+min(timeLine);


S_orig=abs(sum(S_orig));
S_full=zeros(1,length(timeLine));
D1=round((length(timeLine)-length(S_orig))/2);
D2=round((length(timeLine)-length(S_orig))/2);
S_full(D1+1:end-D2+1)=abs(S_orig);
S=S_full;

Sabs = abs(S);
% Sabs = sum(Sabs,1);
%Ssmooth = spikeSmoothGauss(Sabs);
Ssmooth = gaussSmooth(Sabs,1);
%meanSum = mean(Ssmooth);
%sdSum = std(Ssmooth);

noiseSTD=median(abs(Ssmooth-median(Ssmooth)))/.6745;
threshold=noiseSTD*thresholdFactor;

aboveTH = Ssmooth>median(Ssmooth)+threshold;

if length(aboveTH)<length(timeLine)
    aboveTH(length(aboveTH+1):length(timeLine))=0;
end

aboveDiff = diff(aboveTH);
burstsBegin = timeLine(aboveDiff==1);
burstsEnd = timeLine(aboveDiff==-1);

if plotIt
    figure
    plot(timeLine(1:length(Ssmooth)),Ssmooth)
    hold on
    plot([timeLine(1),timeLine(end)],[median(Ssmooth) median(Ssmooth)],'m-',[timeLine(1),timeLine(end)],[median(Ssmooth)+threshold median(Ssmooth)+threshold],'m--')
    for i = 1:length(burstsBegin)
        plot([burstsBegin(i) burstsEnd(i)],[10 10],'r-','linewidth',5)
    end
    set(gca,'xlim',[timeLine(1),timeLine(end)])
end


%% output

burstTimes = [burstsBegin' burstsEnd'];
burstVector = [timeLine(1:length(Ssmooth)); Ssmooth; aboveTH(1:length(Ssmooth))];
