function CC_update_gui(varargin)

handles=varargin{1};
handles=guidata(handles.figure1);

var1=handles.var1;
var2=handles.var2;

spikeData=handles.spikeData;
spikeMatrix=handles.spikeMatrix;
ClusterAllocation=handles.ClusterAllocation;

cluster_vector=handles.cluster_vector;
cluster_vector(cluster_vector==0)=[];
handles.nClusters=length(cluster_vector);
handles.ClusterNames=strcat({'Cluster #'},num2str((cluster_vector').')).';

%%% Adjust cluster names based on exiting clusters
set(handles.cluster_names_dd,'string',handles.ClusterNames)


selected_cluster=handles.selected_cluster;
cheetahColors=handles.cheetahColors;

T=spikeMatrix(:,2);
P1=spikeMatrix(:,3+var1);
P2=spikeMatrix(:,3+var2);
x_maxval=max(abs(P1));xRange=[-x_maxval x_maxval]*1.5;
y_maxval=max(abs(P2));yRange=[-y_maxval y_maxval]*1.5;
handles.xRange=xRange;handles.yRange=yRange;

set(handles.subplots(1).plot_handles(1),'Xdata',P1,'Ydata',P2)

for iClust=1:handles.nClusters
    clusterNr=handles.cluster_vector(iClust);
    sel=ClusterAllocation==clusterNr;
   
    if selected_cluster==clusterNr        
        %set(handles.subplots(1).plot_handles(1+clusterNr),'Xdata',spikeMatrix(sel,3+var1),'Ydata',spikeMatrix(sel,3+var2),'markerSize',5,'color',cheetahColors(clusterNr,:))
        set(handles.layer2_plots(1),'Xdata',spikeMatrix(sel,3+var1),'Ydata',spikeMatrix(sel,3+var2),'markerSize',6,'color',cheetahColors(clusterNr,:))
        %set(handles.layer2_plots(1),'Xdata',[],'Ydata',[],'markerSize',5,'color',cheetahColors(clusterNr,:))
    end
    set(handles.subplots(1).plot_handles(1+clusterNr),'Xdata',spikeMatrix(sel,3+var1),'Ydata',spikeMatrix(sel,3+var2),'markerSize',1,'color',cheetahColors(clusterNr,:))
end

for iClust=1:handles.nColors
     if ~ismember(iClust,handles.cluster_vector)
         set(handles.subplots(1).plot_handles(1+iClust),'Xdata',0,'Ydata',0,'markerSize',1)
     end
end

%%% Reset ROI markers
set(handles.ROI_polygon,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
set(handles.ROI_ellipse,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')

set(handles.properties_table,'CellEditCallback',{@readTable,handles.properties_table_name,selected_cluster})

%%% Show data for this cluster
sel=ClusterAllocation==selected_cluster;

if sum(sel)==0 %|| var1==var2
    for iSpike=1:handles.max_N_spikes
        set(handles.subplots(2).plot_handles(iSpike),'Xdata',1:handles.nSamples,'Ydata',zeros(1,handles.nSamples),'color','w');
    end
    
    set(handles.subplots(3).plot_handles(1),'Ydata',zeros(1,130),'color',cheetahColors(selected_cluster,:))
    set(handles.figure_handles(3),'Ylim',[0 100])
    
    set(handles.subplots(4).plot_handles(1),'Ydata',zeros(1,64),'LData',zeros(64,1),'UData',zeros(64,1),'color',cheetahColors(selected_cluster,:))
else
    %%% Show waveforms
    selected_waveforms=squeeze(spikeData(:,:,sel));
    random_sample=randsample(1:sum(sel),min([sum(sel) handles.max_N_spikes]),0);
        
    for iSpike=1:handles.max_N_spikes
        if iSpike<length(random_sample)
            set(handles.subplots(2).plot_handles(iSpike),'Ydata',selected_waveforms(:,random_sample(iSpike)),'color',cheetahColors(selected_cluster,:))
        else
            set(handles.subplots(2).plot_handles(iSpike),'Ydata',zeros(1,handles.nSamples),'color','w');
        end
    end
    %%% Reset ROI markers
    set(handles.ROI_box_points,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
    set(handles.ROI_box,'Xdata',handles.xRange(1),'Ydata',handles.yRange(1),'color','k')
    updateRect(handles.ROI_rect,[0 0 0 0],'k')  
    
    %%% Show ISI histogram
    ISI_vector=diff(T(sel));
    bins=logspace(log10(1),log10(1E8),130);
    ISI_vector(ISI_vector>max(bins))=[];
    values=hist(ISI_vector,bins);
    maxVal=max(values)*1.2;
    
    set(handles.subplots(3).plot_handles(1),'Ydata',values,'color',cheetahColors(selected_cluster,:))
    set(handles.figure_handles(3),'Ylim',[0 maxVal])
    
    %%% Show average waveform + error
    A=squeeze(spikeData(:,:,sel))';
    A_avg=mean(A);
    A_std=std(A);
    set(handles.subplots(4).plot_handles(1),'Ydata',A_avg,'UData',A_std','LData',A_std','color',cheetahColors(selected_cluster,:))    
end

%%% Update table
handles=CC_calc_properties(handles,handles.selected_cluster);
guidata(handles.figure1,handles)
writeTable(handles.properties_table,handles.properties_table_name,selected_cluster)


guidata(handles.figure1,handles)