function CC_aux_update_gui(varargin)
handles2=varargin{1};
handles=guidata(handles2.figure1);
handles2=guidata(handles2.figure2);


spikeData=handles.spikeData;
spikeMatrix=handles.spikeMatrix;
T=spikeMatrix(:,2);
ClusterAllocation=handles.ClusterAllocation;
cheetahColors=handles.cheetahColors;

cluster_nr1=handles2.selected_clusters(1);
cluster_nr2=handles2.selected_clusters(2);
sel1=ClusterAllocation==cluster_nr1;
sel2=ClusterAllocation==cluster_nr2;

%%% Update average waveforms
A=squeeze(spikeData(:,:,sel1));
B=squeeze(spikeData(:,:,sel2));
A_avg=mean(A,2);
A_std=std(A,[],2);
B_avg=mean(B,2);
B_std=std(B,[],2);
cross_correlation=normxcorr2(A_avg,B_avg);
cross_correlation=cross_correlation(length(A_avg):end);
[M time_shift]=max(cross_correlation(1:round(end/2)));

B_avg_shift=zeros(size(B_avg));
B_avg_shift(1:end-time_shift)=B_avg(time_shift:end-1);

%time_axis=((1:handles.parameters.nSamples)-handles.parameters.PeakSample+1)/handles.samplingRate*1000;

set(handles2.aux_subplots(1).handles(1),'Ydata',A_avg,'color',cheetahColors(cluster_nr1,:))
set(handles2.aux_subplots(1).handles(2),'Ydata',A_avg,'Udata',A_std,'color',cheetahColors(cluster_nr1,:),'Ldata',A_std,'color',cheetahColors(cluster_nr1,:))
set(handles2.aux_subplots(1).handles(3),'Ydata',B_avg,'color',cheetahColors(cluster_nr2,:))
%set(handles2.aux_subplots(1).handles(3),'Xdata',1:length(cross_correlation),'Ydata',cross_correlation*400,'color',cheetahColors(cluster_nr2,:))
%set(handles2.aux_subplots(1).handles(3),'Ydata',B_avg_shift,'color',cheetahColors(cluster_nr2,:))

set(handles2.aux_subplots(1).handles(4),'Ydata',B_avg,'Udata',B_std,'color',cheetahColors(cluster_nr2,:),'Ldata',B_std,'color',cheetahColors(cluster_nr2,:))

set(handles2.aux_subplots(1).handles(5),'string',sprintf('N1=%d; N2=%d; Shift=%d; Rmax=%4.3f',[sum(sel1) sum(sel2) time_shift-1 M]))

%%% Update cross-correlation plot
ST1=T(sel1);
ST2=T(sel2);

window_size=10;
nBins=50;
values=ST_cross_correlation(ST1,ST2,window_size,nBins);
X_AS=linspace(-window_size/2,window_size/2,length(values));
set(handles2.aux_subplots(2).handles(1),'Xdata',X_AS,'Ydata',values)
set(handles2.aux_figure_handles(2),'Xlim',X_AS([1 end]),'Ylim',[0 max(values)*1.2+eps])
set(handles2.aux_subplots(2).handles(2),'string',sprintf('Shows how %d fires relative to %d',[cluster_nr2 cluster_nr1]))