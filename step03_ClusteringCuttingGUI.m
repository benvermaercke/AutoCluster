clear all
clc
headerFile

%% Put main figure ready
handles.figure1=figure;
set(handles.figure1,'menubar','none','toolbar','figure','Units','Normalized','Position',[.1 .1 .7 .8],'resize','on','NumberTitle','Off','Name','AutoCluster: Cluster Cutting')

%% Place Tables
%%% Create sub panels
controlPanel = uipanel(gcf,'Tag','MainPanel','Units','Normalized','Position',[.01 .9 .98 .08]);
graphPanel   = uipanel(gcf,'Tag','MainPanel','Units','Normalized','Position',[.01 .02 .98 .87]);

%% Initialize variables
handles.rootFolder=rootFolder;
handles.dataRootFolder=dataRootFolder;
handles.cheetahColors=cheetahColors;
handles.nColors=nColors;
handles.property_names={'Peak','Valley','Height','Width','NextZero','Area','Energy','PCA1','PCA2','PCA3','PCA4','PCA5'};
handles.early_threshold=2500;
handles.controlPanel=controlPanel;
handles.graphPanel=graphPanel;
handles.samplingRate=32556;

%% Place Buttons
xPos=.01;
yPos=.3;
button_width=.15;
spacing_factor=1.1;
button_height=.5;
iElement=0;
uicontrol(controlPanel,'style','pushbutton','string','Insert Cluster','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement yPos-.25 button_width/2 button_height*.75],'callback',@CC_insert_cluster);
uicontrol(controlPanel,'style','pushbutton','string','Delete Cluster','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement+button_width/2 yPos-.25 button_width/2 button_height*.75],'callback',@CC_delete_cluster);
handles.cluster_names_dd=uicontrol(controlPanel,'style','popupmenu','string','Clusters','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement yPos button_width button_height],'callback',@CC_select_cluster);iElement=iElement+1;

handles.var1_dd=uicontrol(controlPanel,'style','popupmenu','string',handles.property_names,'units','normalized','position',[xPos+(button_width*spacing_factor)*iElement yPos button_width/2 button_height],'callback',{@CC_select_var,1},'value',8);iElement=iElement+1;
handles.var2_dd=uicontrol(controlPanel,'style','popupmenu','string',handles.property_names,'units','normalized','position',[xPos+(button_width*spacing_factor)*iElement-button_width/2 yPos button_width/2 button_height],'callback',{@CC_select_var,2},'value',9);iElement=iElement+1;
uicontrol(controlPanel,'style','pushbutton','string','Define ROI','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement-button_width yPos button_width button_height],'callback',@CC_define_roi);iElement=iElement+1;

handles.cut_spikes_bt=uicontrol(controlPanel,'style','pushbutton','string','Cut spikes','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement-button_width yPos button_width/1.5 button_height],'callback',{@CC_cut_spikes,'cut'},'enable','off');iElement=iElement+1;
handles.add_spikes_bt=uicontrol(controlPanel,'style','pushbutton','string','Add spikes','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement-button_width*1.4 yPos button_width/1.5 button_height],'callback',{@CC_cut_spikes,'add'},'enable','off');iElement=iElement+1;
handles.move_spikes_bt=uicontrol(controlPanel,'style','pushbutton','string','Move2new','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement-button_width*1.8 yPos button_width/1.5 button_height],'callback',{@CC_cut_spikes,'move'},'enable','off');%iElement=iElement+1;
handles.use_ellipse_bt=uicontrol(controlPanel,'style','checkbox','string','Use ellipse','Value',1,'units','normalized','position',[xPos+(button_width*spacing_factor)*iElement-button_width yPos button_width button_height]);iElement=iElement+1;
uicontrol(controlPanel,'style','pushbutton','string','Undo','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement-button_width*1.6 yPos button_width/4 button_height],'callback',{@CC_history,'back'});iElement=iElement+1;
uicontrol(controlPanel,'style','pushbutton','string','Redo','units','normalized','position',[xPos+(button_width*spacing_factor)*iElement-button_width*2.45 yPos button_width/4 button_height],'callback',{@CC_history,'next'});iElement=iElement+1;

%%% Prepare properties table
handles.properties_table=uitable(graphPanel,'Tag','input_table','Units','Normalized','Position',[.01 .4 .18 .50]);
handles.properties_table_name='cluster_parameters';

handles.loadName_txt=uicontrol(graphPanel,'style','text','Units','Normalized','Position',[.001 .275 .20 .1],'backgroundcolor','k','foregroundcolor','w','String','No file loaded...','FontName','Courier New','HorizontalAlignment','Left');
uicontrol(graphPanel,'style','pushbutton','string','Load Data','units','normalized','position',[.05 .225 .1 .025],'callBack',@CC_load_data)
uicontrol(graphPanel,'style','pushbutton','string','Merge Clusters','units','normalized','position',[.05 .2 .1 .025],'callBack',@CC_merge_clusters)
uicontrol(graphPanel,'style','pushbutton','string','Split Cluster','units','normalized','position',[.05 .175 .1 .025],'callBack',@CC_split_clusters)
uicontrol(graphPanel,'style','pushbutton','string','Update Datafile','units','normalized','position',[.05 .15 .1 .025],'callBack',@CC_save_data)

%%% Put 4 graph panels ready
handles.axis_positions=[.2000 .5838 .3347 .3412 ;.6000 .5838 .3347 .3412; .2000 .1100 .3347 .3412; .6000 .1100 .3347 .3412];
coords=[.05 .10; .075 .10; .05 .075 ; .075 .075];
handles.window_priority=1;
for iSubplot=1:4    
    handles.axis_inflate_buttons(iSubplot)=uicontrol(graphPanel,'style','pushbutton','string',num2str(iSubplot),'units','normalized','position',[coords(iSubplot,:) .025 .025],'callback',{@CC_inflate_panel,iSubplot},'BackgroundColor','r');
end

guidata(gcf,handles)

