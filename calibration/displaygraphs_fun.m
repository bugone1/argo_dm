function displaygraphs_fun(floatPlotsDir,floatNum,FigNo)
% DISPLAYGRAPHS_FUN Display OW plots. Start by showing plot FigNo, then prompt
%   the user for the next plot to display
%   USAGE: displaygraphs(FigNo)
%   INPUTS: 
%       floatPlotsDir - Directory for float plots
%       floatNum - Float number
%       FigNo - Figure number. Default is fig. 4. An empty figure causes
%           the function to return without doing anything. FigNo=-1 just
%           displays the prompt without first displaying anything.
%   VERSION HISTORY:
%       May 2017: Current working version (no changes tracked)
%       4 Aug. 2017, Isabelle Gaboury: Added documentation, made into a
%           function, added the "-1" option. Default behaviour unchanged.

% Default is to show figure #4 (TS plot)
if nargin < 3
    FigNo=4; 
elseif FigNo==-1
    FigNo=input('Which Figure; 1-9? (other: calibrate, -1: next float)');
end

%examine figures to come to an opinion about the conductivity cell calibration
while ~isempty(FigNo) && FigNo<10 && FigNo>0 
    flnm=[floatPlotsDir floatNum '_' num2str(FigNo,'%1d') '.png'];
    ['New Plot: ' flnm ]
    if ~ispc
    system(['eog ' flnm ]);
    else
        system(flnm);
    end
    FigNo=input('Which Figure; 1-9? (other: calibrate, -1: next float)');
end

end