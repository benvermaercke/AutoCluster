clear all
clc

LoadSingleFile=1;
BlockSize=15E7; % change depending on memory (RAM) size

dataFolder='E:\LeuvenData\Developement\EyeTrackerDataAnalysis\Eye MovementFiles'; % User-defined!

%
%
% rootFolder=fileparts(mfilename('fullpath'));
% switch LoadSingleFile
%     case 1 %%% Select single file
%         cd(dataFolder)
%         [fname pathName]=uigetfile('*.ncs');
%         if fname==0
%             error('Filename is required...')
%         else
%             CSC_filenames(1).name=fullfile(pathName,fname);
%         end
%         cd(rootFolder)
%     case 0 %%% Select all *.ncs files in subfolders
%         mainFolder=uigetdir(dataFolder);
%         CSC_filenames=rdir([mainFolder '\**\**.ncs'],['bytes<' maxCSCfileSizeMB '*2^20']);
% end

CSCfile_index=1;

% CSCfilename=CSC_filenames(CSCfile_index).name;
CSCfilename='E:\LeuvenData\Developement\EyeTrackerDataAnalysis\Eye MovementFiles\09. 3696789526 To 4062760014\CSC12.ncs';
[subFolder coreName]=fileparts(CSCfilename);
eventFilename=fullfile(subFolder,'Events.nev');


% Use the event file to get timestamps needed to cut the CSC file into blocks...
[TTL_TimeStamps TTLS] = Nlx2MatEV( eventFilename, [1 0 1 0 0], 0, 1, []);
nTimePoints=TTL_TimeStamps(end)-TTL_TimeStamps(1);
nBlocks=ceil(nTimePoints/BlockSize);

X=[];
Y=[];
t0=clock;
for block_index=2:nBlocks
    clc
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
    
    Fs=header.SamplingFrequency;
    %%
    %S=3.889E9;
    %Width=.005E9;
    %sel=between(X,[S S+Width]);
    sel=between(X,[3.84E9 3.95E9]);
    %sel=between(X,[3.85506E9 3.8552E9]); % period of one burst element
    T=X(sel);
    S=Y(sel);
    
    %%% down-sample signal
    S=abs(S-median(S));
    binSize=100;
    nBins=ceil(length(S)/binSize);
    F=zeros(1,nBins*binSize);
    F(1:length(S))=S;
    S=reshape(F,binSize,nBins);
    S=max(S);
    S=gaussSmooth(S,5);
    
    F=zeros(1,nBins*binSize);
    F(1:length(T))=T;
    T=reshape(F,binSize,nBins);
    T=T(1,:);

    %%% Get frequency response in distinct 6-10 band
    % expand signal to encompass filter size
    lengthWindow=.050;
    L=2/lengthWindow;
    frequencyBand=6:14;
    
    S_LP=filter1D(S,[5 14],Fs/binSize); 
%     S_LP=S; 
    
    S_extended=[zeros(1,L/2-1) S_LP-mean(S_LP) zeros(1,L/2)];
    S_spec=spectrogram(S_extended,L,L-1,frequencyBand,Fs/binSize);
    S_spec=abs(sum(S_spec));
    S_spec=gaussSmooth(S_spec,150);
    
    %%% Band Pass filter the signal
    LP=filter1D(S,frequencyBand([1 end]),Fs/binSize);  
    LP_min=minmaxfilt(LP,4500/binSize,'min','same');
    LP_max=minmaxfilt(LP,4500/binSize,'max','same');
    
    %%
    %%% detour: get FFT of obvious burst period
    sel=2400:3500;
    X=S(sel);    
    [Freqs FreqPower]=fftVector(X,Fs/binSize);
    plot(Freqs,FreqPower)
           
    hold on
    X=LP(sel);    
    [Freqs FreqPower]=fftVector(X,Fs/binSize);
    plot(Freqs,FreqPower-1,'g')
    hold off
   
    
    %%        
    %%% Get rms (variation in the signal)
    RMS=sqrt((LP_max-LP_min).^2);
    RMS=gaussSmooth(RMS,3000/binSize);    
    
    %%% Threshold to parse out burst episodes
    TH=45;    
    burst_vector=RMS>TH;
    TH_spect=800;
    burst_vector_spect=S_spec>TH_spect;
    
    %%% implement imopen => apply min-width to burst events, removes small
    %%% threshold crossing for periods smaller than a few cycles of the
    %%% burst oscillation
    minWidth=100;
    SE=[zeros(1,minWidth/2) ones(1,minWidth) zeros(1,minWidth/2)];    
    burst_vector_spect_erode=imopen(burst_vector_spect,SE);
    
    %%% 
    
    %%% Show results
    plot(T,S)
    hold on
    %plot(T,LP,'g','lineWidth',3)
    %plot(T,RMS,'r')
    %plot(T,burst_vector*TH,'m')
    
    plot(T,S_spec/25,'c','lineWidth',3)
    plot(T,burst_vector_spect*TH_spect/25,'g-','lineWidth',2)
    
    plot(T,burst_vector_spect_erode*TH_spect/25-20,'m','lineWidth',3)
    
    hold off
    
    %[burstTimes burst_vector timeLine YmaxSmoothReshape threshold T S]=detectBursts(X,Y,header,2,[],[6 10]);
    
    %     plot(X,Y,'b')
    %     hold on
    %     plot(timeLine,YmaxSmoothReshape-250,'c')
    %     plot(T,S/20,'g')
    %     plot(burst_vector(1,:),burst_vector(2,:)/20-50,'g')
    %     %plot(burst_vector(1,:),burst_vector(3,:)*200,'r')
    %     %plot(burst_vector(1,:),threshold/8,'m')
    %
    %     hold off
    
    %%
    plot(T,spherify2(RMS,2),'r')
    hold on
    plot(T,spherify2(S_spec,2),'c','lineWidth',1)
    hold off
    corrcoef(RMS,S_spec)
    
    
    %%
    burst_vector_s_spec=double(S_spec>1279);
    plot(T,burst_vector,'r')
    hold on
    plot(T,burst_vector_s_spec,'c','lineWidth',1)
    hold off
    corrcoef(burst_vector,burst_vector_s_spec)
    
    %%
    
end

