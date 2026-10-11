function model = FitRecursiveVAR(y, quarters, settings)
% VAR with intercept and optional quarterly deterministic controls.
% IRFs hold deterministic regressors fixed. Bootstrap preserves their calendar.
[N,n] = size(y); p=settings.p; H=settings.H; B=settings.bootstrap;
inflationIndex=4;
if isfield(settings,'inflationIndex'), inflationIndex=settings.inflationIndex; end
assert(numel(quarters)==N && all(diff(quarters)==1), 'Invalid quarterly calendar.');
assert(all(isfinite(y(:))), 'Non-finite data.');
D = ones(N,1);
if settings.seasonal
    q = mod(quarters(:),4);
    D = [D, double(q==0), double(q==1), double(q==2)]; % Q4 reference
end
rows=true(N-p,1);
if isfield(settings,'excludedQuarters') && ~isempty(settings.excludedQuarters)
    assert(B==0, 'Exclusion sensitivity is point-estimate only.');
    % Drop equations whose dependent variable OR any lag touches the excluded
    % quarter. Never concatenate the surviving observations into a false calendar.
    for lag=0:p
        rows=rows & ~ismember(quarters(p+1-lag:N-lag),settings.excludedQuarters);
    end
end
[coef,residuals,A,Sigma,X] = estimate(y,D,p,rows);
model.maxRoot = max(abs(eig(A)));
model.effectiveN = sum(rows);
if model.maxRoot>=1 && isfield(settings,'returnUnstable') && settings.returnUnstable
    assert(B==0, 'Unstable point estimates can only be returned for diagnostics.');
    model.irf=[];
    return;
end
assert(model.maxRoot<1, 'FitRecursiveVAR:Unstable', ...
    'Point estimate is unstable (root %.6f); inspect this specification.', model.maxRoot);
model.irf = responses(A,Sigma,H,n);
model.cumulative = model.irf;
model.cumulative(inflationIndex,:,:) = cumsum(model.irf(inflationIndex,:,:),3);
model.bootstrap = zeros(n,n,H,B);
model.bootstrapRoots = zeros(B,1);
model.residuals = residuals;
model.coefficients = coef;
model.covariance = Sigma;
model.effectiveN = sum(rows);
model.retainedEquationQuarters = quarters(find(rows)+p);
model.regressors = size(X,2);
model.quarters = quarters;
model.settings = settings;
% Resampling entire residual vectors retains contemporaneous covariance.
residuals = residuals-mean(residuals,1);
for b=1:B
    simulated = y;
    innovations = residuals(randi(N-p,N-p,1),:);
    for t=p+1:N
        lag = reshape(simulated(t-1:-1:t-p,:)',1,[]);
        simulated(t,:) = [D(t,:),lag]*coef + innovations(t-p,:);
    end
    [~,~,Ab,Sb] = estimate(simulated,D,p,true(N-p,1));
    model.bootstrapRoots(b) = max(abs(eig(Ab)));
    % Retain unstable finite-horizon draws; report them instead of silently filtering.
    model.bootstrap(:,:,:,b) = responses(Ab,Sb,H,n);
end
model.unstableDraws = sum(model.bootstrapRoots>=1);
assert(all(isfinite(model.bootstrap(:))), 'Non-finite bootstrap responses.');
model.bootstrapCumulative = model.bootstrap;
model.bootstrapCumulative(inflationIndex,:,:,:) = cumsum(model.bootstrap(inflationIndex,:,:,:),3);
[model.fevd,model.fevdByHorizon] = fevd(model.irf,1:H,model.irf,[],[],0,"");
[model.fevdCumulative,model.fevdCumulativeByHorizon] = ...
    fevd(model.cumulative,1:H,model.cumulative,[],[],0,"");
end

function [coef,residuals,A,Sigma,X] = estimate(y,D,p,rows)
[N,n] = size(y); X = D(p+1:end,:);
for lag=1:p, X=[X,y(p+1-lag:N-lag,:)]; end %#ok<AGROW>
target=y(p+1:end,:); X=X(rows,:); target=target(rows,:);
assert(size(X,1)>size(X,2) && rank(X)==size(X,2), 'Insufficient or rank-deficient sample.');
coef = X\target;
residuals = target-X*coef;
% Preserve the legacy T-1 normalisation for a clean specification comparison.
Sigma = cov(residuals);
A = [coef(size(D,2)+1:end,:)'; eye(n*(p-1)),zeros(n*(p-1),n)];
end

function irf = responses(A,Sigma,H,n)
L=chol(Sigma,'lower'); irf=zeros(n,n,H); power=eye(size(A));
for h=1:H
    irf(:,:,h)=power(1:n,1:n)*L;
    power=power*A;
end
end
