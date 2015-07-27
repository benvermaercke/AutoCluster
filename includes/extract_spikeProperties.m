function spikeProperties=extract_spikeProperties(spike,peak_time)

nSamples=length(spike);
peak_value=spike(peak_time); % peak value

%%% use this to differentiate between positive and negative spikes
% if peak_value<0
%     %%% Inverted positive spike => peak and valley are reversed
%     [Tmin Tmax m M]=localMaxMin(spike(peak_time:end));
%     if isempty(m)
%         m=max(spike);
%         Tmin=find(spike==m);
%     end
%
%     valley_value=m(1); % valley value
%     spikeHeight=abs(peak_value-valley_value); % amplitude
%
%     nextMax=-1;
% else

%%% Regular positive (inverted negative) spike
[Tmax Tmin M m]=localMaxMin(spike(peak_time:end));
if isempty(m)
    m=min(spike);
    Tmin=find(spike==m);
end

valley_value=m(1); % valley value
spikeHeight=peak_value-valley_value; % amplitude

TimeMax=peak_time; % fixed
TimeMin=TimeMax+Tmin(1)-1; % time of valley

%%% Find first local maximum after the valley
[Tmax_next Tmin_next M_next m_next]=localMaxMin(spike(TimeMin:end));
if ~isempty(M_next)
    nextMax=M_next(1);
elseif ~isempty(spike(TimeMin:end))
    nextMax=max(spike(TimeMin:end));
else
    nextMax=spike(end);
end


% end

TimeMax=peak_time; % fixed
TimeMin=TimeMax+Tmin(1)-1; % time of valley
spikeWidth=TimeMin-TimeMax+1; % spike width
spikeArea=norm(spike); % spike area
spikeEnergy=sum(spike.^2);

%%% Determine zero-crossing
nextZeroCrossing=TimeMin+find(sign(spike(TimeMin:end))>0,1,'first');
if isempty(nextZeroCrossing)||valley_value>0
    nextZeroCrossing=nSamples+2;
end


%%% Construct output vector
spikeProperties=[peak_value valley_value spikeHeight spikeWidth nextMax spikeArea spikeEnergy];

