clear all
clc

%%% Load example data
ntt_filename='TetrodeExampleData\TT1.ntt';
[Timestamps, Samples, Header] = Nlx2MatSpike(ntt_filename,[1 0 0 0 1], 1, 1, []);

%% Fiddle with the data
Samples(:,2,:)=Samples(:,1,:);

%%% Save the data to a new file
saveName='TetrodeExampleData\ntt_resaved.ntt';
Mat2NlxSpike(saveName,0,1,[],[1 0 1 0 1 1],Timestamps,ones(size(Timestamps)),Samples,Header)

%% Save random data
Samples_random=round((rand(size(Samples))*2^16)-2^15);
Samples_random
Mat2NlxSpike(saveName,0,1,[],[1 0 1 0 1 1],Timestamps,ones(size(Timestamps)),Samples_random,Header)

%% Save actual SE data, expanded
load('exampleSEdata.mat','TimeStampsSE','spikeData_SE')
spikeData_SE(:,2,:)=round(spikeData_SE(:,1,:)*.9);
spikeData_SE(:,3,:)=round(spikeData_SE(:,1,:)*.8);
spikeData_SE(:,4,:)=round(spikeData_SE(:,1,:)*.4);
Mat2NlxSpike(saveName,0,1,[],[1 0 1 0 1 1],TimeStampsSE,ones(size(TimeStampsSE)),spikeData_SE,Header)

%% extract header as it may proove important to get the correct file structure on saving
TT_Header=Header;
save('TT_header.mat','TT_Header')


