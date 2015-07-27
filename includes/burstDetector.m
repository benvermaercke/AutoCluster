function [burstList burst_vector]=burstDetector(X,Y,Fs)

%%% down-sample signal
binSize=100; % down-sample rate

%S=abs(Y);
nBins=ceil(length(Y)/binSize);
F=zeros(1,nBins*binSize);
F(1:length(Y))=Y;
S=reshape(F,binSize,nBins);
%newSignal=mean(S);
S=max(abs(S));
S=gaussSmooth(S,5);

% Reduce timeline to same length
F=zeros(1,nBins*binSize);
F(1:length(X))=X;
T=reshape(F,binSize,nBins);
T=T(1,:);

%%% Get frequency response in distinct 6-10 band
% expand signal to encompass filter size
lengthWindow=.025;
L=2/lengthWindow;
frequencyBand=5:16;

%%% band pass filter
S_LP=filter1D(S,frequencyBand([1 end]),Fs/binSize);

%%% get frequency response
S_extended=[zeros(1,L/2-1) S_LP-mean(S_LP) zeros(1,L/2)];
S_spec=spectrogram(S_extended,L,L-1,frequencyBand,Fs/binSize);
S_spec=abs(sum(S_spec));

%%% Smooth result
S_spec=gaussSmooth(S_spec,100);

%%% Threshold to parse out burst episodes
thresholdFactor=3.75;
noiseSTD=median(abs(S_spec-median(S_spec)))/.6745;
TH_spect=noiseSTD*thresholdFactor;
burst_vector_spect=S_spec>TH_spect;

% remove small gaps in between bursts
minWidth=76;
SE=[zeros(1,minWidth/2) ones(1,minWidth) zeros(1,minWidth/2)];
burst_vector_spect_erode=1-imopen(1-burst_vector_spect,1-SE);

%%% implement imopen => apply min-width to burst events, removes small
%%% threshold crossing for periods smaller than a few cycles of the
%%% burst oscillation
minWidth=126;
SE=[zeros(1,minWidth/2) ones(1,minWidth) zeros(1,minWidth/2)];
burst_vector_spect_open=imopen(burst_vector_spect_erode,SE);

%%% Create list of start and step timepoints of bursts
startPoints=find(diff(burst_vector_spect_open)==1);
endPoints=find(diff(burst_vector_spect_open)==-1);

if length(startPoints)==length(endPoints)+1
    endPoints=[endPoints length(burst_vector_spect_open)];
end

if length(startPoints)+1==length(endPoints)
    startPoints=[1 startPoints];
end

burst_vector=burst_vector_spect_open;
burstList=[(1:length(startPoints)) ; T(startPoints) ; T(endPoints) ; diff([T(startPoints) ; T(endPoints)])]';