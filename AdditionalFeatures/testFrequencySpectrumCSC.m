%% Load files
clc
clear

switch 4
    case 1
        dirname='E:\Documents Leuven Psychologie\Data\2012-10-31_09-47-38\11. 7339422976 To 7639052763\';
    case 2
        dirname='E:\Documents Leuven Psychologie\Data\2012-10-31_09-47-38\12. 7639052763 To 8060120396\';
    case 3
        dirname='E:\Documents Leuven Psychologie\Data\2012-11-22_10-05-58\07. 3907904998 To 4910498435\';
    case 4
        dirname='E:\Documents Leuven Psychologie\Data\2012-11-23_09-28-24\07. 6441192577 To 7557508314\';
end
filename = [dirname 'CSC12.ncs'];
eventfilename = [dirname 'events.nev'];

[X_AS Ydata header NlxHeader]=readCSCfile(filename,[],2);
yRange=header.InputRange;

T2=X_AS(end);
sel=X_AS<=T2;

X=X_AS(sel);
Y=Ydata(sel);


%% Getting Event Timestamps
% Warning! CSC and NEV analysis use the same variables! Be careful to
% check before running the program

FieldSelection(1) = 1;      % 1. Timestamps
FieldSelection(2) = 0;      % 2. Event IDs
FieldSelection(3) = 1;      % 3. Ttls
FieldSelection(4) = 0;      % 4. Extras
FieldSelection(5) = 1;      % 5. Event Strings

ExtractHeader = 0;          % 0= No header extracted, 1= extract header

ExtractMode = 1;            % 1 = all, 4 = Timestamp range (Set in ModeArray)

[TimeStamps, Nttls, EventStrings] = Nlx2MatEV( eventfilename, FieldSelection, ExtractHeader, ExtractMode);

for i = 1:900
    if ~isempty(findstr(char(cellstr(EventStrings{i,1})),'starting exp')) || ~isempty(findstr(char(cellstr(EventStrings{i,1})),'Starting exp'))%%%%%%%%%%%%%%%%%%%
        expnum = strtrim(EventStrings{i,1}(13:end));
        try
            expnum = str2num(expnum(1:2));
        catch
            expnum = str2num(expnum(1));
        end
        
        disp(cellstr(EventStrings(i,:)));
        spikedata.ExperimentHeader = EventStrings(i,:);
        break;
    end
end

% if ~(expnum == expectedexp)
%     disp(sprintf('This is not the right experiment %f file',expectedexp));
%     spikedata.error = 1;
%     return;
% end


if expnum == 3
    nCond = 8;
elseif expnum == 4
    nCond = 12;
elseif expnum == 5
    nCond = 7;
    ExpDuration=0.5;
elseif expnum == 7
    nCond =1;
elseif expnum == 8
    nCond = 15;
    ExpDuration=0.5;
elseif expnum == 9
    nCond = 13;
elseif expnum == 10
    nCond = 12;
    ExpDuration=2;
elseif expnum == 1
    nCond = 6;
elseif expnum == 11
    nCond = 6;
elseif expnum == 12
    nCond = 24; %nCond = 6;
    ExpDuration= 4;
elseif expnum == 13
    nCond = 48;
    ExpDuration=4;
elseif expnum == 15
    nCond = 192; % 8 shapes * 3 sizes * 8 orientations
elseif expnum == 16
    nCond = 240; % 6 shapes * 5 rotations * 8 orientations
elseif expnum == 17
    nCond = 128; % 8 shapes * 2 positions * 8 orientations
end

%% Converting TTLs to decimal numbers

[TTLvals TTLscreen TTLlever] = convertTTL(Nttls);
stepSize = 8;
trial=1;
DataOn1=zeros(1,151);
DataOff1=zeros(1,151);

for i=1:length(TTLvals)-stepSize
    if TTLvals(i) == 254
        conditionNr=TTLvals(i+4);
        CN(trial)=conditionNr;
        checkOnset=TTLvals(i+stepSize);
        if checkOnset>1
            stimOnset(trial)=TimeStamps(i+stepSize+1);
        else
            stimOnset(trial)=TimeStamps(i+stepSize);
        end
        stimOffset(trial)=stimOnset(trial)+ExpDuration*10^6;
        trial=trial+1;
    end
end
Results=[CN' stimOnset' stimOffset'];
spikedata.Results = Results;

startTime = TimeStamps(1);
xLength = length(Ydata)/header.SamplingFrequency;

%% Find envelope of maximum amplitude in  small time bins
samplingFreq = header.SamplingFrequency;
T = 1/samplingFreq;                     % Sample time
L = samplingFreq*5;                     % Length of signal
lengthWindow = 0.010; %ms

BinSize = round(lengthWindow*samplingFreq);
count=0;
for i = 1:BinSize:length(Y)-BinSize
    count=count+1;
    YmaxSmooth(count) = max(Y(i:i+BinSize));
end

% plot(YmaxSmooth)
% figure(2)
% plot(X,Y)

%% calculate frequency spectrum of smoothed data
samplingFreq = 1/lengthWindow;
T = 1/samplingFreq;                     % Sample time
L = samplingFreq*2;                     % Length of signal window
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
f = samplingFreq/2*linspace(0,1,NFFT/2+1);
sel = sum(f<200);
freqTable = [];
c=0;
for i = 1:round(0.200/T):length(YmaxSmooth)-L
    c=c+1;
    t = (i:i-1+L-1)*T;                % Time vector
    
    Yn = abs(fft(YmaxSmooth(i:i+L),NFFT)/L);
    freqTable = [freqTable; Yn(1:sel)];
end

%%

finalTable = freqTable(:,2:end)';
imagesc(finalTable)
set(gca,'CLim',[0 max(finalTable(:))/1]);
set(gca,'ytick',[1:20:sel],'yticklabel',round(f(2:20:sel)))%sci(f,0)) %(2:20:sel)
axis xy
hold on
freqSum = sum(freqTable(:,f>6 & f<=9),2);
plot(freqSum,'r-')
% plot([1:count]./count.*c,YmaxSmooth,'y-')

meanSum = mean(freqSum);
sdSum = std(freqSum);
treshold = sdSum*1;

plot([0 c],[meanSum meanSum],'m-',[0 c],[meanSum+treshold meanSum+treshold],'m--')
remappedOnset=[];
remappedOffset=[];
remappedBLonset=[];
TrialBursts=zeros(size(stimOnset));
BaselineBursts=zeros(size(stimOnset));

for i = 1:length(stimOnset)
    remappedOnset(i)=(stimOnset(i)-startTime)/1000000/xLength*c;
    remappedOffset(i)=(stimOffset(i)-startTime)/1000000/xLength*c;
    remappedBLonset(i) = (stimOnset(i)-2000000-startTime)/1000000/xLength*c;
    plot([remappedOnset(i) remappedOnset(i)],[100 103],'g-',...
        [remappedOffset(i) remappedOffset(i)],[100 103],'r-',...
        [remappedBLonset(i) remappedBLonset(i)],[100 103],'y-')
    
    roundedOnset = round(remappedOnset(i));
    roundedOffset = round(remappedOffset(i));
    roundedBaseline = round(remappedBLonset(i));
    
    trialTheta = freqSum(roundedOnset:roundedOffset)>meanSum+treshold;
    if sum(trialTheta)/length(trialTheta) > 0.2
        TrialBursts(i) = 1;
        plot([roundedOnset roundedOffset],[95 95],'r-')
    end
    
    baselineTheta = freqSum(roundedBaseline:roundedOnset)>meanSum+treshold;
    if sum(baselineTheta)/length(baselineTheta) > 0.2
        BaselineBursts(i) = 1;
        plot([roundedBaseline roundedOnset],[95 95],'y-')
    end

    
end






hold off




