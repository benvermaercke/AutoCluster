function str = padZeros(number,len)
% output a string containing the NUMBER and preceded by enough zeros
% to make the string LEN long

number=round(number);
if ~exist('len','var')
    len=4;
end
if len==0
    len=1;
end
str=num2str(number,['%0' num2str(len) 'd']);



%string=num2str(number);
%number=round(number);
% if length(string)>len
%    %disp('Number is too big, adjusting...')
%    len=length(string);
% end

% % perpare zeros
% str=char(repmat(48,1,len));
%
% for s=1:length(string)
%     str(length(str)-s+1)=string(length(string)-s+1);
% end