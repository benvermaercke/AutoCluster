function new_cluster_nr=CC_find_next_cluster_number(varargin)
cluster_vector=varargin{1};
if any(diff(cluster_vector)>1) % Check if number is free within the sequence
    new_cluster_nr=find(diff(cluster_vector)>1,1,'first')+1;
else % Otherwise, pick the next largest number
    new_cluster_nr=length(cluster_vector)+1;
end