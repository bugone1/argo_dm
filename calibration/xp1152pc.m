function varargout=xp1152pc(varargin)
for i=1:nargin
    [out,in]=deal(varargin{i});
    fn=fieldnames(in);    
    for j=1:length(fn)
        tex=in.(fn{j});
        ok1=strfind(tex,'/u01/rapps');
        if ~isempty(ok1) 
            tex=tex(9:end);
            tex(1:2)='w:';
        end
        out.(fn{j})=bcksl2sl(tex);        
    end
    varargout{i}=out;
    clear out
end