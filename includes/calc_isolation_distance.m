function isolation_distance = calc_isolation_distance(varargin)

feature_matrix=varargin{1};
cluster_spikes=varargin{2};


%% calculate center of mass of selected cluster: mean x-y coordinate weighted by spike amplitude
x_vector=feature_matrix(cluster_spikes,1);
y_vector=feature_matrix(cluster_spikes,2);
weight_vector=feature_matrix(cluster_spikes,3);
weight_vector=spherify2(weight_vector,2);

regular_mean=[mean(x_vector) mean(y_vector)];
weighted_mean=[mean(sum(x_vector.*weight_vector)/sum(weight_vector)) mean(sum(y_vector.*weight_vector)/sum(weight_vector))];

clusterSpikes=feature_matrix(cluster_spikes,1:2);
nonclusterSpikes=feature_matrix(~cluster_spikes,1:2);
M1=mahal(weighted_mean,clusterSpikes);


[dist_vector_sorted order]=sort(mahal(nonclusterSpikes,clusterSpikes));
noise_spikes=nonclusterSpikes(order,1:2);
noise_spikes=noise_spikes(1:sum(cluster_spikes),:);
M2=mahal(weighted_mean,noise_spikes);


abs(M1-M2)/(M1+M2)


plotIt=1;
if plotIt==1
    plot(feature_matrix(:,1),feature_matrix(:,2),'.','color',[1 1 1]*.9)
    hold on
    plot(x_vector,y_vector,'.')
    plot(noise_spikes(:,1),noise_spikes(:,2),'r.')
    plot(regular_mean(:,1),regular_mean(:,2),'m*')
    plot(weighted_mean(:,1),weighted_mean(:,2),'c*')
    hold off
    
    axis square
    axis equal
    
    box off
end


isolation_distance=0;