function varargout = localMaxMin(varargin)
%function varargout = localMaxMin(varargin)

if nargin>=1
    signal=varargin{1};
end
if nargin>=2
    plotIt=varargin{2};
else
    plotIt=0;
end
N=length(signal);

SD=diff(signal);
localMaxima=find(diff(sign(SD))<=-1)+1;
localMinima=find(diff(sign(SD))>=1)+1;

if nargout>=1
    varargout{1}=localMaxima;
end
if nargout>=2
    varargout{2}=localMinima;
end
if nargout>=3
    varargout{3}=signal(localMaxima);
end
if nargout>=4
    varargout{4}=signal(localMinima);
end


if plotIt==1
    plot(signal,'b.-')
    hold on
    plot([0 N],[0 0],'k--')
    plot([localMaxima(:) localMaxima(:)]',repmat([-255 255],length(localMaxima),1)','m*-')
    plot([localMinima(:) localMinima(:)]',repmat([-255 255],length(localMinima),1)','c*-')
    hold off
    axis([0 N min(signal) max(signal)])
end
