function [X_AS Ydata header NlxHeader]=readCSCfile(varargin)
%function [X_AS Ydata header NlxHeader]=readCSCfile(filename,range)

if nargin>=1
    filename=varargin{1};
    if exist(filename,'file')==2
        
        if nargin>=2&&~isempty(varargin{2}) % read range
            range=varargin{2};
            
            [Timestamps Samples NlxHeader] = Nlx2MatCSC( filename, [1 0 0 0 1], 1, 4, range);
        else % read all
            [Timestamps Samples NlxHeader] = Nlx2MatCSC( filename, [1 0 0 0 1], 1, 1);
        end
        header=readNlxHeader(NlxHeader);
        
        if nargin>=3&&~isempty(varargin{3})
            adjustRange=varargin{3};
        else
            adjustRange=1;
        end
        
        %%
        actualVoltage=5;
        nSamplesPerPacket=512;        
        Fs=header.SamplingFrequency;
        switch adjustRange
            case 0
                Ydata=Samples(:);
            case 1
                yRange=header.InputRange;
                ADbitFactor=header.ADBitVolts*header.ADMaxValue/actualVoltage;
                Ydata=Samples(:)*ADbitFactor*yRange;
            case 2                
                Ydata=Samples(:)/header.ADMaxValue*header.InputRange;
        end
        
        sampleTime=1/Fs*1000000;
        nPackets=length(Timestamps);
        
        T=repmat(Timestamps,nSamplesPerPacket,1)+meshgrid(0:nSamplesPerPacket-1,1:nPackets)'*sampleTime;
        X_AS=T(:)';
        
    end
end