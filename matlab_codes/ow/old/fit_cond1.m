function [xfit, condslope, condslope_err, time_deriv, time_deriv_err, sta_mean, ...
    sta_rms, NDF, fit_coef, fit_breaks] = fit_cond(x,y,n_err,lvcov,varargin,fname)
if nargin < 4
    disp('FIT_COND inputs must have at least 4 arguments')
    return
end
global A breaks nbr1 ubrk_g
global xf yf W_i xblim
max_brk_dflt = 4; % default maximum number of break points
max_brk_in = [];
max_brk = [];
nbr1 = -1; % 1st break to consider
brk_init = []; % initial guess for the break points
setbreaks = 0;
nloops = 200;  %Number of loops for the profile fit error
MaxFunEvals = 1000; % maximum function calls
TolFun = 1e-6; % convergence criteria for lsqnonlin
xfit = unique(x);
nfit = length(xfit);
good = find(isfinite(y) & isfinite(x));
x = x(good);
y = y(good);
n_err = n_err(good);
lvcov = lvcov(good,good);
npts = length(x);
if npts == 0 % we failed to find a single good point
    disp('WARNING fit_cond called with no valid data points')
    xp = [];
    condslope      =NaN;
    condslope_err  =NaN;
    time_deriv     =NaN;
    time_deriv_err =NaN;
    sta_mean       =NaN;
    sta_rms        =NaN;
    NDF            =[];
    fit_coef       =[];
    fit_breaks     =[];
    return
end
[x,i] = sort(x);
y = y(i);
n_err = n_err(i);
lvcov = lvcov(i,i);
x = reshape(x,npts,1);
y = reshape(y,npts,1);
n_err = reshape(n_err,npts,1);
x0 = (x(npts)+x(1))/2.;
if x(1) ~= x(npts)
    xscale = (x(npts)-x(1))/2.;
else
    xscale = 1;
end
% remove mean of y and scale y by the standard deviation
y0 = mean(y);
yscale = std(y,1);
if yscale == 0
    yscale = 1;
end
xf = (x-x0)/xscale;
yf = (y-y0)/yscale;
n_err =  n_err/yscale;
xfit = (xfit-x0)/xscale;
[xp,ip] = unique(xf);
nprof = length(xp);
err_var = (n_err).^2; % convert errors from rms to variance
W_i = diag(mean(err_var)./err_var); % weights for weighted Least-squares
NDF = sum(ones(npts,1) ./ (lvcov*ones(npts,1)));
RSS0 = sum(((yf).^2) ./err_var);
if length(xp) > 3
    % find 2nd and next to last profile and use them as limits for the break points
    xblim = [xp(2) xp(nprof-1)];
else
    xblim = [1 1]; % should never be used in this case, ie too few profiles
end
nvarargin = length(varargin);
if rem(nvarargin,2) ~= 0
    disp('FIT_COND - Input must be in the form:')
    disp('x, y, error, parameter, value, ...')
    help fit_cond
    return
end
if nvarargin > 0
    for n=1:nvarargin/2
        parm = varargin(2*(n-1)+1);
        value = varargin(2*n);
        if ~iscellstr(parm)
            disp('FIT_COND - Input must be in the form:')
            disp('flt, parameter, value, ...')
            disp('where parameter is a string')
            help fit_cond
            return
        end
        % find parm in list
        param = lower(char(parm));
        switch param
            case {'initial_breaks'},
                % initial guess for break points included as input
                brk_init = value{:};
                % convert to rescaled units
                brk_init = (brk_init-x0)/xscale;
                brk_init = (brk_init-xblim(1))/diff(xblim);
            case {'max_no_breaks'},
                if ~isempty(value{:})
                    max_brk_in = value{:};
                    nbr1 = -1;
                end
            case {'number_breaks'},
                pbrk = value{:};
                nbr1 = pbrk;
                max_brk_in = pbrk;
            case {'nloops'},
                nloops = value{:};
            case { 'breaks'}
                if ~isempty(value{:})
                    breaks=value{:};
                    breaks = (breaks-x0)/xscale;
                    nbr = length(breaks);
                    setbreaks=1;
                end
            otherwise,
                disp(['FIT_COND: Parameter ' param ' not found in parameter list'])
        end % end switch
    end
end
b_pts = ones(max_brk_in,max_brk_in+1)*NaN;% break points, add one to allow for 1st point
b_A = ones(max_brk_in+2,max_brk_in+1)*NaN;% parameters of piece-wise linear fit
RSS = ones(1,max_brk_in+2)*NaN; % residual sum of squares
AIC = ones(1,max_brk_in+2)*NaN; % AICc test to choose optimal fit
if setbreaks % we have set breaks, now check to see range of break points to be tested
    if isempty(max_brk_in) % we have only specified break points
        max_brk_in = nbr;
        nbr1 = nbr;
    elseif max_brk_in > nbr % we have specified some breaks that are to be fixed
        nbr1 = nbr+1; % do fit possible breaks as those specified up to the maximum number of breaks
        % get fit with specified breaks
        [A, residual] = brk_pt_fit (xf, yf, W_i, breaks);
        b_pts(1:nbr,nbr+1) = breaks';
        b_A(1:nbr+2,nbr+2) = A(1:nbr+2);
        RSS(nbr+2) = sum(residual.^2 ./ err_var);
        p = 2*(nbr+1); % number of parameters
        AIC(nbr+2) = NDF*log(RSS(nbr+2)/npts) + NDF*(NDF+p)./(NDF-p-2);
    else
        nbr1 = nbr; % we have specified same numbr of breaks as specified or made an error entering the break points
    end
    max_brk = max_brk_in;
    pbrk = nbr1:max_brk;
else % no break points entered
    if isempty(max_brk_in); % no max break points set
        max_brk_in = max_brk_dflt; % set maximum break points to default
    end
    max_brk = max_brk_in;
    pbrk = nbr1:max_brk;
end
if nprof < 6
    disp(['WARNING: Only have ' num2str(nprof) ' good profiles, will estimate offset only'])
    pbrk = -1;
end
for nbr = pbrk
    if nbr == -1 || nbr==0
    else
        nbr2 = length(brk_init);
        if length(brk_init) >= nbr % there are enough initial guesses for break points
            [m n]= size(brk_init);
            if (m>n) brk_init = brk_init'; end
            b_guess = brk_init(1:nbr);
        else
            b_guess = -1+2*(1:nbr)/(nbr+1);
        end
        b_g = [-1 b_guess];
        clear ubrk_g
        ubrk_g(1:nbr)=log((b_g(2:nbr+1)-b_g(1:nbr))/(1-b_g(nbr+1)));
        if setbreaks || nbr1 == max_brk;  % break points are set get linear-lsq fit to offset and slopes
        else % we are supposed to fit over a limited number of breaks
            try
                stru(nbr).ubrk_g=ubrk_g;
                stru(nbr).MaxFunEvals=MaxFunEvals;
                stru(nbr).TolFun=TolFun;
                stru(nbr).command='[ubrk, resnorm, residual] = nonlinlsq (@nlbpfun, ubrk_g, [],[], optimset(''DISPLAY'',''off'',''MaxFunEvals'',MaxFunEvals,''TolFun'',TolFun));';
            catch % if error in lsqnonlin get last iteration
                stru(nbr).ubrk_g=ubrk_g;
                stru(nbr).command='[ubrk resnorm residual] = LMA(ubrk_g);';
            end
            ubrk = [ubrk_g(1:nbr1-1) ubrk];
        end
    end
end
save(fname,'stru');