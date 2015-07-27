function handles=CC_calc_properties(varargin)

handles=varargin{1};
selected_cluster=varargin{2};

spikeData=handles.spikeData;
spikeMatrix=handles.spikeMatrix;
ClusterAllocation=handles.ClusterAllocation;
parameters=handles.parameters;
T=spikeMatrix(:,2);

sel=ClusterAllocation==selected_cluster;

handles.cluster_parameters(selected_cluster).Total_spikes=size(spikeMatrix,1);
handles.cluster_parameters(selected_cluster).Number_of_clusters=handles.nClusters;
handles.cluster_parameters(selected_cluster).Cluster_number=selected_cluster;
handles.cluster_parameters(selected_cluster).Number_of_spikes=sum(sel);

if sum(sel)>0
    %%% Get Mahalanobis distance-based measures
    warning off
    Q=Cluster_Quality(spikeMatrix(:,[handles.var1 handles.var2]),find(sel));
    warning on
    
    %%% Get amplitude from average waveform
    A=squeeze(spikeData(:,:,sel));
    average_waveform=mean(A,2);    
    Tpeak=parameters.PeakSample;
    [Tmax Tmin]=localMaxMin(average_waveform(Tpeak:end));
    if isempty(Tmin)
        Tvalley=parameters.nSamples;
    else
        Tvalley=Tpeak+Tmin(1);
    end                    
    width=Tvalley-Tpeak;
    %amplitude=range(average_waveform);
    amplitude=average_waveform(Tpeak)-average_waveform(Tvalley);
            
    %%% Calc slope
    slope=amplitude/width;
    down_phase=average_waveform(Tpeak:Tvalley);
    step_size=5;
    start_vector=1:(length(down_phase)-step_size);
    nStart=length(start_vector);
    max_slope_vector=zeros(nStart,1);
    for iStart=1:nStart
        max_slope_vector(iStart,1)=diff(down_phase([start_vector(iStart) start_vector(iStart)+step_size]))/step_size;
    end
    max_slope=max(abs(max_slope_vector));
    
    
    %%% Get ISI histogram to check for early spikes
    ISI_vector=diff(T(sel));
    bins=logspace(log10(1),log10(1E8),130);
    ISI_vector(ISI_vector>max(bins))=[];
    percentage_early_spikes=sum(ISI_vector<handles.early_threshold)/length(ISI_vector)*100;
    
    handles.cluster_parameters(selected_cluster).Isolation_distance=Q.IsolationDist;
    handles.cluster_parameters(selected_cluster).L_ratio=Q.Lratio;
    handles.cluster_parameters(selected_cluster).Noise_level=handles.noise_level;
    handles.cluster_parameters(selected_cluster).Amplitude=amplitude;
    handles.cluster_parameters(selected_cluster).Width=width;
    handles.cluster_parameters(selected_cluster).slope=slope;
    handles.cluster_parameters(selected_cluster).max_slope=max_slope;
    handles.cluster_parameters(selected_cluster).SNR_raw=amplitude/handles.noise_level;
    handles.cluster_parameters(selected_cluster).SNR=20*log10(amplitude/handles.noise_level);
    handles.cluster_parameters(selected_cluster).Early_spikes=percentage_early_spikes;
else
    handles.cluster_parameters(selected_cluster).Isolation_distance=[];
    handles.cluster_parameters(selected_cluster).L_ratio=[];
    handles.cluster_parameters(selected_cluster).Noise_level=[];
    handles.cluster_parameters(selected_cluster).Amplitude=[];
    handles.cluster_parameters(selected_cluster).Width=[];
    handles.cluster_parameters(selected_cluster).slope=[];
    handles.cluster_parameters(selected_cluster).max_slope=[];
    handles.cluster_parameters(selected_cluster).SNR_raw=[];
    handles.cluster_parameters(selected_cluster).SNR=[];
    handles.cluster_parameters(selected_cluster).Early_spikes=[];
    handles.cluster_parameters(selected_cluster).Unit_number=[];
end
