function CC_save_data(varargin)

H=varargin{1};
handles=guidata(H);

cluster2unit_mapping=zeros(0,2);
count=1;

for iCluster=1:handles.nClusters
    cluster_number=handles.cluster_vector(iCluster);
    if ~isempty(handles.cluster_parameters(cluster_number).Unit_number)
        cluster2unit_mapping(count,:)=[cluster_number handles.cluster_parameters(cluster_number).Unit_number];
        count=count+1;
    end    
end

saveName=handles.loadName;
saveFolder=fileparts(saveName);

%%% Save txt file containing cluster2unit mapping
dlmwrite(fullfile(saveFolder,[handles.channelID '_cluster2unit_mapping.txt']),cluster2unit_mapping,'delimiter','\t','newline','pc')

%%% Overwrite ClusterAllocation
ClusterAllocation=handles.ClusterAllocation;
cluster_parameters=handles.cluster_parameters;
save(saveName,'ClusterAllocation','cluster_parameters','-append')