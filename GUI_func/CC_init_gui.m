function CC_init_gui(varargin)

handles=varargin{1};
handles=guidata(handles.figure1);

var1=handles.var1;
var2=handles.var2;
spikeData=handles.spikeData;
spikeMatrix=handles.spikeMatrix;
ClusterAllocation=handles.ClusterAllocation;
cluster_vector=unique(ClusterAllocation);
cluster_vector(cluster_vector==0)=[];
nClusters=length(cluster_vector);
parameters=handles.parameters;
time_axis=handles.time_axis;
time_axis_slice=handles.time_axis_slice;

selected_cluster=handles.selected_cluster;
cheetahColors=handles.cheetahColors;
property_names=handles.property_names;

T=spikeMatrix(:,2);
P1=spikeMatrix(:,3+var1);
P2=spikeMatrix(:,3+var2);
x_maxval=max(abs(P1));xRange=[-x_maxval x_maxval]*1.5;
y_maxval=max(abs(P2));yRange=[-y_maxval y_maxval]*1.5;
handles.xRange=xRange;handles.yRange=yRange;

handles.ROIx=[];
handles.ROIy=[];
handles.ellipse=[];

nRows=2;
nCols=2;
handles.figure_handles(1)=subplot(nRows,nCols,1,'Parent',handles.graphPanel);
cla
handles.subplots(1).plot_handles(1)=plot(P1,P2,'.','markerSize',1,'color',[1 1 1]*.8);
set(gca,'color','k','position',handles.axis_positions(1,:))
line([0 0 ; -1E6 1E6]',[ -1E6 1E6 ; 0 0]','color',[1 1 1]*.5)
hold on
for iClust=1:nClusters
    clusterNr=cluster_vector(iClust);
    sel=ClusterAllocation==clusterNr;
    
    %if selected_cluster==clusterNr
        %handles.subplots(1).plot_handles(1+iClust)=plot(spikeMatrix(sel,3+var1),spikeMatrix(sel,3+var2),'.','color',cheetahColors(clusterNr,:),'markersize',5);
     %   handles.layer2_plots(1)=plot(spikeMatrix(sel,3+var1),spikeMatrix(sel,3+var2),'.','color',cheetahColors(clusterNr,:),'markersize',5);        
    %else        
    handles.subplots(1).plot_handles(1+iClust)=plot(spikeMatrix(sel,3+var1),spikeMatrix(sel,3+var2),'.','color',cheetahColors(clusterNr,:),'markersize',1);
    %end
end
for iClust=nClusters+1:handles.nColors
    plot([],[],'.','color',cheetahColors(iClust,:),'markersize',1)
    handles.subplots(1).plot_handles(1+iClust)=plot(0,0,'.','color',cheetahColors(iClust,:),'markersize',1);
end

hold off
xlabel(property_names{var1})
ylabel(property_names{var2})
axis([xRange yRange])
box off
axis square
title('Feature Space')

%%% Layer 2: shows selected cluster
handles.layer2_handles(1)=axes('parent',handles.graphPanel,'position',handles.axis_positions(1,:));
handles.layer2_plots(1)=plot(0,0,'.');
hold on
handles.ROI_polygon=plot(xRange(1),yRange(1),'k*-');
handles.ROI_ellipse=plot(xRange(1),yRange(1),'k-');
hold off
box off
axis square
set(gca,'Xlim',xRange,'Ylim',yRange,'xTick',[],'Ytick',[],'color','none')

%%% Mask axes: used for selection ROI's
handles.mask_handles(1)=axes('parent',handles.graphPanel,'position',handles.axis_positions(1,:));
box off
axis square
set(gca,'Xlim',xRange,'Ylim',yRange,'xTick',[],'Ytick',[],'color','none')
set(zoom,'ActionPostCallback',{@CC_sync_axes,1}) % keep axes in sync when zooming
set(pan,'ActionPostCallback',{@CC_sync_axes,1})

%set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})

%%% Show data for this cluster
sel=ClusterAllocation==selected_cluster;
if sum(sel)==0
    handles.figure_handles(2)=subplot(nRows,nCols,2,'Parent',handles.graphPanel);
    cla
    set(gca,'color','k','position',handles.axis_positions(2,:))
    line([parameters.PeakSample ; parameters.PeakSample],[-yRange ; yRange],'color',[1 0 0])
    line([1 parameters.nSamples ],[0 0],'color',[1 1 1])
    axis([1 parameters.nSamples yRange])
    set(gca,'Xtick',time_axis_slice,'XtickLabel',round(time_axis(time_axis_slice)*10)/10)
    
    handles.figure_handles(3)=subplot(nRows,nCols,3,'Parent',handles.graphPanel);
    cla
    set(gca,'color','k','position',handles.axis_positions(3,:))
    line([56 56],[0 100],'color',[1 0 0])
    axis([1 130 0 100])
    axis square
    box off
    
    handles.figure_handles(4)=subplot(nRows,nCols,4,'Parent',handles.graphPanel);
    cla
    set(gca,'color','k','position',handles.axis_positions(4,:))
    line([1 parameters.nSamples ],[0 0],'color',[1 1 1])
    box off
    axis square
    axis([1 parameters.nSamples -400 400])
else
    %%% Show waveforms
    handles.figure_handles(2)=subplot(nRows,nCols,2,'Parent',handles.graphPanel);
    cla
    handles.subplots(2).plot_handles=line(1:parameters.nSamples,zeros(handles.max_N_spikes,parameters.nSamples),'color','w');
    hold on
    handles.ROI_box_points=plot(xRange(1),yRange(1),'k*');
    handles.ROI_box=plot(xRange(1),yRange(1),'k-');
    nBoxes=5;
    for iBox=1:nBoxes
        handles.ROI_rect(iBox,:)=plotRect([0 0 0 0],'k');
    end
    hold off
    set(gca,'Xtick',time_axis_slice,'XtickLabel',round(time_axis(time_axis_slice)*10)/10)
    
    selected_waveforms=squeeze(spikeData(:,:,sel));
    random_sample=randsample(1:sum(sel),min([sum(sel) handles.max_N_spikes]),0);
    for iSpike=1:length(random_sample)
        set(handles.subplots(2).plot_handles(iSpike),'Xdata',1:parameters.nSamples,'Ydata',selected_waveforms(:,random_sample(iSpike)),'color',cheetahColors(selected_cluster,:))
    end
    
    set(gca,'color','k','position',handles.axis_positions(2,:))
    line([parameters.PeakSample ; parameters.PeakSample],[-400 ; 400],'color',[1 0 0])
    line([1 parameters.nSamples],[0 0],'color',[1 1 1])
    axis([1 parameters.nSamples -400 400])
    axis square
    box off
    title('Example Waveforms')
    
    % Create mask to select stuff on subplot 2
    handles.mask_handles(2)=axes('parent',handles.graphPanel,'position',handles.axis_positions(2,:));
    axis square
    box off
    set(gca,'Xlim',[1 parameters.nSamples],'Ylim',[-400 400],'xTick',[],'Ytick',[],'color','none')
    set(zoom,'ActionPostCallback',{@CC_sync_axes,2}) % keep axes in sync when zooming
    set(pan,'ActionPostCallback',{@CC_sync_axes,2})
    
    %%% Get ISI histogram
    ISI_vector=diff(T(sel));
    bins=logspace(log10(1),log10(1E8),130);
    ISI_vector(ISI_vector>max(bins))=[];
    values=hist(ISI_vector,bins);
    maxVal=max(values)*1.2;
    TH=find(bins>handles.early_threshold,1,'first');
    
    handles.figure_handles(3)=subplot(nRows,nCols,3,'Parent',handles.graphPanel);
    cla
    handles.subplots(3).plot_handles(1)=plot(1:length(values),values,'color',cheetahColors(selected_cluster,:),'lineWidth',2);
    line([TH TH],[0 1E5],'color',[1 0 0])
    axis([1 length(values) 0 maxVal])
    set(gca,'color','k','position',handles.axis_positions(3,:))
    axis square
    box off
    title('ISI Histogram')
    
    %%% Show average waveform + error
    handles.figure_handles(4)=subplot(nRows,nCols,4,'Parent',handles.graphPanel);
    cla
    sel=ClusterAllocation==selected_cluster;
    A=squeeze(spikeData(:,:,sel))';
    A_avg=mean(A);
    A_std=std(A);
    handles.subplots(4).plot_handles(1)=errorbar(A_avg,A_std,'color',cheetahColors(selected_cluster,:));
    line([1 parameters.nSamples],[0 0],'color',[1 1 1])
    line([parameters.PeakSample ; parameters.PeakSample],[-400 ; 400],'color',[1 0 0])
    set(gca,'color','k','position',handles.axis_positions(4,:))
    box off
    axis square
    axis([1 parameters.nSamples -400 400])
    title('Average Waveform (+/-STD)')
end

%%% Init table
set(handles.properties_table,'ColumnName',{'Parameter' 'Value'},'ColumnWidth',{100 70},'ColumnEditable',[false true],'ColumnFormat',{'char' ''},'RowName',[],'CellEditCallback',{@readTable,handles.properties_table_name,selected_cluster})

%%% Update table
for iClust=1:handles.nClusters
    clusterNr=handles.cluster_vector(iClust);
    handles=CC_calc_properties(handles,clusterNr);
    if ~isfield(handles.cluster_parameters(selected_cluster),'Unit_number')
        handles.cluster_parameters(selected_cluster).Unit_number=[];
    end
end

guidata(handles.figure1,handles)
writeTable(handles.properties_table,handles.properties_table_name,selected_cluster)

guidata(handles.figure1,handles)