function CC_insert_cluster(varargin)
H=varargin{1};
handles=guidata(H);

cluster_vector=handles.cluster_vector;

%%% Check which number new cluster shoud get
if any(diff(cluster_vector)>1) % Check if number is free within the sequence
    new_cluster_nr=find(diff(cluster_vector)>1,1,'first')+1;
else % Otherwise, pick the next largest number
    new_cluster_nr=length(cluster_vector)+1;
end

cluster_vector=sort([cluster_vector ; new_cluster_nr]);
handles.cluster_vector=cluster_vector;

handles=CC_calc_properties(handles,new_cluster_nr);
set(handles.cluster_names_dd,'value',new_cluster_nr)
handles.selected_cluster=new_cluster_nr;

guidata(H,handles)
CC_update_gui(handles)