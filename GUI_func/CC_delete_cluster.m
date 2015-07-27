function CC_delete_cluster(varargin)
H=varargin{1};
handles=guidata(H);

cluster_vector=handles.cluster_vector;
ClusterAllocation=handles.ClusterAllocation;
selected_cluster=handles.selected_cluster;
cluster_vector(cluster_vector==selected_cluster)=[];

ClusterAllocation(ClusterAllocation==selected_cluster)=0;

new_cluster_nr=cluster_vector(1);
set(handles.cluster_names_dd,'value',1)

handles.cluster_vector=cluster_vector;
handles.selected_cluster=new_cluster_nr;
handles.ClusterAllocation=ClusterAllocation;

guidata(H,handles)
CC_update_gui(handles)
