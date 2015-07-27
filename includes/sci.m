function rounded = sci(varargin)
%function rounded = sci(varargin)



if nargin>=1
    values=varargin{1};
end
if nargin>=2
    precision=varargin{2};
else
    precision=2;
end
if nargin>=3&&~isempty(varargin{3})
    format=varargin{3};
else
    format=['%8.' num2str(precision) 'f'];
end

rounded=num2str(values,format);

% multiplier=10^precision;
% rounded=round(values*multiplier)/multiplier;
% 
% if mod(rounded,1)<1E-5
%     decimals=0;
% else
%     decimals=length(num2str(mod(rounded,1)))-2;
% end
% if decimals<=0
%     addon=['.' char(zeros(1,precision)+48)];
% else
%     addon=char(zeros(1,precision-decimals)+48);
% end
% rounded=[num2str(rounded) addon];

% if nargin==0
%     help sci
% else
%     for i=1:length(values)
%         value=values(i);
%         if isnan(value)
%             rounded='NaN';
%         else
%             if nargin==1
%                 precision=2;
%             else
%                 precision=varargin{1};
%             end
%
%             signValue=sign(value);
%             if signValue==1
%                 signString='';
%             else
%                 signString='-';
%             end
%             value=abs(value);
%             whole=num2str(floor(value));
%             multiplier=10^precision;
%             dec=padZeros(abs(floor(mod(value,floor(value))*multiplier)),precision);
%             rounded{i}=[signString whole '.' dec];
%         end
%     end
% end
%
% if length(rounded)==1
%    rounded=rounded{1};
% end