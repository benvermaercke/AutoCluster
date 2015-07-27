clear all
clc

headerFile % define default data folder in this header file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% These variables should be optimized for every system this script is
%%% used from.
BlockSize=500E7; % change depending on memory (RAM) size

LoadSingleFile=0; % if 0 => do batch processing of all *.NCS files in the selected folder and its subfolders
maxCSCfileSizeMB=200; % in MB, exclude CSC files that are than this value. This value should be optimized to exclude unsplit CSC files from the analysis
shutDownWhenDone=0; % Optionally, shut computer down after (batch-) processing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Spike extraction parameters
runSpikeExtraction=1; % toggle on if we want to do/redo spike extraction
TH_max=0; % Threshold for initial detection of local maxima (this value is usually kept fairly low), if -1, use 0.25*minHeigth as threshold
min_heigth_factor=4; % default 4: amplitude (=abs(peak-valley)) of spikes should be x number of times above noise level
minHeight_fix=0; % minimal value of spike height: difference between peak and valley, if 0, this value is calculated from the data
retriggerSamples=5; % 1= minimum => no double peaks | 25=750µsec = cheetah value | 5 was default

nChannels=1; % increase in case of stereotrode/tetrode configurations (script is not optimized for it yet!!!)
nSamples=72;peakSample=24; % 23 before and 48 after

%%% Cluster parameters
clusterIt=1; % 0: MUA activity | 1: SUA activity
runClusterAnalysis=1; % toggle on if we want to do/redo clustering
maxNClusters=15; % maximum number of clusters allowed in KlustaKwik
adjustClusterNumbers=1; % Assign first clusternumbers to cluster with heighest average peak and lowest average valley => change the random assignments given by KlustaKwik. Clusters containing 1000 spikes or more will be placed first.

%%% PCA parameters
usePCAcomponents=1; % toggle on if we want to used the PCA feature space during clustering
PCA_dimensions=peakSample-10:peakSample+12; % [-7 +12] Optimize these values! Linked to the value of retriggerSamples, which sets the hard threshold on ISI. PCA_dimensions acts more as a soft threshold
nPCA_components=5;   % 5: Optimize these values! More components will lead to more sub-clusters that can be easily merged in SpikeSort 3D, but this also increases processing time...

%%% Post-processing parameters
showDensityMap=0; % show heatmap version of peak-valley plot to get an intuition of cluster location based on densities

showClusters=1; % show average+std of waveforms, plus some examples
nExampleWaveforms=250; % number of examples

saveClusters=0; % write *.NSE file containing cluster definition obtained from KlustaKwik
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch LoadSingleFile
    case 1 %%% Select single file
        cd(dataRootFolder)
        [fname pathName]=uigetfile('*.ncs');
        if fname==0
            cd(rootFolder)
            error('Filename is required...')
        else
            CSC_filenames(1).name=fullfile(pathName,fname);
        end
        cd(rootFolder)
    case 0 %%% Select all *.ncs files in subfolders
        mainFolder=uigetdir(dataRootFolder);
        switch 2
            case 1 % Search for files that are small enough to be splitted NCS files                
                CSC_filenames=rdir([mainFolder '\**\**.ncs'],sprintf('bytes<%d',maxCSCfileSizeMB*2^20));
            case 2 % Use folder that were marked 'Analyze' in step01
                load(fullfile(mainFolder,'Expdata.mat'),'folderProperties')
                %count=1;
                folderNr_vector=cat(1,folderProperties.Nr);
                selection_vector=folderNr_vector(cat(1,folderProperties.Analyze));
                CSC_filenames=struct;
                iCount=1;
                for iFolder=1:length(selection_vector)
                    folderName=fullfile(mainFolder,folderProperties(selection_vector(iFolder)).folderName);
                    content=scandir(folderName,'.ncs');
                    for iFile=1:numel(content)
                        CSC_filenames(iCount).name=fullfile(folderName,content(iFile).name);
                        iCount=iCount+1;
                    end
                end                
        end
end

%%% Load the data
nCSCFiles=length(CSC_filenames);
for CSCfile_index=1:nCSCFiles
    tic
    
    %%% Parse filenames
    CSCfilename=CSC_filenames(CSCfile_index).name;
    [subFolder coreName]=fileparts(CSCfilename);
    eventFilename=fullfile(subFolder,'Events.nev');
    
    %%% Prepare *.mat file to store all relevant data-structures
    matFilename=fullfile(subFolder,[coreName '_extractedData' num2str(nSamples) '.mat']);
    
    %%% Store current parameters
    parameters.TH_max=TH_max;
    parameters.minHeight_fix=minHeight_fix;
    parameters.retriggerSamples=retriggerSamples;
    parameters.nSamples=nSamples;
    parameters.PeakSample=peakSample;
    
    parameters.usePCAcomponents=usePCAcomponents;
    parameters.PCA_dimensions=PCA_dimensions;
    parameters.nPCA_components=nPCA_components;
    
    parameters.maxNClusters=maxNClusters;
    if exist(matFilename,'file')==0
        save(matFilename,'parameters')
    else
        save(matFilename,'parameters','-append')
    end
    
    %%% Extract events and experiment properties from file Events.nev
    [TTL_TimeStamps TTLS] = Nlx2MatEV( eventFilename, [1 0 1 0 0], 0, 1, []);
    experimentProperties=extract_experimentProperties(TTL_TimeStamps,TTLS);
    
    %%% Check whether we have to do spike-extraction or cluster analysis
    warning off
    if runSpikeExtraction==0
        try
            load(matFilename,'spikeMatrix')
            mean(spikeMatrix);
        catch % either file does not exist or no spikes have been extracted
            runSpikeExtraction=1;
            disp('No spike definitions detected, running spike extraction anyway...')
        end
    end
    
    if clusterIt==1&&runClusterAnalysis==0
        try
            load(matFilename,'ClusterAllocation')
            mean(ClusterAllocation);
        catch % either file does not exist or no clustering has been done
            runClusterAnalysis=1;
            disp('No cluster definitions detected, running cluster analysis anyway...')
        end
    end
    warning on
    
    %%% Run spike extraction
    if runSpikeExtraction==1
        %% Start blocked processing
        nFeatures=7;
        disp('Calculating Block Size...')
        
        % Use the event file to get timestamps needed to cut the CSC file into blocks...
        nTimePoints=TTL_TimeStamps(end)-TTL_TimeStamps(1);
        nBlocks=ceil(nTimePoints/BlockSize);
        toc
        disp('Done!')
        
        % Pre-allocate variables
        spikeMatrixAll=zeros(0,3+nFeatures);
        spikeDataAll=zeros(nSamples,1,0);
        noiseTH_vector=zeros(nBlocks,1);
        noiseSTD_vector=zeros(nBlocks,1);
        minHeight_vector=zeros(nBlocks,1);
        
        X=[];
        Y=[];
        t0=clock;
        burstList_all=[];
        
        disp(['Processing file: ' CSCfilename])
        for block_index=1:nBlocks
            progress(block_index,nBlocks,t0)
            
            %%% Get timestamps for beginning and end of block
            T1=TTL_TimeStamps(1)+(block_index-1)*BlockSize+1;
            T2=T1+BlockSize;
            if T2>TTL_TimeStamps(end)
                T2=TTL_TimeStamps(end);
            end
            
            %%% Read this block of data from CSC file
            [X_AS Ydata header NlxHeader]=readCSCfile(CSCfilename,[T1 T2],2);
            X=X_AS(:);
            Y=Ydata(:);
            clear X_AS Ydata
            
            %%% Extract parameters from header
            Fs=header.SamplingFrequency;
            yRange=header.InputRange;
            
            %%% Get burst episodes to allow later deletion of conditions            
            disp('Detecting bursts')
            [burstList burst_vector]=burstDetector(X,Y,Fs);
            burstList_all=[burstList_all ; burstList];
            clear burstList
            
            %%% Determine noise threshold and related minHeight
            if minHeight_fix==0
                %%% Wave_clus threshold: close to 6 times median of abs signal
                % Quiroga, 2004 (Neural Comp 16)
                noiseSTD=median(abs(Y))/.6745;
                minHeight=noiseSTD*min_heigth_factor;
            else
                minHeight=minHeight_fix;
                noiseSTD=0;
            end
            noiseSTD_vector(block_index)=noiseSTD;
            minHeight_vector(block_index)=minHeight;
            
            
            %%% Detect all local minima and maxima using a vector operation
            [Tmax Tmin M m]=localMaxMin(Y);
                                                            
            %%% Selection peaks to evaluate based on their amplitudes
            local_maxima_times=Tmax(diff([0;Tmax])>1); % remove double peaks
            N=length(local_maxima_times)-1;
            peak_data=zeros(N,8);
            
            waveForms=struct;
            count=1;
            for iMax=2:N-2
                T1=local_maxima_times(iMax-1);P1=Y(T1);
                T3=local_maxima_times(iMax);P3=Y(T3);
                T5=local_maxima_times(iMax+1);P5=Y(T5);
                T7=local_maxima_times(iMax+2);P7=Y(T7);
                
                [P2 T2_temp]=min(Y(T1:T3));T2=T1+T2_temp-1;
                [P4 T4_temp]=min(Y(T3:T5));T4=T3+T4_temp-1;
                [P6 T6_temp]=min(Y(T5:T7));T6=T5+T6_temp-1;
                
                time=(T1:T5)';
                values=Y(time);
                
                A1=(P2-P1);A2=(P3-P2);A3=(P4-P3);A4=(P5-P4);A5=(P6-P5);
                
                plotIt=0;
                type=0;
                if P3>TH_max&&A3<-minHeight % basic criteria for any spike
                    % Regular spike
                    type=3;
                    spikeTime=T3;
                    trigger_value=P3;
                    valley_value=P4;
                    amplitude=abs(A3);
                    width=T4-T3+1;
                else % not a valid spike
                    %disp('Discarded')
                end
                if type>0
                    peak_data(count,:)=[count iMax type spikeTime trigger_value valley_value amplitude width];                    
                    count=count+1;
                end
                
                if plotIt==1
                    %%
                    disp([P1 P2 P3 P4 P5])
                    disp([A1 A2 A3 A4])
                    subplot(211)
                    plot(time,values,'b.-')
                    hold on
                    plot([T1 T2 T3 T4 T5],[P1 P2 P3 P4 P5],'ro')
                    line([T1 T5],[0 0],'color','k')
                    line([T1 T1 ; T2 T2 ; T3 T3 ; T4 T4]',[P1 P1+A1; P2 P2+A2; P3 P3+A3; P4 P4+A4]','color','r')
                    line([T1 T2 ; T2 T3 ; T3 T4 ; T4 T5]',[P1+A1 P1+A1; P2+A2 P2+A2; P3+A3 P3+A3; P4+A4 P4+A4]','color','r')
                    hold off
                    axis([time([1 end])' -400 400])
                    box off
                    
                    subplot(212)
                    plot(Y(spikeTime-23:spikeTime+48));
                    title(type)
                    set(gca,'ylim',[-400 400])
                    box off
                    drawnow
                    KbWait;
                end
            end                        
            peak_data=peak_data(1:count-1,:);
            tabulate(peak_data(:,3))            
            
            %%% Implementation of retrigger time
            peak_data_minHeigth=peak_data;
            sel=[0;diff(peak_data_minHeigth(:,4))]>retriggerSamples;
            peak_data_selected=peak_data_minHeigth(sel,:);
            Tpeak=peak_data_selected(:,4);
            
            %%% Avoid out of range errors
            Tpeak=Tpeak(Tpeak>peakSample+1&Tpeak<length(X)-nSamples);
            nPeaks=length(Tpeak);
            
            % Pre-allocate variables, will be cropped later
            spikeMatrix=zeros(nPeaks,3+nFeatures);
            spikeData=zeros(nSamples,nChannels,nPeaks);
            t0=clock;
            
            %% Evaluate each spike
            for index=1:nPeaks
                %%% Display progess
                progress(index,nPeaks,t0,[block_index nBlocks size(spikeMatrixAll,1)/1000])
                
                %%% Collect information needed
                time_index=Tpeak(index);
                spikeTime=X(time_index);
                the_spike=Y(time_index-peakSample+1:time_index+nSamples-peakSample);
                
                %%% Run function to extract basic features from the spike
                spikeProperties=extract_spikeProperties(the_spike,peakSample);
                
                %%% Store properties for current spike
                spikeMatrix(index,1:3+nFeatures)=[index spikeTime time_index spikeProperties];
                
                %%% Store this spike in correct format
                spikeData(:,:,index)=the_spike;                
            end
            clear X Y
                                  
            %%% Append data to total matrices  
            spikeMatrixAll=cat(1,spikeMatrixAll,spikeMatrix); % append spike properties extracted from this block to spikeMatrixAll
            spikeDataAll=cat(3,spikeDataAll,spikeData); % append spike data extracted from this block to spikeDataAll
            clear spikeMatrix spikeData
        end        
        %%% Calculate PCA features
        PCA_Matrix=squeeze(spikeDataAll(PCA_dimensions,:,:))';
        [COEF scores]=princomp(PCA_Matrix);
        spikeMatrixAll=[spikeMatrixAll(:,1:end) scores(:,1:nPCA_components)];
        
        %%% Book-keeping
        spikeMatrix=spikeMatrixAll;
        spikeData=spikeDataAll;
        clear spikeMatrixAll spikeDataAll
        nSpikes=size(spikeMatrix,1);
        disp([num2str(nSpikes) ' Spikes Extracted!'])
        toc
        save(matFilename,'spikeMatrix','yRange','spikeData','nSpikes','noiseSTD_vector','minHeight_vector','header','burstList_all','experimentProperties','-append')
    else
        load(matFilename,'spikeMatrix','yRange','spikeData','nSpikes','noiseSTD_vector','minHeight_vector','header','burstList_all','experimentProperties')
        disp('Reloading previously extracted spikes...')
    end
    
    %% Run cluster analysis
    if clusterIt==1
        if runClusterAnalysis==1
            tic
            switch 1 % Select clustering algorithm
                case 1 % Klusta-Kwik
                    % Write the last part of spikeMatrix to a feature (*.fet_N) file and use
                    % this as input to klustaKwik => cluster numbers will be placed in the
                    % corresponding *.clu_N file
                    KK_folder='KlustaKwik';
                    baseName='temp';
                    clusterNr=1;
                    tempName=[baseName '.fet.' num2str(clusterNr)];
                    features=spikeMatrix(:,4:end);
                    nFeatures=size(features,2);
                    dlmwrite(fullfile(KK_folder,tempName),nFeatures,'delimiter','\t')
                    dlmwrite(fullfile(KK_folder,tempName),round(features),'delimiter','\t','-append')
                    
                    if usePCAcomponents==1
                        useFeatures=[char(zeros(1,nFeatures-nPCA_components)+48) char(zeros(1,nPCA_components)+49)];
                        disp(['Using first ' num2str(nPCA_components) ' PCA components'])
                        PCA_string=['_PCA' num2str(nPCA_components)];
                    else
                        useFeatures=['1100001' char(zeros(1,nPCA_components)+48)];
                        disp('Using peak-valley-energy')
                        PCA_string='_PeakValleyEnergy';
                    end
                    disp(['Now Clustering all ' num2str(nSpikes) ' spikes using KlustaKwik! Please be patient...'])
                    cd('KlustaKwik')
                    eval(['!KlustaKwik.exe "' fullfile(rootFolder,KK_folder,baseName) '" ' num2str(clusterNr) ' -ChangedThresh 0.500000 -DistThresh 0.000000 -FullStepEvery 10 -MaxClusters 4 -MaxIter 500 -MaxPossibleClusters ' num2str(maxNClusters) ' -MinClusters 2 -PenaltyMix 0.000000 -nStarts 1 -RandomSeed 1 -SplitEvery 50 -fSaveModel 0 -Log 0 -Screen 0 -UseFeatures '  useFeatures ''])
                    
                    %%% Read *.clu.1 file => extract cluster allocation for each spike
                    ClusterAllocation=dlmread([baseName '.clu.' num2str(clusterNr)]);
                    nClusters=ClusterAllocation(1);
                    ClusterAllocation=ClusterAllocation(2:end);
                    
                    cd(rootFolder)
                case 2 % Wave Clus
                    disp('Not implemented yet...')
                case 3 % k-means
            end
            disp('Clustering Finished!')                        
            
            if adjustClusterNumbers==1
                A=[ClusterAllocation spikeMatrix];
                centroids=pivotTable(A,1,'mean',5:6);
                nSpikesPerCluster=pivotTable(A,1,'length',1);
                [a order]=sortrows([nSpikesPerCluster>1000 centroids],[-1 3 -2]);
                
                ClusterAllocation_adjusted=zeros(size(ClusterAllocation));
                for index=1:nClusters
                    ClusterAllocation_adjusted(ClusterAllocation==order(index))=index;
                end
                ClusterAllocation=ClusterAllocation_adjusted;
                nSpikesPerCluster=nSpikesPerCluster(order);
            end
            
            ClusterAllocation_reset=ClusterAllocation;
            toc
            save(matFilename,'ClusterAllocation','ClusterAllocation_reset','nSpikes','nSpikesPerCluster','nClusters','PCA_string','-append')
        else
            disp('Loading existing cluster allocations...')
            load(matFilename,'ClusterAllocation','ClusterAllocation_reset','nSpikes','nSpikesPerCluster','nClusters','PCA_string')
        end
        clusterType='SUA';
    else
        ClusterAllocation=ones(nSpikes,1);
        nClusters=1;
        nSpikesPerCluster=nSpikes;
        ClusterAllocation_reset=ClusterAllocation;
        save(matFilename,'ClusterAllocation','ClusterAllocation_reset','nSpikes','nSpikesPerCluster','nClusters','-append')
        clusterType='MUA';
    end
    
    %%% Show density map to give an intuition about cluster locations
    if showDensityMap==1
        x=spikeMatrix(:,4);
        y=spikeMatrix(:,5);
        
        resolution=1;
        xBins=-50:resolution:yRange;
        yBins=-yRange:resolution:100;
        
        histmat=hist2(x,y,xBins,yBins);
        kernelSize=109;
        
        figure(1)
        
        smoothPoints=10/4;
        gammaVal=3/20;
        
        subplot(121)
        H(1)=plot(x,y,'w.','markerSize',1);
        set(gca,'color','k')
        axis equal
        axis([min(xBins) max(xBins) min(yBins) max(yBins)])
        box off
        title(nSpikes)
        im1=gca;
        
        subplot(122)
        kernel=bellCurve2(1,[kernelSize kernelSize]/2,[1 1]*smoothPoints,[kernelSize kernelSize],0);
        histmat_smooth=conv2(histmat,kernel,'same');
        histmat_smooth_gamma=abs(calc_gamma(histmat_smooth,gammaVal));
        imagesc(flipud(histmat_smooth_gamma))
        
        axis equal
        axis([0 range(xBins) 0 range(yBins)])
        set(gca,'xtick',0:50:range(xBins),'xtickLabel',get(im1,'xTickLabel'),'ytick',0:50:range(yBins),'ytickLabel',flipud(get(im1,'yTickLabel')))
        title(nSpikes)
        colormap jet
        drawnow
    end
    
    %%% Give a summary of waveforms per cluster
    if showClusters==1
        %%
        figure(1)
        clf
        yRange=header.InputRange;
        nCols=ceil(sqrt(nClusters));
        nRows=ceil(nClusters/nCols);
        
        
        for cluster_index=1:nClusters
            subplot(nRows,nCols,cluster_index)
            ClusterSpikes=ClusterAllocation==cluster_index;
            clusterSpikes=squeeze(spikeData(:,1,ClusterSpikes));
            
            N=size(clusterSpikes,2);
            
            sel=rand(N,1)<nExampleWaveforms/N;
            nExampleWaveforms_shown=min([N nExampleWaveforms]);
            spikeAVG=mean(clusterSpikes,2);
            spikeSTD=std(clusterSpikes,[],2);
            clusterSpikes=clusterSpikes(:,sel);
            Fs=header.SamplingFrequency;
            X_AS=((1:nSamples)-peakSample)/Fs*1000;
            xRange=X_AS([1 end]);
            plot(xRange,[0 0],'color',[.5 .5 .5])
            set(gca,'color','k')
            hold on
            plot([0 0],[-yRange yRange],'r')
            plot(X_AS,clusterSpikes,'color',cheetahColors(cluster_index,:))
            plot(X_AS,spikeAVG,'color',cheetahColors(cluster_index,:)/2,'lineWidth',3)
            errorbar(X_AS,spikeAVG,spikeSTD,'color',cheetahColors(cluster_index,:)/2,'lineWidth',1)
            
            plot(xRange,[0 0],'color',[.5 .5 .5])
            %plot([0 .5],[-yRange -yRange]+3,'color','r','lineWidth',5)
            %text(0,-yRange+15,'0.5ms','color','w')
            
            hold off
            axis([X_AS([1 end]) -yRange yRange])
            box off
            set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')},'yTick',-yRange:yRange/2:yRange,'yGrid','on','yColor',[1 1 1]*.5)
            set(gca,'xTick',round(X_AS(1)):.5:round(X_AS(end)))
            title([num2str(cluster_index) ': ' num2str(N) ' (' num2str(nExampleWaveforms_shown) ' examples)'])
            drawnow
        end
    end
    
    %% Save cluster definitions
    if saveClusters==1
        %%
        TimeStampsSE=spikeMatrix(:,2)';
        spikeData_SE=spikeData(peakSample-7:peakSample+24,:,:)/header.InputRange*header.ADMaxValue;
        
        if size(spikeData,1)~=size(spikeData_SE,1)
            disp(['Warning: spikes were truncated to comply with the *.nse file format (samples ' num2str(peakSample-7) ':' num2str(peakSample+24) ').'])
        end
        load('SE_header.mat','NlxHeaderSE') % Import SE header from another file in order to create a valid *.nse file
        
        % Modify headers
        %NlxHeaderSE{23}(end-1:end)=num2str(nSamples);
        %NlxHeaderSE{24}=[NlxHeaderSE{24}(1:end-1) num2str(peakSample)];
        
        %%% Actual save command
        saveName=fullfile(subFolder,[coreName '_extractedSpikes_clustered' PCA_string '_nClust' num2str(maxNClusters) '_' clusterType '.nse']);
        %Mat2NlxSE(saveName,0,1,1,nSpikes,[1 0 1 0 1 1],TimeStampsSE,ClusterAllocation',spikeData_SE,NlxHeaderSE)
        Mat2NlxSpike(saveName,0,1,1,[1 0 1 0 1 1],TimeStampsSE,ClusterAllocation',spikeData_SE,NlxHeaderSE)
        %%% Create pseudo tetrode data
        %%% Increase channel count artificially => similate tetrode
        %%% configuration
        
        %load('TT_header.mat','TT_Header') % Import SE header from another file in order to create a valid *.nse file
        %spikeData_SE(:,2,:)=round(spikeData_SE(:,1,:)*.9);
        %spikeData_SE(:,3,:)=round(spikeData_SE(:,1,:)*.8);
        %spikeData_SE(:,4,:)=round(spikeData_SE(:,1,:)*.4);
        
        %saveName='test.ntt';
        %Mat2NlxSpike(saveName,0,1,[],[1 0 1 0 1 1],TimeStampsSE,ClusterAllocation',spikeData_SE,TT_Header)
        
        disp('Clustered Spike Data File saved!!!')
        disp(saveName)
    end
end


if shutDownWhenDone==1
    shutdown;quit
end