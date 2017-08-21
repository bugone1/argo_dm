function varargout=agg_ocproc_stat(varargin)
nstat=[];
for i=1:nargin
    d{i}=dir([varargin{i} '*.mat']);
end
d=cat(1,d{:});d=char(d.name);
[inde1,inde2]=deal([]);
for i=1:size(d,1)
    tic;
    fname=deblank(d(i,:))
    load(fname,'stat');
    nstat=[nstat;stat];
    if nargout>1
        inde1=[inde1;i*ones(length(stat),1)];
        inde2=[inde2;(1:length(stat))'];
    end
    clear stat
    toc
end
varargout{1}=nstat;
if nargout>1
    inde=[inde1 inde2];
    varargout{2}=inde;
end
