function CC_split_clusters(varargin)
H=varargin{1};
handles=guidata(H);

rootFolder=handles.rootFolder;
spikeData=handles.spikeData;
spikeMatrix=handles.spikeMatrix;
ClusterAllocation=handles.ClusterAllocation;
selected_cluster=handles.selected_cluster;
cluster_vector=handles.cluster_vector;
parameters=handles.parameters;

sel=ClusterAllocation==selected_cluster;
nSpikes=sum(sel);

%PCA_Matrix=squeeze(spikeData(parameters.PCA_dimensions,:,sel))';
PCA_Matrix=squeeze(spikeData(parameters.PCA_dimensions(1):end,:,sel))';
[COEF scores]=princomp(PCA_Matrix);

nPCA_components=3;
features=scores(:,1:nPCA_components);

switch 3
    case 1
        KK_folder='KlustaKwik';
        baseName='temp';
        clusterNr=1;
        tempName=[baseName '.fet.' num2str(clusterNr)];
        nFeatures=size(features,2);
        dlmwrite(fullfile(KK_folder,tempName),nFeatures,'delimiter','\t')
        dlmwrite(fullfile(KK_folder,tempName),round(features),'delimiter','\t','-append')
        
        if parameters.usePCAcomponents==1
            useFeatures=[char(zeros(1,nFeatures-nPCA_components)+48) char(zeros(1,nPCA_components)+49)];
            %disp(['Using first ' num2str(nPCA_components) ' PCA components'])
        else
            useFeatures=['1100001' char(zeros(1,nPCA_components)+48)];
            %disp('Using peak-valley-energy')
        end
        disp(['Now Clustering all ' num2str(nSpikes) ' spikes using KlustaKwik! Please be patient...'])
        cd('KlustaKwik')
        eval(['!KlustaKwik.exe "' fullfile(rootFolder,KK_folder,baseName) '" ' num2str(clusterNr) ' -ChangedThresh 0.500000 -DistThresh 0.000000 -FullStepEvery 10 -MinClusters 2 -MaxClusters 2 -MaxIter 500 -MaxPossibleClusters 4 -PenaltyMix 0 -nStarts 1 -RandomSeed 1 -SplitEvery 50 -fSaveModel 0 -Log 0 -Screen 0 -UseFeatures '  useFeatures ''])
        ClusterAllocation_split=dlmread([baseName '.clu.' num2str(clusterNr)]);
        cd(rootFolder)
        ClusterAllocation_split=ClusterAllocation_split(2:end);
    case 2
        ClusterAllocation_split=kmeans(features,2);
    case 3         
        features=spikeMatrix(sel,3+[handles.var1 handles.var2]);        
        ClusterAllocation_split=kmeans(features,2);
    case 4
        splitting=1;
        iter=1;
        max_iterations=5;
        
        while splitting==1
            [ClusterAllocation_split N]=KK_Cluster(scores(:,1:3),[],2);
            iter=iter+1;
            bias=mean(ClusterAllocation_split)-1;
            [N bias]
            if N==2&&between(bias,[.10 .90])
                disp('KlustaKwik did it!!!')                
                splitting=0;
            end
            if iter>max_iterations
                %features=spikeMatrix(sel,3+[handles.var1 handles.var2]);
                %ClusterAllocation_split=kmeans(features,2);
                %disp('K-means had to do it...')
                splitting=0;                
            end
        end        
end


%unique(ClusterAllocation_split)
if length(unique(ClusterAllocation_split))==2
    largest_cluster=mode(ClusterAllocation_split);
    new_cluster_nr=CC_find_next_cluster_number(cluster_vector);
    ClusterAllocation_split(ClusterAllocation_split~=largest_cluster)=new_cluster_nr;
    ClusterAllocation_split(ClusterAllocation_split==largest_cluster)=selected_cluster;
    
    ClusterAllocation(sel)=ClusterAllocation_split;
    
    handles.ClusterAllocation=ClusterAllocation;
    cluster_vector=sort([cluster_vector ; new_cluster_nr]);
    handles.cluster_vector=cluster_vector;
    
    handles=CC_calc_properties(handles,new_cluster_nr);
    
    %%% Make new entry in history matrix
    handles.ClusterAllocation_history=[handles.ClusterAllocation_history(:,1:handles.history_index) ClusterAllocation];
    handles.history_index=handles.history_index+1;
    guidata(H,handles)
    CC_update_gui(handles)
    
    %%% 
    fprintf('remaining spikes were moved to cluster %d',new_cluster_nr)
    
else
    disp('Re-cluster failed...')
end
