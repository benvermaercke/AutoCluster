clear all
clc

headerFile

areaNr=3;
fileNr=13;

feature_space=1; % Peak-valley-energy / PCA

areaName=sprintf('area%02d',areaNr);
loadFolder=fullfile(saveFolder,areaName);
files=scandir(loadFolder,'.mat');

%disp(cat(1,files.name))
filename=files(fileNr).name;
filename_str=filename;
filename_str(filename_str=='_')=' ';
loadName=fullfile(saveFolder,areaName,filename);

if not(exist(loadName,'file'))
    disp(['File ' filename ' does not exist in folder ' saveFolder])
else
    A=load(loadName,'exp*');
    
    %%% Collect features for all clusters for this unit
    experiment_names=fieldnames(A);
    nExperiments=length(experiment_names);
    feature_matrix=[];
    cluster_allocation=[];
    for iExp=1:nExperiments
        exp_name=experiment_names{iExp};
        
        eval(['F=A.' exp_name '.clusterProperties.features;']);
        eval(['W=A.' exp_name '.clusterProperties.average_waveform;'])
        
        switch feature_space
            case 1
                F=F(:,[4 5 10]);
            case 2 % use 3 first PCA components even if more were used during clustering, as these first components explain most of the variance in the data
                F=F(:,[11 12 13]);
        end
        feature_matrix=cat(1,feature_matrix,F);
        cluster_allocation=cat(1,cluster_allocation,ones(size(F,1),1)*iExp);
        
        avg_waveforms{iExp}=W;
    end
    
    
    ranges=max(abs(feature_matrix))*1.2;
    
    %clf
    %hold on
    %%% Plot all clusters
    cluster_vector=unique(cluster_allocation);
    nClusters=length(cluster_vector);
    
    randColors=[1 5 8 10];
    
    if 0
        %% Plot selected clusters in 3D
        figure(1)
        hold on
        for iCluster=1:nClusters
            sel=cluster_allocation==iCluster;
            randColor=Randi(15);
            plot3(feature_matrix(sel,1),feature_matrix(sel,2),feature_matrix(sel,3),'.','color',cheetahColors(randColors(iCluster),:),'markerSize',1)
        end
        
        plot3([-ranges(1) ranges(1)],[0 0],[0 0],'w')
        plot3([0 0],[-ranges(2) ranges(2)],[0 0],'w')
        plot3([0 0],[0 0],[-ranges(3) ranges(3)],'w')
        hold off
        axis([-ranges(1) ranges(1) -ranges(2) ranges(2) -ranges(3) ranges(3)])
        set(gcf,'color',[0 0 0])
        set(gca,'visible','off','position',[-.2 -.2 1.4 1.4])
        
        axis vis3d
        rotate3d on
    end
    
    if 0
        %% In 2D
        figure(2)
        for iCluster=1:nClusters
            sel=cluster_allocation==iCluster;
            plot(feature_matrix(sel,1),feature_matrix(sel,2),'.','color',cheetahColors(randColors(iCluster),:),'markerSize',1)
            hold on
        end
        %set(gca,'visible','off','position',[-.2 -.2 1.4 1.4])
        
        
        %%% Fitted ellipses
        for iCluster=1:nClusters
            sel=cluster_allocation==iCluster;
            plot(feature_matrix(sel,1),feature_matrix(sel,2),'.','color',cheetahColors(randColors(iCluster),:),'markerSize',1)
            hold on
        end
        for iCluster=1:nClusters
            sel=cluster_allocation==iCluster;
            ellipse=fit_ellipse(feature_matrix(sel,1),feature_matrix(sel,2));
            nPoints=100;
            H(iCluster)=plotEllipse(ellipse.a,ellipse.b,-ellipse.phi,ellipse.X0_in,ellipse.Y0_in,min([cheetahColors(randColors(iCluster),:)+.1 ; 1 1 1]),nPoints);
            set(H(iCluster),'LineWidth',2)
        end
        legend(H,experiment_names)
        
        plot([-ranges(1) ranges(1)],[0 0],'w')
        plot([0 0],[-ranges(2) ranges(2)],'w')
        hold off
        axis([-ranges(1) ranges(1) -ranges(2) ranges(2)])
        axis equal
        set(gca,'color',[0 0 0])
        set(gcf,'color',[0 0 0])
        t=title(filename_str);
        set(t,'color',[1 1 1],'Visible','on')
    end
    
    %% Show average waveforms
    figure(3)
    for iCluster=1:nClusters
        W=avg_waveforms{iCluster};
        H(iCluster)=errorbar(W(:,1),W(:,2),W(:,3),'color',cheetahColors(randColors(iCluster),:));
        hold on
    end
    xRange=[1 size(W,1)];
    plot(xRange,[0 0],'w')
    hold off
    set(gca,'visible','off')
    set(gcf,'color',[0 0 0])
    legend(H,experiment_names)
    axis([xRange -400 400])
    t=title(filename_str);
    set(t,'color',[1 1 1],'Visible','on')
end



