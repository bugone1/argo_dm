function t=read_all_nc(dire,files,t,dokeep)
%Read all netCDF files within directory "dire" and stores them in structure
%"t"
%If a previous version of "t" existed:
% If dokeep(1)==1, Qc parms from struct t will be kept
% If dokeep(2)==1, other parms from struct t will be kept

for i=1:length(files)
    at(i)=read_nc([dire filesep files(i).name]);
end
if ~isempty(t)
    cyc1=cat(1,at.cycle_number);
    cyc2=cat(1,t.cycle_number);
    fn=fieldnames(t);
    for j=1:length(at)
        for i=1:length(fn)
            pos=strfind(fn{i},'_qc');
            ok=find(cyc2==cyc1(j));
            if ~isempty(pos) && ~dokeep(1)
                at(j).(fn{i})=t(ok).(fn{i});
            end
            if isempty(pos) && ~dokeep(2)
                at(j).(fn{i})=t(ok).(fn{i});
            end
        end        
    end
end
t=at;