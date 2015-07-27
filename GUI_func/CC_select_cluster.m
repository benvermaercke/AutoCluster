function CC_select_cluster(varargin)

H=varargin{1};
handles=guidata(H);
cluster_vector=handles.cluster_vector;
handles.selected_cluster=cluster_vector(get(H,'Value'));
guidata(H,handles);

CC_update_gui(handles)