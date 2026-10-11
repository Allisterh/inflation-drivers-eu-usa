function robustness=RunRobustness(data,settings)
% Point-estimate sensitivity, not a test of equality across countries.
s=settings; s.bootstrap=0; s.returnUnstable=true;
orders={1:7,[1,2,3,4,6,5,7],[1,2,3,4,5,7,6],[1,2,3,5,6,7,4]};
orderNames=["Baseline","Money before income","Rate before money","Inflation last"];
sampleNames=["Full sample","Pre-2020","Exclude 2020Q2","Exclude 2020"];
regions=["EA","USA"]; values={data.eu,data.usa}; summary=table; influence=table;
for r=1:2
    for sample=1:4
        y=values{r}; q=data.quarters; s.excludedQuarters=[];
        if sample==2, y=y(data.pre2020,:); q=q(data.pre2020); end
        if sample==3, s.excludedQuarters=4*2020+1; end
        if sample==4, s.excludedQuarters=4*2020+(0:3); end
        for o=1:numel(orders)
            order=orders{o}; s.inflationIndex=find(order==4);
            stats=fitStats(y(:,order),q,s,find(order==6));
            summary=[summary;table(regions(r),sampleNames(sample),orderNames(o), ...
                stats(1),stats(2),stats(3),stats(4),stats(5), ...
                'VariableNames',{'Region','Sample','Ordering','EGMInflation','EGMCumulative','MaxRoot','EffectiveN','Stable'})]; %#ok<AGROW>
        end
    end
    % Remove every individual source quarter, not just quarters chosen ex post.
    s.inflationIndex=4;
    for j=1:numel(data.quarters)
        s.excludedQuarters=data.quarters(j);
        stats=fitStats(values{r},data.quarters,s,6);
        label=string(floor(data.quarters(j)/4))+"Q"+string(mod(data.quarters(j),4)+1);
        influence=[influence;table(regions(r),label,stats(1),stats(2),stats(3),stats(4),stats(5), ...
            'VariableNames',{'Region','ExcludedQuarter','EGMInflation','EGMCumulative','MaxRoot','EffectiveN','Stable'})]; %#ok<AGROW>
    end
end
robustness.summary=summary; robustness.influence=influence;
end

function stats=fitStats(y,q,s,moneyIndex)
m=FitRecursiveVAR(y,q,s);
if m.maxRoot<1
    stats=[m.fevd(s.inflationIndex,moneyIndex),m.fevdCumulative(s.inflationIndex,moneyIndex), ...
        m.maxRoot,m.effectiveN,1];
else
    % Retain diagnostics, but do not publish FEVD from an unstable point fit.
    stats=[NaN,NaN,m.maxRoot,m.effectiveN,0];
end
end
