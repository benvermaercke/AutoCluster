function varargout=KK_Cluster(varargin)

if nargin>=1&&~isempty(varargin{1})
    features=varargin{1};
else
    error('KK_Cluster requires at least one input argument')
end
nSpikes=size(features,1);
nFeatures=size(features,2);

if nargin>=2&&~isempty(varargin{2})
    feature_selection=varargin{2};
else
    feature_selection=ones(1,nFeatures);
end

if nargin>=3&&~isempty(varargin{3})
    maxNClusters=varargin{3};
else
    maxNClusters=15;
end

% Write the last part of spikeMatrix to a feature (*.fet_N) file and use
% this as input to klustaKwik => cluster numbers will be placed in the
% corresponding *.clu_N file
KK_folder='temp';
baseName='temp';
clusterNr=1;
inputName=fullfile(KK_folder,[baseName '.fet.' num2str(clusterNr)]);
outputName=fullfile(KK_folder,[baseName '.clu.' num2str(clusterNr)]);

%%% Convert feature_selection vector into string
useFeatures=char(feature_selection+48);

if nSpikes>1E5
    disp(['Now Clustering all ' num2str(nSpikes) ' spikes using KlustaKwik! Please be patient...'])
end
oldFolder=pwd;
thisFolder=fileparts(which('KK_Cluster.m'));
cd(thisFolder)

    %%% Write features to file
    dlmwrite(inputName,nFeatures,'delimiter','\t')
    dlmwrite(inputName,round(features),'delimiter','\t','-append')

    %%% Execute KustaKwik
    command=['!KlustaKwik.exe "' fullfile(thisFolder,KK_folder,baseName) '" ' num2str(clusterNr) ' -ChangedThresh 0.500000 -DistThresh 0.000000 -FullStepEvery 10 -MinClusters 2 -MaxClusters 10 -MaxIter 500 -MaxPossibleClusters ' num2str(maxNClusters) ' -PenaltyMix 0.000000 -nStarts 1 -SplitEvery 50 -fSaveModel 0 -Log 0 -Screen 0 -UseFeatures '  useFeatures ''];
    %command=['!KlustaKwik.exe "' fullfile(thisFolder,KK_folder,baseName) '" ' num2str(clusterNr) ' -MaxPossibleClusters ' num2str(maxNClusters) ' -nStarts 1 -SplitEvery 20 -fSaveModel 0 -Log 0 -Screen 0 -UseFeatures '  useFeatures ''];
    eval(command)
    if nSpikes>1E5
        disp('Clustering done...')
    end

    %%% Read *.clu.1 file => extract cluster allocation for each spike
    ClusterAllocation=dlmread(outputName);
    
cd(oldFolder)

%%% Prepare output
%nClusters=ClusterAllocation(1);
ClusterAllocation=ClusterAllocation(2:end);
ClusterAllocation=ClusterAllocation-min(ClusterAllocation)+1;
nClusters=length(unique(ClusterAllocation));

if nargout>=1
    varargout{1}=ClusterAllocation;
end

if nargout>=2
    varargout{2}=nClusters;
end