function out = ST_cross_correlation(S1,S2,window_size,nBins)
%function out = ST_cross_correlation(S1,S2,window_size,nBins)
%
% Order of spike trains defines directionality, spikes of S1 are the
% reference, S2 spikes come before or after as indicated by the time below
% or above zero

%size(S2)

switch 2
    case 1
        N1=length(S1);
        STH_matrix=zeros(N1,nBins);
        for iSpike=1:N1
            interval=[S1(iSpike)-window_size*1000 S1(iSpike)+window_size*1000];
            in_interval=between(S2,interval);
            bins=linspace(interval(1),interval(2),nBins);
            values=hist(S2(in_interval),bins);
            STH_matrix(iSpike,1:nBins)=values;
        end
        
    case 2
        %%% First bin both spike trains
        %tic
        %bin_width=1E2;
        try
            bin_width=window_size/nBins*1000;
            time_factor=1E3/bin_width;
            window_size=window_size*time_factor;
            
            bins=S1(1):bin_width:S1(end);
            values1=hist(S1,bins);
            values2=hist(S2,bins);
            
            events=find(values1>0);
            events(~between(events,[window_size max(events)-window_size]))=[];
            N1=length(events);
            
            %%% Then select windows of 2 centered around spike in 1
            selection=-window_size/2:window_size/2;
            STH_matrix=zeros(N1,length(selection));
            for iSpike=1:N1
                reference=events(iSpike);
                selection=reference-window_size/2:reference+window_size/2;
                STH_matrix(iSpike,:)=values2(selection);
            end
        catch
            N1=length(S1);
            STH_matrix=zeros(N1,nBins);
            for iSpike=1:N1
                interval=[S1(iSpike)-window_size*1000 S1(iSpike)+window_size*1000];
                in_interval=between(S2,interval);
                bins=linspace(interval(1),interval(2),nBins);
                values=hist(S2(in_interval),bins);
                STH_matrix(iSpike,1:nBins)=values;
            end
        end
end
out=mean(STH_matrix);