% a function that calculates means and standard deviations of data
function [tmean,tstd]=meanstd2(temp)
% m*n array cantaining temperature data
% m2*n2 array containing index information (rows refer to each 'zone')
[m1,n1]=size(temp);
tmean=zeros(m1,1);
tstd=zeros(m1,1);
%
for i=1:m1
		ind=find(~isnan(temp(i,:)));
		tmean(i)=mean(temp(i,ind)');
		if ~isempty(ind)
			tstd(i)=std(temp(i,ind));
		else
			tstd(i)=NaN;
		end
end

