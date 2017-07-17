function out=nanmean(in,dim)
% NANMEAN - Take the mean of a vector or matrix, excluding means. For a
%   vector this returns the scalar mean. For a matrix this returns the mean
%   along the specified dimension, or along the first dimension if none is
%   specified.
%   USAGE: out=nanmean(in,dim)
%   INPUTS: 
%       in - Input vector or matrix
%       dim - Dimension; if not specified, the same default is assumed as
%           for Matlab's sum function
%   OUTPUTS:
%       out - Mean with NaN's removed
%   VERSION HISTORY (only tracked as of May 2017):
%       11 July 2017, Isabelle Gaboury: Added the "dim" input, changed the
%           default behaviour for 2-dimensional matrices

% Default dimension. This causes sum to use its own default value
if nargin < 2, dim=[]; end

% Find the non-NaN values
ok=~isnan(in);
count = sum(ok,dim);

% Sum after setting NaNs to zero, divide by the count
in(~ok)=0;
out = sum(in,dim)./count;

% For cases where there are non non-NaN values, we reset to NaN
out(isinf(out))=nan;