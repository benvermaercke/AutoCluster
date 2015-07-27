function CC_history(varargin)

H=varargin{1};
handles=guidata(H);
operation=varargin{3};

ClusterAllocation_history=handles.ClusterAllocation_history;
nPages=size(ClusterAllocation_history,2);
history_index=handles.history_index;
switch operation
    case 'back'
        history_index=history_index-1;
    case 'next'
        history_index=history_index+1;
end

cluster_vector=unique(handles.ClusterAllocation);
cluster_vector=cluster_vector(cluster_vector>0);
if history_index>=1&&history_index<=nPages
    handles.ClusterAllocation=ClusterAllocation_history(:,history_index);
    handles.history_index=history_index;   
    handles.cluster_vector=cluster_vector;
    %history_index
end

if ~ismember(handles.selected_cluster,cluster_vector)
    set(handles.cluster_names_dd,'value',1)
    handles.selected_cluster=1;
end

guidata(H,handles)
CC_update_gui(handles)