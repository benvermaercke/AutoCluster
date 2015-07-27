function CC_aux_merge_clusters(varargin)
H=varargin{1};
handles2=guidata(H);

handles=guidata(handles2.figure1);
ClusterAllocation=handles.ClusterAllocation;

selected_clusters=handles2.selected_clusters;
new_cluster_number=min(selected_clusters);

ClusterAllocation(ismember(ClusterAllocation,selected_clusters))=new_cluster_number;
handles.ClusterAllocation=ClusterAllocation;
cluster_vector=unique(ClusterAllocation);
cluster_vector(cluster_vector==0)=[];
handles.cluster_vector=cluster_vector;

%%% Make new entry in history matrix
handles.ClusterAllocation_history=[handles.ClusterAllocation_history(:,1:handles.history_index) ClusterAllocation];
handles.history_index=handles.history_index+1;

selector_value=find(cluster_vector==new_cluster_number);
set(handles.cluster_names_dd,'value',selector_value)
handles.selected_cluster=new_cluster_number;
guidata(handles2.figure1,handles)
CC_update_gui(handles)

%%% Close this window
close(handles2.figure2)

