function CC_aux_select_cluster(varargin)

H=varargin{1};
cluster_number=varargin{3};
handles2=guidata(H);
handles=guidata(handles2.figure1);
cluster_vector=handles.cluster_vector;
handles2.selected_clusters(cluster_number)=cluster_vector(get(H,'Value'));
guidata(H,handles2);

CC_aux_update_gui(handles2)
