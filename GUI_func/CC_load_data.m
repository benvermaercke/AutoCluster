function CC_load_data(varargin)
H=varargin{1};
handles=guidata(H);

if ~exist('loadName','var')
    cd(handles.dataRootFolder)
    [fname pathName]=uigetfile('*.mat');
    if fname==0
        cd(handles.rootFolder)
        error('Filename is required...')
    else
        loadName=fullfile(pathName,fname);
    end
    cd(handles.rootFolder)
end

%fName=fileparts(loadName);
fName=loadName(length(handles.dataRootFolder)+2:end);
[~,core]=fileparts(loadName);
parts=strsplit('_',core);
handles.channelID=parts{1};

set(handles.loadName_txt,'String',fName)

%%% Reset cluster mapping
if isfield(handles,'cluster_parameters')
    handles=rmfield(handles,'cluster_parameters');
end

%warning off
load(loadName,'spikeData','spikeMatrix','ClusterAllocation','parameters','noiseSTD_vector','cluster_parameters')
if exist('cluster_parameters','var')
    handles.cluster_parameters=cluster_parameters;
end
%warning on


handles.loadName=loadName;
handles.spikeData=spikeData;
spikeMatrix(:,10)=spikeMatrix(:,10)/1E3;
handles.spikeMatrix=spikeMatrix;
handles.ClusterAllocation=ClusterAllocation;
cluster_vector=unique(handles.ClusterAllocation);
cluster_vector=cluster_vector(cluster_vector>0);
handles.cluster_vector=cluster_vector;
handles.nClusters=length(handles.cluster_vector);
handles.max_N_spikes=min([500 max(hist(ClusterAllocation,handles.nClusters))]);
handles.nSamples=size(spikeData,1);
handles.parameters=parameters;
handles.noise_level=mean(noiseSTD_vector);
handles.time_axis=((1:handles.parameters.nSamples)-handles.parameters.PeakSample+1)/handles.samplingRate*1000;
handles.time_axis_slice=1:10:handles.nSamples;

handles.selected_cluster=1;
set(handles.cluster_names_dd,'value',1) % adjust in GUI
handles.var1=1;
handles.var2=2;

set(handles.var1_dd,'value',1);
set(handles.var2_dd,'value',2);

handles.ClusterAllocation_history=handles.ClusterAllocation;
handles.history_index=1;

handles.ClusterNames=strcat({'Cluster #'},num2str((1:handles.nClusters).')).';

guidata(H,handles)
CC_init_gui(handles)
CC_update_gui(handles)