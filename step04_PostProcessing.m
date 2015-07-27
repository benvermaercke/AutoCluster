clear all
clc

headerFile

plotIt=1;
saveIt=1;

%%% Make sure cluster2unit_mapping.txt and exp_properties exist in selected folder and are accurate!
cd(dataRootFolder)
[fname pathName]=uigetfile('*.mat');
if fname==0
    cd(rootFolder)
    error('Filename is required...')
else
    loadName=fullfile(pathName,fname);
end
cd(rootFolder)

[~,core]=fileparts(loadName);
parts=strsplit('_',core);
channelID=parts{1};

%%% Select mat file for all relevant data extracted during autocluster
load(loadName,'spikeMatrix','spikeData','ClusterAllocation','experimentProperties','yRange','noiseSTD_vector','burstList_all')
spikeTimes=spikeMatrix(:,2);

%%% Load experiment properties
%%% Format experimentNr - siteNr - areaNr
filename=fullfile(pathName,'exp_properties.txt');
if exist(filename,'file')
    exp_properties=dlmread(filename);
    expNr=exp_properties(1);
    siteNr=exp_properties(2);
    areaNr=exp_properties(3);
else
    error('No exp_properties.txt file found in root folder...')
end

%%% Load cluster mapping file
%%% Format: cluster number - corresponding unit number
%%% => make sure this maps the cluster number at the same location over experiment to the same unit (within experiments at one location)
filename=fullfile(pathName,[channelID '_cluster2unit_mapping.txt']);
if exist(filename,'file')
    cluster2unit_mapping=dlmread(filename);
    cluster2unit_mapping=sortrows(cluster2unit_mapping,1);
else
    error('No cluster2unit_mapping.txt file found in selected folder...')
end

if ~exist('yRange','var')
    yRange=250;
end
experimentProperties.yRange=yRange;

early_threshold=2500; % in µs; below which <5% off ISI are allowed

%% Check quality of each cluster
cluster_vector=unique(ClusterAllocation);
cluster_vector=cluster_vector(cluster_vector>0);
cluster_vector=intersect(cluster_vector,cluster2unit_mapping(:,1));
nClusters=length(cluster_vector);

noiseLevel=mean(noiseSTD_vector);
experimentProperties.noiseLevel=noiseLevel;
clusterProperties=struct();

for iCluster=1:nClusters
    
    %%% Select all rows for this cluster
    cluster_spikes=ClusterAllocation==cluster_vector(iCluster);
    if sum(cluster_spikes)>1
        clusterProperties(iCluster).cluster_number=cluster_vector(iCluster);
        clusterProperties(iCluster).nSpikes=sum(cluster_spikes);
        
        %%% Get average waveform with standard deviations
        cluster_spikeData=squeeze(spikeData(:,1,cluster_spikes));
        average_waveform=[(1:size(cluster_spikeData,1))' mean(cluster_spikeData,2) std(cluster_spikeData,[],2)];
        clusterProperties(iCluster).average_waveform=average_waveform;
        
        %%% Get cluster quality (based on function taken from the MClust
        %%% package)
        Q=Cluster_Quality(spikeMatrix(:,4:5),find(cluster_spikes));
        clusterProperties(iCluster).isolation_distance=Q.IsolationDist;
        clusterProperties(iCluster).L_ratio=Q.Lratio;
        
        %%% Get cluster SNR
        ampl=range(average_waveform(:,2));
        clusterProperties(iCluster).SNR_raw=ampl/noiseLevel; % raw
        clusterProperties(iCluster).SNR=20*log10(ampl/noiseLevel); % in dB
        
        %%% Get ISI histogram
        ISI_vector=diff(spikeTimes(cluster_spikes));
        bins=logspace(log10(1),log10(1E8),130);
        ISI_vector(ISI_vector>max(bins))=[];
        values=hist(ISI_vector,bins);
        
        clusterProperties(iCluster).ISI_vector=ISI_vector;
        clusterProperties(iCluster).ISI_histogram=[bins(:) values(:)];
        clusterProperties(iCluster).percentage_early_spikes=sum(ISI_vector<early_threshold)/length(ISI_vector)*100;
    end
end
nClusters=length(clusterProperties);
%%
%[[clusterProperties(:).nSpikes]'/100 [clusterProperties(:).SNR_raw]' ]

selected_cluster=1;

checkCorrelations=0;
if checkCorrelations==1;
    %% Check clusters for overlap => cross-correlation between spike-trains or waveform
    waveform_matrix=zeros(32,nClusters);
    for iCluster=1:nClusters
        waveform=clusterProperties(iCluster).average_waveform(:,2);
        waveform_matrix(:,iCluster)=waveform;
    end
    
    clf
    set(gcf,'color',[1 1 1]*.8);rotate3d off
    corr_matrix=corr(waveform_matrix);
    imagesc(corr_matrix)
    axis square
    
    C=round(corr_matrix*100);
    C(C<1)=1;
    color_matrix=hot(100);
    
    clf
    set(gcf,'color',[1 1 1]*.8);rotate3d off
    CC_matrix=zeros(nClusters);
    nClusters=5;
    for iCluster_1=1:nClusters
        for iCluster_2=1:nClusters
            if iCluster_1<iCluster_2
                X=waveform_matrix(:,iCluster_1);
                Y=waveform_matrix(:,iCluster_2);
                R=corr(X,Y);
                CC_matrix(iCluster_1,iCluster_2)=R;
                
                subplot(nClusters,nClusters,(iCluster_1-1)*nClusters+iCluster_2)
                plot(X,'k')
                hold on
                plot(Y,'g')
                hold off
                
                title(sci(R,2))
                xlabel(cluster_vector(iCluster_2))
                ylabel(cluster_vector(iCluster_1))
                
                
                %axis([1 32 -yRange yRange])
                axis square
                set(gca,'xTick',[],'yTick',[],'color',color_matrix(C(iCluster_1,iCluster_2),:))
                set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
            end
        end
    end
end


checkCC=0;
if plotIt==1&&checkCC==1
    %% cross correlation between spiketimes
    window_size=10; % ms
    nBins=50;
%     table=tabulate(ClusterAllocation);
%     spikeCounts=table(:,2);
%     CC_cluster_vector=unique(ClusterAllocation);
%     CC_cluster_vector=CC_cluster_vector(CC_cluster_vector>0);
%     CC_cluster_vector=CC_cluster_vector(between(spikeCounts,[median(spikeCounts) 1E5]));
    CC_cluster_vector=cluster_vector;
    %clf
    for iCluster=1:length(CC_cluster_vector)
        cluster_nr=CC_cluster_vector(iCluster);
        
        AVG=clusterProperties(iCluster).average_waveform;
        X_AS_avg=AVG(:,1);
        subplot(length(CC_cluster_vector),length(CC_cluster_vector),(iCluster-1)*length(CC_cluster_vector)+1)
        plot(X_AS_avg([1 end]),[0 0],'k-')
        hold on
        plot(X_AS_avg([1 end]),[experimentProperties.noiseLevel experimentProperties.noiseLevel],'k--')
        errorbar(X_AS_avg,AVG(:,2),AVG(:,3))
        axis([X_AS_avg([1 end])' -yRange yRange])
        axis square
        box off
        xlabel(cluster_nr)
        
        for iCluster2=1:length(CC_cluster_vector)
            cluster_nr2=CC_cluster_vector(iCluster2);
            if cluster_nr>cluster_nr2
                ST1=spikeMatrix(ClusterAllocation==cluster_nr,2);
                ST2=spikeMatrix(ClusterAllocation==cluster_nr2,2);
                
                CC_values=ST_cross_correlation(ST1,ST2,window_size,nBins);
                X_AS=linspace(-window_size/2,window_size/2,length(CC_values));
                
                subplot(length(CC_cluster_vector),length(CC_cluster_vector),(iCluster2-1)*length(CC_cluster_vector)+iCluster)
                bar(X_AS,CC_values,'barWidth',1)
                xlabel(cluster_nr)
                ylabel(cluster_nr2)
                %axis([X_AS([1 end]) 0 max(CC_values)*1.2])
                box off; axis square
                drawnow
            end
        end
    end
end

%% Check merging of clusters
plot_featureSpace=0;
if plot_featureSpace==1
    examine_clusters=[1 2];
    feature_space=2; % Peak-valley-energy / PCA
    
    switch feature_space
        case 1
            feature_matrix=spikeMatrix(:,[4 5 10]);
            ranges=max(abs(feature_matrix))/2;
        case 2 % use 3 first PCA components even if more were used during clustering, as these first components explain most of the variance in the data
            feature_matrix=spikeMatrix(:,[11 12 13]);
            ranges=max(abs(feature_matrix))/2;
    end
    
    clf
    hold on
    %%% Plot all clusters
    plot3(feature_matrix(:,1),feature_matrix(:,2),feature_matrix(:,3),'.','color',[1 1 1]*.7,'markerSize',1)
    
    %%% Plot selected clusters
    for cluster_index=cluster_vector(examine_clusters)
        sel=ClusterAllocation==cluster_index;
        plot3(feature_matrix(sel,1),feature_matrix(sel,2),feature_matrix(sel,3),'.','color',cheetahColors(cluster_index,:),'markerSize',1)
    end
    
    plot3([-ranges(1) ranges(1)],[0 0],[0 0],'w')
    plot3([0 0],[-ranges(2) ranges(2)],[0 0],'w')
    plot3([0 0],[0 0],[-ranges(3) ranges(3)],'w')
    hold off
    axis([-ranges(1) ranges(1) -ranges(2) ranges(2) -ranges(3) ranges(3)])
    set(gcf,'color',[0 0 0])
    set(gca,'visible','off','position',[-.2 -.2 1.4 1.4])
    
    
    axis vis3d
    rotate3d on
end


%% Detect burst-infected trials
switch experimentProperties.experiment_type
    case 8 % 15 positions
        window_size=[-.5 .5 1]*1E6; % time of start - offset - end
    case 10 % orientation tuning
        window_size=[-2 2 2.5]*1E6; % time of start - offset - end
    case 12
        window_size=[-1 4 5]*1E6; % time of start - offset - end
    case 13
        window_size=[-1 4 5]*1E6; % time of start - offset - end
    case 19
        window_size=[-2 2 2.5]*1E6; % time of start - offset - end
    case 20
        window_size=[-8 512*33.333/1000 20]*1E6; % time of start - offset - end
    case 21
        window_size=[-8 512*33.333/1000 20]*1E6; % time of start - offset - end
    case 22
        window_size=[-.2 .3 .5]*1E6; % time of start - offset - end
    case 25
        window_size=[-.3 60 60.6]*1E6; % time of start - offset - end
    case 26
        window_size=[-.5 .5 1]*1E6; % time of start - offset - end
end

trialMatrix=experimentProperties.trialMatrix;

burst_detection_matrix=zeros(size(trialMatrix,1),size(burstList_all,1));
for iTrial=1:size(trialMatrix,1)
    trial_period=[trialMatrix(iTrial,1)+window_size(1) trialMatrix(iTrial,1)+window_size(2)];
    trial_duration=diff(window_size(1:2));
    for iBurst=1:size(burstList_all,1)
        burst_period=burstList_all(iBurst,2:3);
        burst_duration=burstList_all(iBurst,4);
        
        %%% Check whether trial starts or ends between burst
        test(1,:)=between(trial_period,burst_period);
        
        %%% Check whether burst starts or ends within trial
        test(2,:)=between(burst_period,trial_period);
        
        %%% Check overlap
        if any(test(:))
            proportion_overlap=diff([max([trial_period(1) burst_period(1)]) min([trial_period(2) burst_period(2)])])/trial_duration;
            %proportion_infected=min([1 burst_duration/trial_duration]);
            burst_detection_matrix(iTrial,iBurst)=proportion_overlap;
        end
    end
end

infected_trials=sum(burst_detection_matrix,2)>0;
experimentProperties.trialMatrix_noBursts=trialMatrix(~infected_trials,:);
sprintf('%d infected trials out of %d',[sum(infected_trials) length(infected_trials)])


%% Get and save results => fill in all parameters correctly before advancing!!!
for selected_cluster=1:nClusters
    unitNr=cluster2unit_mapping(selected_cluster,2);
    saveFilename=sprintf('area%02d/e%02d_s%02d_u%02d.mat',[areaNr expNr siteNr unitNr]);
    saveFilename_str=saveFilename;saveFilename_str(saveFilename_str=='_')=' ';
    saveName=fullfile(saveFolder,saveFilename);
    
    
    sprintf('Cluster %02d matches unit %02d for this experiment',[clusterProperties(selected_cluster).cluster_number unitNr])
    %%% Manually set properties to save data from same cell to the same file
    if saveIt==1
        % set so cells match over experiments
        %cellNr=1;
    end
    
    %%% Construct raster_data and raster_labels
    binWidth=1000;
    
    trial_periods=[trialMatrix(:,1)+window_size(1) trialMatrix(:,1)+window_size(3)];
    nTrials=size(trialMatrix,1);
    
    sel=ClusterAllocation==cluster2unit_mapping(selected_cluster,1);
    if sum(sel)==0
        disp('No spikes for this cluster')
    else
        clusterProperties(selected_cluster).binWidth=binWidth;
        
        clusterProperties(selected_cluster).window_size=window_size/binWidth;
        
        %%% Add cluster feature space
        %sel=ClusterAllocation==cluster2unit_mapping(selected_cluster,1);
        clusterProperties(selected_cluster).features=spikeMatrix(sel,:);
        
        %%% Add raster data
        for iTrial=1:nTrials
            bins=trial_periods(iTrial,1)+binWidth:binWidth:trial_periods(iTrial,2);
            X_AS=(bins-bins(1)+binWidth+window_size(1))/binWidth;
            
            spikes=spikeTimes(sel);
            spikes=spikes(between(spikes,trial_periods(iTrial,[1 2])));
            
            values=hist(spikes,bins);
            clusterProperties(selected_cluster).X_AS=X_AS;
            clusterProperties(selected_cluster).raster_data(iTrial,:)=values;
        end
        
        %%% Add condition labels
        clusterProperties(selected_cluster).raster_labels.condition_labels=trialMatrix(:,2);
        %clusterProperties(selected_cluster).raster_labels.stimulus_ID=trialMatrix(:,2);
        %clusterProperties(selected_cluster).raster_labels.stimulus_position=trialMatrix(:,2);
        
        if plotIt==1            
            figure(unitNr)
            clf
            nRows=4; nCols=2;
            set(gcf,'color',[1 1 1]*.8);rotate3d off
            
            %%% Show average waveform + ste
            subplot(nRows,nCols,1)
            AVG=clusterProperties(selected_cluster).average_waveform;
            X_AS_avg=AVG(:,1);
            plot(X_AS([1 end]),[0 0],'k-')
            hold on
            plot(X_AS_avg([1 end]),[experimentProperties.noiseLevel experimentProperties.noiseLevel],'k--')
            errorbar(X_AS_avg,AVG(:,2),AVG(:,3))
            hold off
            axis([X_AS_avg([1 end])' -yRange yRange])
            box off
            title(sprintf('N spikes=%d; SNR=%5.2fdB',[clusterProperties(selected_cluster).nSpikes clusterProperties(selected_cluster).SNR ]))
            set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
            
            %%% Show ISI histogram
            subplot(nRows,nCols,2)
            bins=clusterProperties(selected_cluster).ISI_histogram(:,1);
            values=clusterProperties(selected_cluster).ISI_histogram(:,2);
            maxVal=max(values)*1.2;
            
            TH=find(bins>early_threshold,1,'first');
            
            %bar(1:length(values),values,'barWidth',1)
            plot(1:length(values),values)
            hold on
            %bar(1:TH,values(1:TH),'barWidth',1,'faceColor',[1 0 0]*.7)
            plot(1:TH,values(1:TH),'r-','lineWidth',5)
            plot([TH TH],[0 maxVal],'r-')
            hold off
            axis([1 length(values) 0 maxVal])
            box off
            %set(gca,'xTick',0:20:140,'xTickLabel',round(bins(1:20:140)))
            set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
            title(sprintf('Early spikes=%5.2f%%',clusterProperties(selected_cluster).percentage_early_spikes))
            
            %%% Show raster plots
            subplot(nRows,nCols,[3 6])
            [a order]=sort(trialMatrix(:,2));
            A=clusterProperties(selected_cluster).raster_data;
            
            % Check consistency within condition with van Rossum distance
            condition_vector=clusterProperties(selected_cluster).raster_labels.condition_labels;
            nConditions=length(unique(condition_vector));
            %consistency_index=zeros(nConditions,1);
            %for iCond=1:nConditions
            %    D=vanRossum(A(condition_vector==iCond,:),40/1000);
            %    consistency_index(iCond)=mean(squareform(D));
            %end
            %consistency_index_avg=mean(consistency_index);
            %consistency_index_ste=ste(consistency_index);
            %clusterProperties(selected_cluster).consistency_index_avg=consistency_index_avg;
            %clusterProperties(selected_cluster).consistency_index_ste=consistency_index_ste;
            
            switch 2
                case -1
                    imagesc(A(order,:))
                    colormap gray
                    set(gca,'clim',[0 1])
                    view(0,90)
                    axis([X_AS([1 end])-min(X_AS) 1 nTrials])
                case 2
                    A=A(order,:);
                    curCond=0;
                    for iTrial=1:nTrials
                        times=find(A(iTrial,:))+window_size(1)/1000;
                        plot(times,zeros(size(times))+iTrial+randn(size(times))*.1,'.','markerSize',1)
                        hold on
                        
                        if a(iTrial)>curCond
                            curCond=a(iTrial);
                            plot(X_AS([1 end]),[iTrial iTrial]-.5,'-','color',[1 1 1]*.5)
                        end
                    end
                    plot([0 0],[0 nTrials],'r-')
                    plot([clusterProperties(selected_cluster).window_size(2) clusterProperties(selected_cluster).window_size(2)],[0 nTrials],'r-')
                    hold off
                    axis([X_AS([1 end]) 1 nTrials])
                    box off
            end
            title(sprintf(['Cluster %02d, exp. %02d (unit %d) => ' saveFilename_str],[clusterProperties(selected_cluster).cluster_number experimentProperties.experiment_type unitNr]))
            %ylabel(sprintf('Consistency=%4.2f (+/-%4.2f)',[consistency_index_avg consistency_index_ste]))
            set(gca,'XtickLabel',[])
            set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
            
            %%% Show smoothed PSTH
            subplot(nRows,nCols,[7 8])
            X_AS=clusterProperties(selected_cluster).X_AS;
            PSTH=mean(clusterProperties(selected_cluster).raster_data)*binWidth;
            PSTH_smooth=gaussSmooth(PSTH,100);
            clusterProperties(selected_cluster).PSTH_smooth=PSTH_smooth;
            maxVal=max(abs(PSTH_smooth))*1.2;
            baseline_interval=[window_size(1)/2 0]/binWidth;
            baseline_response=mean(PSTH_smooth(between(X_AS,baseline_interval)));
            stimulus_interval=[0 window_size(2)]/binWidth;
            stimulus_response=mean(PSTH_smooth(between(X_AS,stimulus_interval)));
            
            response_net=stimulus_response-baseline_response;
            response_strength=(stimulus_response-baseline_response)/(stimulus_response+baseline_response);
            
            plot(X_AS,PSTH_smooth)
            hold on
            plot([0 0],[0 maxVal],'r-')
            plot(baseline_interval,[baseline_response baseline_response],'r')
            plot(stimulus_interval,[stimulus_response stimulus_response],'r')
            plot([clusterProperties(selected_cluster).window_size(2) clusterProperties(selected_cluster).window_size(2)],[0 maxVal],'r-')
            hold off
            axis([X_AS([1 end]) 0 maxVal])
            box off
            title(sprintf('N spikes=%d; net reponse=%3.2f (response index=%4.2f)',[clusterProperties(selected_cluster).nSpikes response_net response_strength]))
            set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
        end
        
        if saveIt==1
            %%% Save data to file => ready for Neural Decoding Toolbox or other
            %%% analysis pipelines
            savec(saveName);
                        
            %clusterProperties(selected_cluster).experimentProperties=experimentProperties;
            eval(['expName=''exp' num2str(experimentProperties.experiment_type) ''';'])
            eval([expName '.experimentProperties=experimentProperties;'])
            eval([expName '.clusterProperties=clusterProperties(selected_cluster);'])
            
            if exist(saveName,'file')
                save(saveName,expName,'-append')
            else
                save(saveName,expName)
            end
        end
    end
end






