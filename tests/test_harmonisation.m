function tests=test_harmonisation
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(root,'src'))); t.TestData.root=root;
end
function testGrowthConversion(t)
d=LoadAnalysisData(t.TestData.root,true);
old=LoadAnalysisData(t.TestData.root,false);
verifyEqual(t,d.usa(:,2),100*log1p(old.usa(:,2)/100),'AbsTol',1e-10);
verifyEqual(t,d.usa(:,6)+d.usa(:,2),100*log1p((old.usa(:,6)+old.usa(:,2))/100),'AbsTol',1e-10);
verifyEqual(t,d.eu(1,4),100*log(79.49/79.02),'AbsTol',1e-10);
verifyEqual(t,d.eu(:,5),old.eu(:,5),'AbsTol',1e-8);
verifyEqual(t,d.quarters,old.quarters);
end
function testSeasonalEstimationAndBootstrap(t)
rng(7); N=120; quarters=(8000:8000+N-1)'; y=zeros(N,4);
for i=2:N
    y(i,:)=0.3*y(i-1,:)+2*(mod(quarters(i),4)==0)+randn(1,4);
end
s=struct('p',1,'H',8,'bootstrap',5,'seasonal',true);
m=FitRecursiveVAR(y,quarters,s);
verifyEqual(t,m.regressors,8);
verifyEqual(t,m.effectiveN,119);
verifySize(t,m.bootstrap,[4,4,8,5]);
verifyEqual(t,sum(m.fevd,2),100*ones(4,1),'AbsTol',1e-9);
verifyEqual(t,m.bootstrapCumulative(4,:,:,:),cumsum(m.bootstrap(4,:,:,:),3));
% Direct OLS with the known quarterly calendar is an independent design check.
q=mod(quarters(2:end),4);
X=[ones(N-1,1),q==0,q==1,q==2,y(1:end-1,:)];
verifyEqual(t,m.coefficients,X\y(2:end,:),'AbsTol',1e-10);
end
function testLegacyEstimatorAgreement(t)
d=LoadAnalysisData(t.TestData.root,false);
s=struct('p',2,'H',20,'bootstrap',0,'seasonal',false);
m=FitRecursiveVAR(d.usa,d.quarters,s);
[r,~]=CholeskyIdentification(d.usa,2,20,1,1,4,0,strings(1,7),0,'',[16,84]);
verifyEqual(t,m.irf,r,'AbsTol',1e-8);
end

function testExcludedQuartersKeepCalendar(t)
rng(8); N=120; q=(8000:8119)'; y=randn(N,4);
s=struct('p',2,'H',8,'bootstrap',0,'seasonal',true,'excludedQuarters',q(50));
m=FitRecursiveVAR(y,q,s);
verifyEqual(t,m.effectiveN,N-2-3);
verifyFalse(t,any(ismember(q(50:52),m.retainedEquationQuarters)));
% Explicit complete lag matrix: only equations touching the source quarter drop.
quarter=mod(q(3:end),4);
X=[ones(N-2,1),quarter==0,quarter==1,quarter==2,y(2:end-1,:),y(1:end-2,:)];
Y=y(3:end,:); keep=~ismember(q(3:end),q(50:52));
verifyEqual(t,m.coefficients,X(keep,:)\Y(keep,:),'AbsTol',1e-10);
end

function testInflationIndexFollowsOrdering(t)
rng(9); q=(8000:8119)'; y=randn(120,4);
s=struct('p',1,'H',8,'bootstrap',3,'seasonal',true,'inflationIndex',2);
m=FitRecursiveVAR(y,q,s);
verifyEqual(t,m.cumulative(2,:,:),cumsum(m.irf(2,:,:),3));
verifyEqual(t,m.cumulative(4,:,:),m.irf(4,:,:));
verifyEqual(t,m.bootstrapCumulative(2,:,:,:),cumsum(m.bootstrap(2,:,:,:),3));
end

function testUnstableSensitivityIsFlagged(t)
rng(11); q=(8000:8079)'; y=zeros(80,4);
for i=2:80, y(i,:)=1.06*y(i-1,:)+randn(1,4); end
s=struct('p',1,'H',8,'bootstrap',0,'seasonal',false,'returnUnstable',true);
m=FitRecursiveVAR(y,q,s);
verifyGreaterThanOrEqual(t,m.maxRoot,1);
verifyEqual(t,m.effectiveN,79);
verifyEmpty(t,m.irf);
s.returnUnstable=false;
verifyError(t,@() FitRecursiveVAR(y,q,s),'FitRecursiveVAR:Unstable');
end
