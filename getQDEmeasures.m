function [amps,riseTimes,halfWidths] = getQDEmeasures(Vtrace,VpeaksIdcs,baselineVs)
%this function takes Vtraces,VpeaksIdcs and baselineVs 
%and calculates amp, rise-time and half-width for each QDE.
no_of_QDEs = length(VpeaksIdcs);

Vpeaks = Vtrace(VpeaksIdcs);
amps = Vpeaks - baselineVs;

    riseTimes = zeros(no_of_QDEs,1);
    halfWidths = zeros(no_of_QDEs,1);
for i = 1:no_of_QDEs
    QDEtrace = Vtrace(VpeaksIdcs(i)-120:VpeaksIdcs(i)+800);
    
    risingTrace_i = QDEtrace(1:121) - baselineVs(i);
    riseTimeTrace = find(risingTrace_i > .1*amps(i) & risingTrace_i < .9*amps(i));
    riseTimes(i) = length(riseTimeTrace) / 20;
    
    risingDecayingTrace_i = smoothdata(QDEtrace - baselineVs(i),'movmedian',10);
    halfWidthTrace = find(risingDecayingTrace_i > .5*amps(i));
    halfWidths = length(halfWidthTrace) / 20;
    
    figure;hold on;
    plot((-6:.05:40),QDEtrace,'b')
    scatter(riseTimeTrace(1)-120,.1*amps(i)+baselineVs(i),'r','filled')
    scatter(riseTimeTrace(end)-120,.9*amps(i)+baselineVs(i),'r','filled')
    scatter(halfWidthTrace(1)+20,.5*amps(i)+baselineVs(i),'g','filled')
    scatter(halfWidthTrace(end)+20,.5*amps(i)+baselineVs(i),'g','filled')
end



end

