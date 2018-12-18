function options = optimset(varargin)
%OPTIMSET Create/alter OPTIM OPTIONS structure.
%   OPTIONS = OPTIMSET('PARAM1',VALUE1,'PARAM2',VALUE2,...) creates an
%   optimization options structure OPTIONS in which the named parameters have
%   the specified values.  Any unspecified parameters are set to [] (parameters
%   with value [] indicate to use the default value for that parameter when 
%   OPTIONS is passed to the optimization function). It is sufficient to type 
%   only the leading characters that uniquely identify the parameter.  Case is 
%   ignored for parameter names.  
%   NOTE: For values that are strings, correct case and the complete string  
%   are required; if an invalid string is provided, the default is used.
%   
%   OPTIONS = OPTIMSET(OLDOPTS,'PARAM1',VALUE1,...) creates a copy of OLDOPTS 
%   with the named parameters altered with the specified values.
%   
%   OPTIONS = OPTIMSET(OLDOPTS,NEWOPTS) combines an existing options structure
%   OLDOPTS with a new options structure NEWOPTS.  Any parameters in NEWOPTS
%   with non-empty values overwrite the corresponding old parameters in 
%   OLDOPTS. 
%   
%   OPTIMSET with no input arguments and no output arguments displays all 
%   parameter names and their possible values, with defaults shown in {} 
%   when the default is the same for all functions that use that option -- use
%   OPTIMSET(OPTIMFUNCTION) to see options for a specific function.).
%
%   OPTIONS = OPTIMSET (with no input arguments) creates an options structure
%   OPTIONS where all the fields are set to [].
%
%   OPTIONS = OPTIMSET(OPTIMFUNCTION) creates an options structure with all
%   the parameter names and default values relevant to the optimization
%   function named in OPTIMFUNCTION. For example,
%           optimset('fminbnd') 
%   or
%           optimset(@fminbnd)
%   returns an options structure containing all the parameter names and  
%   default values relevant to the function 'fminbnd'.
%   
%OPTIMSET PARAMETERS
%DerivativeCheck - Compare user supplied derivatives (gradients or Jacobian)
%                  to finite-differencing derivatives  [ on | {off}]
%Diagnostics - Print diagnostic information about the function to be 
%              minimized or solved [ on | {off}]
%DiffMaxChange - Maximum change in variables for finite difference gradients
%              [ positive scalar  | {1e-1} ]
%DiffMinChange - Minimum change in variables for finite difference gradients
%              [ positive scalar  | {1e-8} ]
%Display - Level of display [ off | iter | notify | final ]  
%GoalsExactAchieve - Number of goals to achieve exactly (do not over- or
%                    under-achieve) [ positive scalar integer | {0}]
%GradConstr - Gradients for the nonlinear constraints defined by user
%                    [ on | {off} ]
%GradObj - Gradient(s) for the objective function(s) defined by user
%                    [ on | {off}]
%Hessian - Hessian for the objective function defined by user  [ on | {off} ]
%HessMult - Hessian multiply function defined by user
%                    [ function | {[]} ]
%HessPattern - Sparsity pattern of the Hessian for finite-differencing
%              [ sparse matrix ]
%HessUpdate - Quasi-Newton updating scheme 
%             [ {bfgs} | dfp | gillmurray | steepdesc ] 
%Jacobian - Jacobian for the objective function defined by user
%                    [ on | {off}]
%JacobMult - Jacobian multiply function defined by user
%                    [ function | {[]} ]
%JacobPattern - Sparsity pattern of the Jacobian for finite-differencing
%               [ sparse matrix ]
%LargeScale - Use large-scale algorithm if possible [ {on} | off ]
%LevenbergMarquardt - Chooses Levenberg-Marquardt over Gauss-Newton algorithm
%                     [ on | off]
%LineSearchType - Line search algorithm choice [ cubicpoly | {quadcubic} ]
%MaxFunEvals - Maximum number of function evaluations allowed 
%                     [ positive integer ]
%MaxIter - Maximum number of iterations allowed [ positive integer ]
%MaxPCGIter - Maximum number of PCG iterations allowed [positive integer]
%MeritFunction - Use goal attainment/minimax merit function 
%                     [ {multiobj} | singleobj ]
%MinAbsMax - Number of F(x) to minimize the worst case absolute values
%                     [ positive scalar integer | {0} ]
%PrecondBandWidth - Upper bandwidth of preconditioner for PCG 
%                    [ positive integer | Inf | {0} ]
%TolCon - Termination tolerance on the constraint violation [ positive scalar ]
%TolFun - Termination tolerance on the function value [ positive scalar ]
%TolPCG - Termination tolerance on the PCG iteration 
%         [ positive scalar | {0.1} ]
%TolX - Termination tolerance on X [ positive scalar ]
%TypicalX - Typical X values [ vector ]
%
%   See also OPTIMGET, FZERO, FMINBND, FMINSEARCH.

% Future options (to be implemented):
%
%ActiveConstrTol - The tolerance used to determine which constraints are
%                  active for the interior-point methods at algorithm 
%                  end [ positive scalar ]
%OutputFcn - Name of installable output function  [ string ]
%   This output function is called by the solver after each time step.  When
%   a solver is called with no output arguments, OutputFcn defaults to
%   'optimplot'.  Otherwise, OutputFcn defaults to ''
%Preconditioner - Alternative preconditioning function for PCG [ string ] 
%ShowStatusWindow - Show window of performance statistics
%MaxSQPIter - Maximum number of SQP iteration allowed [positive integer]

%   Copyright 1984-2002 The MathWorks, Inc. 
%   $Revision: 1.34 $  $Date: 2002/05/14 19:21:42 $

% Print out possible values of properties.
if (nargin == 0) & (nargout == 0)
    fprintf('        DerivativeCheck: [ on | {off} ]\n');
    fprintf('            Diagnostics: [ on | {off} ]\n');
    fprintf('          DiffMaxChange: [ positive scalar {1e-1} ]\n');
    fprintf('          DiffMinChange: [ positive scalar {1e-8} ]\n');
    fprintf('                Display: [ off | iter | notify | final ]\n');
    fprintf('      GoalsExactAchieve: [ positive scalar | {0} ]\n');
    fprintf('             GradConstr: [ on | {off} ]\n');
    fprintf('                GradObj: [ on | {off} ]\n');
    fprintf('                Hessian: [ on | {off} ]\n');
    fprintf('               HessMult: [ function | {[]} ]\n');
    fprintf('            HessPattern: [ sparse matrix | {sparse(ones(NumberOfVariables))} ]\n');
    fprintf('             HessUpdate: [ dfp | gillmurray | steepdesc | {bfgs} ]\n');
    fprintf('               Jacobian: [ on | {off} ]\n');
    fprintf('              JacobMult: [ function | ([]) ]\n');
    fprintf('           JacobPattern: [ sparse matrix | {sparse(ones(Jrows,Jcols))} ]\n');
    fprintf('             LargeScale: [ {on} | off ]\n');
    fprintf('     LevenbergMarquardt: [ on | off ]\n');
    fprintf('         LineSearchType: [ cubicpoly | {quadcubic} ]\n');
    fprintf('            MaxFunEvals: [ positive scalar ]\n');
    fprintf('                MaxIter: [ positive scalar ]\n');
    fprintf('             MaxPCGIter: [ positive scalar | {max(1,floor(numberOfVariables/2))}]\n');
    fprintf('          MeritFunction: [ singleobj | multiobj ]\n');
    fprintf('              MinAbsMax: [ positive scalar | {0} ]\n');
    fprintf('       NonlEqnAlgorithm: [ {dogleg} | lm | gn ]\n');
    fprintf('       PrecondBandWidth: [ positive scalar | {0} | Inf ]\n');
    fprintf('                 TolCon: [ positive scalar ]\n');
    fprintf('                 TolFun: [ positive scalar ]\n');
    fprintf('                 TolPCG: [ positive scalar | {0.1} ]\n');
    fprintf('                   TolX: [ positive scalar ]\n')
    fprintf('               TypicalX: [ vector | {ones(NumberOfVariables,1)} ]\n');
    fprintf('\n');
    return;
end

options = struct(  'ActiveConstrTol', [], ...
    'DerivativeCheck', [], ...
    'Diagnostics', [], ...
    'DiffMaxChange', [], ...
    'DiffMinChange', [], ...
    'Display', [], ...
    'GoalsExactAchieve', [], ...
    'GradConstr', [], ...
    'GradObj', [], ...
    'Hessian', [], ...
    'HessMult', [], ...
    'HessPattern', [], ...
    'HessUpdate', [], ...
    'Jacobian', [], ...
    'JacobMult', [], ...
    'JacobPattern', [], ...
    'LargeScale', [], ...
    'LevenbergMarquardt', [], ...
    'LineSearchType', [], ...
    'MaxFunEvals', [], ...
    'MaxIter', [], ...
    'MaxPCGIter', [], ...
    'MaxSQPIter', [], ...
    'MeritFunction', [], ...
    'MinAbsMax', [], ...
    'NonlEqnAlgorithm', [], ...
    'Preconditioner', [], ...
    'PrecondBandWidth', [], ...
    'ShowStatusWindow', [], ...
    'TolCon', [], ...
    'TolFun', [], ...
    'TolPCG', [], ...
    'TolX', [], ...
    'TypicalX', []);

numberargs = nargin; % we might change this value, so assign it

% If we pass in a function name then return the defaults.
if (numberargs==1) & (ischar(varargin{1}) | isa(varargin{1},'function_handle') )
    if ischar(varargin{1})
        funcname = lower(varargin{1});
        if ~exist(funcname)
            msg = sprintf(...
                'No default options available: the function ''%s'' does not exist on the path.',funcname);
            error(msg)
        end
    elseif isa(varargin{1},'function_handle')
        funcname = func2str(varargin{1});
    end
    try 
        optionsfcn = feval(varargin{1},'defaults');
    catch
        msg = sprintf(...
            'No default options available for the function ''%s''.',funcname);
        error(msg)
    end
    % To get output, run the rest of optimset as if called with optimset(options, optionsfcn)
    varargin{1} = options;
    varargin{2} = optionsfcn;
    numberargs = 2;
end

Names = fieldnames(options);
[m,n] = size(Names);
names = lower(Names);

i = 1;
while i <= numberargs
    arg = varargin{i};
    if isstr(arg)                         % arg is an option name
        break;
    end
    if ~isempty(arg)                      % [] is a valid options argument
        if ~isa(arg,'struct')
            error(sprintf(['Expected argument %d to be a string parameter name ' ...
                    'or an options structure\ncreated with OPTIMSET.'], i));
        end
        for j = 1:m
            if any(strcmp(fieldnames(arg),Names{j,:}))
                val = arg.(Names{j,:});
            else
                val = [];
            end
            if ~isempty(val)
                if ischar(val)
                    val = lower(deblank(val));
                end
                [valid, errmsg] = checkfield(Names{j,:},val);
                if valid
                    options.(Names{j,:}) = val;
                else
                    error(errmsg);
                end
            end
        end
    end
    i = i + 1;
end

% A finite state machine to parse name-value pairs.
if rem(numberargs-i+1,2) ~= 0
    error('Arguments must occur in name-value pairs.');
end
expectval = 0;                          % start expecting a name, not a value
while i <= numberargs
    arg = varargin{i};
    
    if ~expectval
        if ~isstr(arg)
            error(sprintf('Expected argument %d to be a string parameter name.', i));
        end
        
        lowArg = lower(arg);
        j = strmatch(lowArg,names);
        if isempty(j)                       % if no matches
            error(sprintf('Unrecognized parameter name ''%s''.', arg));
        elseif length(j) > 1                % if more than one match
            % Check for any exact matches (in case any names are subsets of others)
            k = strmatch(lowArg,names,'exact');
            if length(k) == 1
                j = k;
            else
                msg = sprintf('Ambiguous parameter name ''%s'' ', arg);
                msg = [msg '(' Names{j(1),:}];
                for k = j(2:length(j))'
                    msg = [msg ', ' Names{k,:}];
                end
                msg = sprintf('%s).', msg);
                error(msg);
            end
        end
        expectval = 1;                      % we expect a value next
        
    else           
        if ischar(arg)
            arg = lower(deblank(arg));
        end
        [valid, errmsg] = checkfield(Names{j,:},arg);
        if valid
            options.(Names{j,:}) = arg;
        else
            error(errmsg);
        end
        expectval = 0;
    end
    i = i + 1;
end

if expectval
    error(sprintf('Expected value for parameter ''%s''.', arg));
end

%-------------------------------------------------
function [valid, errmsg] = checkfield(field,value)
%CHECKFIELD Check validity of structure field contents.
%   [VALID, MSG] = CHECKFIELD('field',V) checks the contents of the specified
%   value V to be valid for the field 'field'. 
%


valid = 1;
errmsg = '';
% empty matrix is always valid
if isempty(value)
    return
end

switch field
case {'TolFun','TolCon','TolPCG','ActiveConstrTol',...
            'DiffMaxChange','DiffMinChange'} % real scalar
    if ~(isa(value,'double') & value >= 0) ...
        valid = 0;
        if ischar(value)
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number (not a string).',field);
        else
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number.',field);
        end
    end
case {'TolX'} % real scalar
    if ~(isa(value,'double') & value >= 0) ...
            & ~isequal(value,'10*eps*norm(c,1)*length(c)')
        valid = 0;
        if ischar(value)
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number (not a string).',field);
        else
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number.',field);
        end
    end
case {'LargeScale','DerivativeCheck','Diagnostics','GradConstr','GradObj',...
            'Hessian','Jacobian','LevenbergMarquardt'} % off, on
    if ~isa(value,'char') | ~any(strcmp(value,{'on';'off'}))
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be ''off'' or ''on''.',field);
    end
case {'Display'} % off,none,iter,final,notify,testing
    if ~isa(value,'char') | ~any(strcmp(value,{'on';'off';'none';'iter';'final';'notify';'testing';'simplex'}))
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be ''off'',''on'',''iter'',''notify'', or ''final''.',field);
    end
case {'MaxIter'} % integer including inf
    if ~(isa(value,'double') & value >= 0) ...
            & ~isequal(value, '200*numberofvariables')
        valid = 0;
        if ischar(value)
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number (not a string).',field);
        else
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number.',field);
        end
    end
case {'MaxFunEvals'} % integer including inf or default string
        if ~(isa(value,'double') & value >= 0) ...
            & ~isequal(value,'100*numberofvariables') ...
            & ~isequal(value, '200*numberofvariables') 
        valid = 0;
        if ischar(value)
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number (not a string).',field);
        else
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number.',field);
        end
    end
case {'PrecondBandWidth','MinAbsMax','GoalsExactAchieve'} % integer including inf
      if ~(isa(value,'double') & value >= 0) ...
        valid = 0;
        if ischar(value)
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number (not a string).',field);
        else
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number.',field);
        end
    end
case {'MaxPCGIter'} % integer including inf or default string
     if ~(isa(value,'double') & value >= 0) ...
 & ~isequal(value,'max(1,floor(numberofvariables/2))') & ~isequal(value,'numberofvariables') 
        valid = 0;
        if ischar(value)
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number (not a string).',field);
        else
            errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number.',field);
        end
    end
case {'MaxSQPIter'} % integer including inf 
     if ~(  (isa(value,'double') & value >= 0) | ischar(value) ) 
        valid = 0;
		errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real positive number.',field);
    end
case  {'JacobPattern'}  % matrix or default string
    if ~isa(value,'double') & ~isequal(value,'sparse(ones(jrows,jcols))')
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a matrix.',field);
    end
case  {'HessPattern'}  % matrix or default string
    if ~isa(value,'double') & ~isequal(value,'sparse(ones(numberofvariables))')
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a matrix.',field);
    end
case  {'TypicalX'}  % matrix or default string
    if ~isa(value,'double') & ~isequal(value,'ones(numberofvariables,1)')
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a matrix.',field);
    end
case {'HessMult','JacobMult','Preconditioner'}% function
    if ~isa(value,'char') & ~isa(value,'function_handle')
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a function.',field);
    end
case  'HessUpdate'
    if ~isa(value,'char') | ~any(strcmp(value,{'dfp' ; 'gillmurray'; 'steepdesc';'bfgs'}))
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: \n must be ''bfgs'', ''gillmurray'', ''dfp'', or ''steepdesc''.',field);
    end
case  'NonlEqnAlgorithm'
    if ~isa(value,'char') | ~any(strcmp(value,{'dogleg' ; 'lm'; 'gn'}))
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: \n must be ''dogleg'', ''lm'', or ''gn''.',field);
    end
case    'LineSearchType'
    if ~isa(value,'char') | ~any(strcmp(value,{'cubicpoly' ; 'quadcubic' }))
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be ''cubicpoly'' or ''quadcubic'' .',field);
    end
case    'MeritFunction'
    if ~isa(value,'char') | ~any(strcmp(value,{'singleobj'; 'multiobj' }))
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be ''singleobj'' or ''multiobj'' .',field);
    end
case    'ShowStatusWindow'
    if ~isa(value,'char') | ~any(strcmp(value,{'on';'off';'none';'iter';'final';'iterplus'}))
        valid = 0;
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be ''off'',''on'',''iter'', ''iterplus'', or ''final''.',field);
    end
otherwise
    valid = 0;
    error('Unknown field name for Options structure.')
end