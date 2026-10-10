function data = LoadAnalysisData(root, harmonise)
% Read workbook dates rather than relying on spreadsheet row positions.
% harmonise=false reproduces the date-aligned legacy transformations.
if nargin<2, harmonise=true; end
[qe, e] = readQuarterly(fullfile(root, 'data', 'input', 'dataset_eu_BEAR_nodummy.xlsx'), 6);
[ql, levels] = readQuarterly(fullfile(root, 'data', 'input', 'dataset_eu.xlsx'), 10);
[qu, u] = readQuarterly(fullfile(root, 'data', 'input', 'dataset_usa.xlsx'), 7);
startQuarter = 4*2002 + 1; % 2002Q2
qeMask = qe >= startQuarter;
qe = qe(qeMask); e = e(qeMask,:);
assert(all(diff(qe)==1), 'EA prepared data have missing quarters.');
[found, current] = ismember(qe, ql);
[previousFound, previous] = ismember(qe-1, ql);
assert(all(found & previousFound), 'Missing current or previous EA GDP quarter.');
gdp = levels(current,5); gdpPrevious = levels(previous,5);
assert(all(isfinite(gdp) & gdp>0 & isfinite(gdpPrevious) & gdpPrevious>0), ...
    'EA real GDP must be finite and positive.');
eu = [e(:,1), 100*log(gdp./gdpPrevious), e(:,2:end)];
if harmonise
    % B:K = M3, rate, HICP, nominal GDP, real GDP, income, UR, oil, FISC, EGM.
    now = levels(current,:); before = levels(previous,:);
    positiveColumns = [1,3,4,5,6,8];
    assert(all(all(isfinite(now(:,positiveColumns)) & now(:,positiveColumns)>0)) && ...
        all(all(isfinite(before(:,positiveColumns)) & before(:,positiveColumns)>0)), ...
        'EA levels needed for log growth must be finite and positive.');
    growth = 100*log(now(:,positiveColumns)./before(:,positiveColumns));
    eu = [growth(:,6), growth(:,4), now(:,7), growth(:,2), ...
        growth(:,5)-growth(:,3), growth(:,1)-growth(:,4), now(:,2)];
end

% The first US quarter provides the previous fiscal ratio, not an estimation row.
usMask = qu >= 4*1979 & qu <= qe(end);
quFull = qu(usMask); us = u(usMask,:);
[found, previous] = ismember(quFull-1, qu);
assert(all(found), 'Missing previous quarter for US fiscal growth.');
ratios = us(:,5); previousRatios = u(previous,5);
assert(all(isfinite(ratios) & ratios>0 & isfinite(previousRatios) & previousRatios>0), ...
    'US income/GDP ratios must be finite and positive.');
us(:,5) = 100*log(ratios./previousRatios);
if harmonise
    % EGM is a difference of simple growth rates, so recover money growth first.
    moneyPch = us(:,6) + us(:,2);
    assert(all(all(us(:,[1,2,4])>-100)) && all(moneyPch>-100), ...
        'Simple growth must exceed -100 percent for log conversion.');
    us(:,[1,2,4]) = 100*log1p(us(:,[1,2,4])/100);
    us(:,6) = 100*log1p(moneyPch/100)-us(:,2);
end

[quarters, ie, iu] = intersect(qe, quFull);
assert(~isempty(quarters) && quarters(1)==startQuarter, 'Missing sample start.');
assert(all(diff(quarters)==1), 'Common sample has missing quarters.');
data.quarters = quarters;
data.eu = eu(ie,:);
data.usa = us(iu,:);
data.pre2020 = quarters < 4*2020;
data.harmonisedGrowth = harmonise;
% Keep the same endpoint for the long-sample robustness comparison.
longMask = quFull <= quarters(end);
data.usaLong = us(longMask,:);
data.usaLongQuarters = quFull(longMask);
assert(all(diff(data.usaLongQuarters)==1), 'US long sample has missing quarters.');
data.incomeRatioEU = levels(current(ie),6)./levels(current(ie),4);
data.incomeRatioUSA = ratios(iu);
assert(all(isfinite(data.eu(:))) && all(isfinite(data.usa(:))) && ...
    all(isfinite(data.usaLong(:))), 'Non-finite model input.');
assert(all(isfinite(data.incomeRatioEU) & data.incomeRatioEU>0), 'Invalid EA income ratio.');
end

function [quarters, values] = readQuarterly(file, n)
cells = readcell(file, 'Sheet', 1);
quarters = []; values = zeros(0,n);
for row = 1:size(cells,1)
    date = cells{row,1};
    if isdatetime(date)
        q = 4*year(date) + floor((month(date)-1)/3);
    elseif ischar(date) || isstring(date)
        token = regexp(char(date), '^(\d{4})[Qq]([1-4])$', 'tokens', 'once');
        if ~isempty(token)
            q = 4*str2double(token{1}) + str2double(token{2})-1;
        else
            token = regexp(char(date), '^(\d{4})-(\d{2})-\d{2}$', 'tokens', 'once');
            if isempty(token), continue; end
            m = str2double(token{2});
            assert(m>=1 && m<=12, 'Invalid date in %s.', file);
            q = 4*str2double(token{1}) + floor((m-1)/3);
        end
    else
        continue;
    end
    v = nan(1,n);
    for col = 1:n
        item = cells{row,col+1};
        if isnumeric(item) && isscalar(item), v(col) = item; end
    end
    quarters(end+1,1) = q; %#ok<AGROW>
    values(end+1,:) = v; %#ok<AGROW>
end
assert(~isempty(quarters), 'No recognised dates in %s.', file);
assert(all(diff(quarters)>0), 'Dates must be unique and increasing in %s.', file);
end
