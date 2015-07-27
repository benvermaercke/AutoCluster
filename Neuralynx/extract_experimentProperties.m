function experimentProperties=extract_experimentProperties(TTL_TimeStamps,TTLS)

%%% Create one matrix with timestamps and decoded TTL triggers
M=[TTL_TimeStamps(:) convertTTL(TTLS)];


trial_start_vector=find(M(:,2)==254);
trial_start_vector(trial_start_vector>size(M,1)-8)=[];

%%% Detect experiment labels and check them for errors
experiment_labels=M(trial_start_vector+2,2);
if length(unique(experiment_labels))==1
    experiment_type=experiment_labels(1);
else
    disp('Mixed experiment numbers, possible bug...')
    
    %%% Detect most likely experiment label
    experiment_type_temp=mode(experiment_labels);
    error_cases=find(experiment_labels~=experiment_type_temp);
    
    for iError=1:length(error_cases)
        rowNr=trial_start_vector(error_cases(iError));
        %%% Show the part of the condition vector that caused the issue
        disp(M(rowNr-3:rowNr+8,2)')
    end
    %%% Delete error cases
    M(trial_start_vector(error_cases),:)=[];
    
    %%% Recalculate most stuff
    trial_start_vector=find(M(:,2)==254);
    trial_start_vector(trial_start_vector>size(M,1)-8)=[];    
    experiment_labels=M(trial_start_vector+2,2);
    
    if length(unique(experiment_labels))==1
        experiment_type=experiment_labels(1);
        disp('Auto-Correction successful...')
    else
        disp('Auto-Correction failed...')
    end
end

%%% Detect condition labels and check them for errors
condition_labels=M(trial_start_vector+4,2);
if any(condition_labels==0)||any(condition_labels>250)
    disp('Invalid condition numbers, possible bug...')
end
condition_labels_unique=unique(condition_labels);
nConditions=length(condition_labels_unique);

%%% Collect timestamps for start of the trial
trial_start=M(trial_start_vector,1);

%%% Collect timestamps when screens are turned on
trial_onset=M(trial_start_vector+8,1);

%%% Construct trial matrix: timestamps and condition labels
trialMatrix=[trial_onset condition_labels];
nTrials=size(trialMatrix,1);

%%% Check timing difference between start of the trial and when stimulus
%%% appears
diffOnset=(trial_onset-trial_start)/1E3;
timing_results=[mean(diffOnset) std(diffOnset)];
mean_onset=mean(diffOnset);
std_onset=std(diffOnset)*2;

%%% Check for outliers
outliers=diffOnset(not(between(diffOnset,[mean_onset-std_onset mean_onset+std_onset])));
nOutliers=length(outliers);

if nOutliers>5
    bins=0:1000;
    hist(diffOnset,bins)
end


%%% Construct output variable
experimentProperties.experiment_type=experiment_type;

experimentProperties.nConditions=nConditions;
experimentProperties.condition_labels_unique=condition_labels_unique;
experimentProperties.condition_labels=condition_labels;

experimentProperties.trialMatrix=trialMatrix;
experimentProperties.trialDuration=[];
experimentProperties.nTrials=nTrials;

experimentProperties.diffOnset=diffOnset;
experimentProperties.timing_results=timing_results;
experimentProperties.nOutliers=nOutliers;
experimentProperties.outliers=outliers;
