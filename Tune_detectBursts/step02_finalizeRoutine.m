clear all
clc

LoadSingleFile=1;
BlockSize=15E7; % change depending on memory (RAM) size

plotIt=0;

dataFolder='E:\LeuvenData\Developement\EyeTrackerDataAnalysis\Eye MovementFiles'; % User-defined!

switch 0
    case 0
        rootFolder=fileparts(mfilename('fullpath'));
        switch LoadSingleFile
            case 1 %%% Select single file
                cd(dataFolder)
                [fname pathName]=uigetfile('*.ncs');
                if fname==0
                    error('Filename is required...')
                else
                    CSC_filenames(1).name=fullfile(pathName,fname);
                end
                cd(rootFolder)
            case 0 %%% Select all *.ncs files in subfolders
                mainFolder=uigetdir(dataFolder);
                CSC_filenames=rdir([mainFolder '\**\**.ncs'],['bytes<' maxCSCfileSizeMB '*2^20']);
        end
        
        CSCfile_index=1;
        
        CSCfilename=CSC_filenames(CSCfile_index).name;
    case 1
        CSCfilename='E:\LeuvenData\Developement\EyeTrackerDataAnalysis\Eye MovementFiles\09. 3696789526 To 4062760014\CSC12.ncs';
end
[subFolder coreName]=fileparts(CSCfilename);
eventFilename=fullfile(subFolder,'Events.nev');


% Use the event file to get timestamps needed to cut the CSC file into blocks...
[TTL_TimeStamps TTLS] = Nlx2MatEV( eventFilename, [1 0 1 0 0], 0, 1, []);
nTimePoints=TTL_TimeStamps(end)-TTL_TimeStamps(1);
nBlocks=ceil(nTimePoints/BlockSize);

%%
X=[];
Y=[];
t0=clock;
for block_index=1%:nBlocks
    tic
    clc
    %%% Load datafile
    disp(['Processing file: ' CSCfilename])
    progress(block_index,nBlocks,t0)
    T1=TTL_TimeStamps(1)+(block_index-1)*BlockSize+1;
    T2=T1+BlockSize;
    if T2>TTL_TimeStamps(end)
        T2=TTL_TimeStamps(end);
    end
    [X_AS Ydata header NlxHeader]=readCSCfile(CSCfilename,[T1 T2],2);
    X=X_AS(:);
    Y=Ydata(:);
    clear X_AS Ydata
    
    %%% Read sampling rate
    Fs=header.SamplingFrequency;
    
    %%% down-sample signal
    binSize=100; % down-sample rate
    
    %S=abs(Y);
    nBins=ceil(length(Y)/binSize);
    F=zeros(1,nBins*binSize);
    F(1:length(Y))=Y;
    S=reshape(F,binSize,nBins);
    newSignal=mean(S);
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
    
    burstList=[(1:length(startPoints)) ; T(startPoints) ; T(endPoints) ; diff([T(startPoints) ; T(endPoints)])]';

    toc
    %% Show results
    plotIt=0;
    if plotIt==1
        plot(T,S)
        hold on
        plot(T,S_spec/25,'c','lineWidth',3)
        plot(T,burst_vector_spect*TH_spect/25,'g-','lineWidth',2)
        plot(T,burst_vector_spect_open*TH_spect/25-20,'m','lineWidth',3)
        hold off
    else
        %plot(X,spherify2(Y,1),'color',[1 1 1]*.5)
        
        plot(T,spherify2(newSignal,1),'b')
        hold on
        plot(T,spherify2(S,1)-.05,'r')
        plot(T,spherify2(S_spec,1),'g')
        N=size(burstList,1);
        for index=1:N
            plot(burstList(index,[2 3]),[0 0],'mo-','lineWidth',3)
        end
        hold off
    end
end

