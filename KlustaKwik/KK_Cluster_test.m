clear all
clc

cheetahColors=[255 0 0 ; 255 222 153 ; 161 255 0 ; 153 255 158 ; 0 255 187 ; 153 212 255 ; 12 0 127 ; 232 153 255 ; 255 0 135 ; 255 168 153 ; 255 212 0 ; 202 255 153 ; 0 255 51 ; 153 255 243 ; 0 110 255 ; 89 76 127 ; 119 0 127 ; 127 76 96 ; 127 38 0 ; 127 126 76 ; 42 127 0 ; 76 127 94 ; 0 123 127 ; 76 90 127 ; 51 0 127 ; 127 76 123 ; 127 0 29 ; 127 99 76 ; 110 127 0 ; 85 127 76 ; 0 127 63 ; 76 118 127]/255;

nSamples_per_class=1000;
nFeatures=5;
D1=randn(nSamples_per_class,nFeatures);
D2=randn(nSamples_per_class,nFeatures)+2;
class_vector=cat(1,ones(nSamples_per_class,1),ones(nSamples_per_class,1)+1);

features=cat(1,D1,D2);
randomizer=randperm(size(features,1));
features=features(randomizer,:);
class_vector=class_vector(randomizer);

splitting=1;
iter=1;
max_iterations=10;

while splitting==1
    [mapping N]=KK_Cluster(features,[],3);
    iter=iter+1;
    if N==2
        splitting=0;
    end
    if iter>max_iterations
        die
    end
end

%%
[mean(class_vector==mapping) mean(class_vector~=mapping)]

tabulate(mapping)

figure(1)
clf
hold on
for iClust=1:N
    sel=mapping==iClust;
    switch nFeatures
        case 2
            plot(features(sel,1),features(sel,2),'.','color',cheetahColors(iClust,:))
        case 3
            plot3(features(sel,1),features(sel,2),features(sel,3),'.','color',cheetahColors(iClust,:))            
            view(45,45)
            grid on
        otherwise
            [COEF scores]=princomp(features);
            
            plot3(scores(sel,1),scores(sel,2),scores(sel,3),'.','color',cheetahColors(iClust,:))            
            view(45,45)
            grid on
    end
end
