function tests = test_baseline
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(root,'src')));
testCase.TestData.root = root;
end

function testWorkbookAlignment(testCase)
d = LoadAnalysisData(testCase.TestData.root, false);
verifyEqual(testCase, d.quarters([1,end]), [4*2002+1;4*2025+2]);
verifySize(testCase, d.eu, [94,7]);
verifySize(testCase, d.usa, [94,7]);
verifyEqual(testCase, sum(d.pre2020), 71);
verifyEqual(testCase, d.usaLongQuarters(end), d.quarters(end));
% The fiscal difference must use the preceding quarter, not the next one.
verifyEqual(testCase, d.usa(1,5), 100*log(0.74222/0.73794), 'AbsTol',1e-10);
verifyEqual(testCase, d.eu(1,2), 100*log(2510322.77/2498701.77), 'AbsTol',1e-10);
end

function testKnownFEVD(testCase)
% At impact, variable 1 responds only to shock 1. At h=2, each contributes 1.
r = zeros(2,2,2); r(:,:,1) = eye(2); r(1,2,2) = 1;
[vd,vdk] = fevd(r,1:2,r,["a","b"],["a","b"],0,"");
verifyEqual(testCase, vd, [50,50;0,100], 'AbsTol',1e-12);
verifyEqual(testCase, reshape(vdk(1,1,:),1,[]), [100,0], 'AbsTol',1e-12);
rc = cumsum(r,3);
vc = fevd(rc,1:2,rc,["a","b"],["a","b"],0,"");
verifyEqual(testCase, vc(1,:), [200/3,100/3], 'AbsTol',1e-12);
end

function testRawAndCumulativeSeparation(testCase)
d = LoadAnalysisData(testCase.TestData.root, false);
labels = ["Oil","GDP","UR","Inflation","Income","Money","Rate"];
rng(42);
[raw,original,boot] = CholeskyIdentification(d.usa,2,20,1,5,4,0,labels,0,'',[16,84]);
verifyEqual(testCase, raw, original);
rng(42);
[cumulative,originalAgain,bootCumulative] = CholeskyIdentification(d.usa,2,20,1,5,4,1,labels,0,'',[16,84]);
verifyEqual(testCase, originalAgain, raw);
verifyEqual(testCase, cumulative(4,:,:), cumsum(raw(4,:,:),3));
verifyEqual(testCase, bootCumulative(4,:,:,:), cumsum(boot(4,:,:,:),3));
v = fevd(raw,1:20,raw,labels,labels,0,"");
vc = fevd(cumulative,1:20,cumulative,labels,labels,0,"");
verifyEqual(testCase, sum(v,2), 100*ones(7,1), 'AbsTol',1e-9);
verifyEqual(testCase, v(4,6), 6.09, 'AbsTol',0.02);
verifyEqual(testCase, vc(4,6), 21.34, 'AbsTol',0.02);
end
