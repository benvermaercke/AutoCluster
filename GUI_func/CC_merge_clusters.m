function CC_merge_clusters(varargin)
H=varargin{1};
handles=guidata(H);

handles2.figure1=handles.figure1;
handles2.figure2=figure(2);

time_axis=handles.time_axis;
time_axis_slice=handles.time_axis_slice;

set(handles.figure1,'Units','Pixels');
main_window_position=get(handles.figure1,'Position');
set(handles.figure1,'Units','Normalized');
aux_window_size=main_window_position(3:4)/2;
aux_window_position=[main_window_position(1:2)+aux_window_size/2 aux_window_size];
set(handles2.figure2,'Position',aux_window_position)

%%% Draw panel
main_panel=uipanel(handles2.figure2,'Units','Normalized','Position',[.025 .025 .95 .95]);

%%% Draw buttons
preset_value1=find(handles.cluster_vector==handles.selected_cluster);
preset_value2=handles.cluster_vector(1);
handles2.selected_clusters=[handles.selected_cluster preset_value2];
uicontrol(main_panel,'style','popupmenu','string',handles.ClusterNames,'units','normalized','position',[.1 .9 .2 .05],'callback',{@CC_aux_select_cluster,1},'value',preset_value1)
uicontrol(main_panel,'style','popupmenu','string',handles.ClusterNames,'units','normalized','position',[.3 .9 .2 .05],'callback',{@CC_aux_select_cluster,2},'value',1)
uicontrol(main_panel,'style','Pushbutton','string','Merge Selected Clusters','units','normalized','position',[.5 .9 .3 .05],'callback',@CC_aux_merge_clusters)

%%% Draw axes
N=handles.nSamples;
handles2.aux_figure_handles(1)=subplot(121);
line([1 N],[0 0],'color','w')
hold on
handles2.aux_subplots(1).handles(5)=plot([handles.parameters.PeakSample handles.parameters.PeakSample],[-400 ; 400],'r','lineWidth',1);
handles2.aux_subplots(1).handles(1)=plot(1:N,zeros(1,N),'r','lineWidth',2);
handles2.aux_subplots(1).handles(2)=errorbar(1:N,zeros(1,N),zeros(1,N),'r','lineWidth',1);
handles2.aux_subplots(1).handles(3)=plot(1:N,zeros(1,N),'b','lineWidth',2);
handles2.aux_subplots(1).handles(4)=errorbar(1:N,zeros(1,N),zeros(1,N),'b','lineWidth',1);
hold off
set(handles2.aux_figure_handles(1),'units','normalized','position',[.1 .2 .4 .5],'color','k')
set(gca,'Xtick',time_axis_slice,'XtickLabel',round(time_axis(time_axis_slice)*10)/10)
axis([1 N -400 400])
axis square
box off
title('Average Waveforms')
handles2.aux_subplots(1).handles(5)=xlabel(sprintf('N1=%d ; N2=%d',[0 0]));

N=51;
handles2.aux_figure_handles(2)=subplot(122);
line([0 0],[0 1],'color','w')
hold on
handles2.aux_subplots(2).handles(1)=bar(1:N,zeros(1,N),'FaceColor','r','edgeColor','r');
hold off
axis([1 N 0 1])
set(handles2.aux_figure_handles(2),'units','normalized','position',[.55 .2 .4 .5],'color','k')
axis square
box off
title('Cross-Correlogram')
handles2.aux_subplots(2).handles(2)=xlabel(sprintf('Shows how %d fires relative to %d',[2 1]));

guidata(handles2.figure2,handles2)
CC_aux_update_gui(handles2)