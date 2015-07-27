function [values screens levers]=convertTTL(TTLS)
%function [values screens levers]=convertTTL(TTLS)
% This function can be used to decode 16-bit DIO-messages returned in the Nttls
% argument by the Nlx2MatEV function. 
% The first two bits contain information about the two photocells on the screen. 
% Possible values are:
% - 0 both squares are white
% - 1 left square is white
% - 2 right square is white
% - 3 both squares are black
% => returned in SCREENS
%
% The next 8 bits encode the headers.
% Possible values are between 0 and 255
% => returned in VALUES
%
% The next 2 bits encode the levers
% 0=down | 1=pressed

if nargin~=1
    help convertTTL
else % bits are read from right to left
    binvecs=myDec2binvec(TTLS,12);
    screens=binvecs(:,[12 11]);
    values=myBinvec2dec(binvecs(:,3:10));
    levers=binvecs(:,[2 1]);
end


function out = myDec2binvec(varargin)
if nargin>=1
    in=varargin{1};
end
if nargin>=2
    n=varargin{2};
else
    n=12; % cheetah case
end
len=length(in);
if len>1
    in=repmat(in(:),1,n);
end
powers=repmat(pow2(1-n:0),len,1);
out=rem(floor(in.*powers),2);


function out=myBinvec2dec(varargin)
if nargin>=1
    in=varargin{1};
end

[m, n]=size(in);
twos =pow2(n-1:-1:0);
if m>1
    twos = repmat(twos,m,1);
end
out = sum(in .* twos(ones(m,1),:),2);