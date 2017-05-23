function [allfcns,msg] = fprefcnchk(funstr,caller,lenVarIn,gradflag)
%PREFCNCHK Pre- and post-process function expression for FUNCHK.
%   [ALLFCNS,MSG] = PREFUNCHK(FUNSTR,CALLER,lenVarIn,GRADFLAG) takes
%   the (nonempty) expression FUNSTR from CALLER with LenVarIn extra arguments,
%   parses it according to what CALLER is, then returns a string or inline
%   object in ALLFCNS.  If an error occurs, this message is put in MSG.
%
%   ALLFCNS is a cell array: 
%    ALLFCNS{1} contains a flag 
%    that says if the objective and gradients are together in one function 
%    (calltype=='fungrad') or in two functions (calltype='fun_then_grad')
%    or there is no gradient (calltype=='fun'), etc.
%    ALLFCNS{2} contains the string CALLER.
%    ALLFCNS{3}  contains the objective function
%    ALLFCNS{4}  contains the gradient function (transpose of Jacobian).
%  
%    NOTE: we assume FUNSTR is nonempty.
% Initialize
msg='';
allfcns = {};
funfcn = [];
gradfcn = [];
if gradflag
    calltype = 'fungrad';
else
    calltype = 'fun';
end
% {fun}
if isa(funstr, 'cell') & length(funstr)==1
    % take the cellarray apart: we know it is nonempty
    if gradflag
        calltype = 'fungrad';
    end
    [funfcn, msg] = fcnchk(funstr{1},lenVarIn);
    if ~isempty(msg)
        error(msg);
   end
    % {fun,[]}      
elseif isa(funstr, 'cell') & length(funstr)==2 & isempty(funstr{2})
    if gradflag
        calltype = 'fungrad';
    end
    [funfcn, msg] = fcnchk(funstr{1},lenVarIn);
    if ~isempty(msg)
        error(msg);
    end  
    % {fun, grad}   
elseif isa(funstr, 'cell') & length(funstr)==2 % and ~isempty(funstr{2})
    [funfcn, msg] = fcnchk(funstr{1},lenVarIn);
    if ~isempty(msg)
        error(msg);
    end  
    [gradfcn, msg] = fcnchk(funstr{2},lenVarIn);
    if ~isempty(msg)
        error(msg);
    end
    calltype = 'fun_then_grad';
    if ~gradflag
        warnstr = ...
            sprintf('%s\n%s\n%s\n','Jacobian function provided but OPTIONS.Jacobian=''off'';', ...
            '  ignoring Jacobian function and using finite-differencing.', ...
            '  Rerun with OPTIONS.Jacobian=''on'' to use Jacobian function.');
        warning(warnstr);
        calltype = 'fun';
    end   
elseif ~isa(funstr, 'cell')  %Not a cell; is a string expression, function name string, function handle, or inline object
    [funfcn, msg] = fcnchk(funstr,lenVarIn);
    if ~isempty(msg)
        error(msg);
    end   
    if gradflag % gradient and function in one function/M-file
        gradfcn = funfcn; % Do this so graderr will print the correct name
    end  
else
    errmsg = sprintf('%s\n%s', ...
        'FUN must be a function object or an inline object;', ...
        ' or, FUN may be a cell array that contains these type of objects.');
    error(errmsg)
end
allfcns{1} = calltype;
allfcns{2} = caller;
allfcns{3} = funfcn;
allfcns{4} = gradfcn;
allfcns{5}=[];