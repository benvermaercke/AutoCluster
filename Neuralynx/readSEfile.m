function [spikeTimes spikes header NlxHeader cell_allocation]=readSEfile(varargin)
%function [spikes header]=readSEfile(filename,range)

if nargin>=1
    filename=varargin{1};
    
    if nargin>=2 % read range
        range=varargin{2};
        [spikeTimes cell_allocation spikes NlxHeader] = Nlx2MatSpike( filename, [1 0 1 0 1], 1, 4, range);
    else % read all
        [spikeTimes cell_allocation spikes NlxHeader] = Nlx2MatSpike( filename, [1 0 1 0 1], 1, 1);
    end
    header=readNlxHeader(NlxHeader);
    
    %%
    switch 1
        case 1
            actualVoltage=5;
            %Fs=header.SamplingFrequency;
            yRange=header.InputRange;
            ADbitFactor=header.ADBitVolts*header.ADMaxValue/actualVoltage;
            spikes=spikes*ADbitFactor*yRange;
        case 2
            
    end
    %sampleTime=1/Fs*1000000;
    
end