% function [a] =covarxy(x1,x2,gs,ts,q)
%
% Output:
% a 	m*n  unscaled Gaussian covariance function
%
% Input:
% x1	m*3  model grid, col 1+2+3 are lat, long, depth respectively
% x2	n*3  data grid, col 1+2+3 are lat, long, depth respectively
% ts	scalar, horizontal latitude scale  (degrees)
% gs    scalar, horizontal longitude scale (degrees)
% q	scalar, vertical scale  (metres)
%
% Author:   N.L. Bindoff
% Date:     8/October/1990
% Modified: J. Harris
% Date:     18/10/93
% Modified: A. Wong
% Date:     13 April 2000

function  [a] =covarxy(x1,x2,gs,ts,q)

m=size(x1);
n=size(x2);
a=zeros(m(1),n(1));
one=ones(n(1),1);

for i=1:m(1)
	tmp1=((abs(x1(i,1)-x2(:,1)))./ts).^2 + ...
		((abs(x1(i,2)-x2(:,2)))./gs).^2;
	a(i,:)=exp(-tmp1');
end

