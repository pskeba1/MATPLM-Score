function outtable = generate_report(plm_results,arousal,apnea)
% TODO: allow for different sleep epoch lengths
% TODO: need sleep stages for arousal and apnea stuff

col1 = {'Time in Stage';'CLMnr';'PLMnr';'PLMnr_a';'PInr';'IMInr';'IMInr';'CLM';'PLM';...;
    'PLMa';'PI';'IMI';'IMI';'R events';'R events';'Arousal'};

col2 = {'hours';'no./hour';'no./hour';'no./hour';'no./hour';'log; mean';...
    'log; SD';'no./hour';'no./hour';'no./hour';'no./hour';'log; mean';...
    'log; SD';'no./hour';'with CLM';'no./hour'};

ep = plm_results.epochstage;
TRT = size(ep,1)/120;
TST = size(ep(ep > 0),1)/120;
TWT = size(ep(ep == 0),1)/120;
T1T = size(ep(ep == 1),1)/120;
T2T = size(ep(ep == 2),1)/120;
T3T = size(ep(ep == 3),1)/120;
TREMT = size(ep(ep == 5),1)/120;
TnREMT = size(ep(ep > 0 & ep < 5),1)/120;

% Indices during entire night
col3 = cell(15,1);
col3{1} = datestr(TRT/24,'HH:MM:SS');
col3{1+1} = size(plm_results.CLM,1)/TRT;
col3{2+1} = size(plm_results.PLM,1)/TRT;
col3{3+1} = size(plm_results.PLM(plm_results.PLM(:,12) > 0),1)/TRT;
col3{4+1} = size(plm_results.PLM,1)/size(plm_results.CLM,1);
col3{5+1} = exp(mean(log(plm_results.PLM(plm_results.PLM(:,9)==0,4))));
col3{6+1} = exp(std(log(plm_results.PLM(plm_results.PLM(:,9)==0,4))));
col3{7+1} = size(plm_results.CLMr,1)/TRT;
col3{8+1} = size(plm_results.PLMr,1)/TRT;
col3{9+1} = size(plm_results.PLMr(plm_results.PLMr(:,12) > 0),1)/TRT;
col3{10+1} = size(plm_results.PLMr,1)/size(plm_results.CLMr,1);
col3{11+1} = exp(mean(log(plm_results.PLMr(plm_results.PLMr(:,9)==0,4))));
col3{12+1} = exp(std(log(plm_results.PLMr(plm_results.PLMr(:,9)==0,4))));
col3{13+1} = size(apnea,1);
col3{14+1} = size(plm_results.CLMr(plm_results.CLMr(:,11)>0),1);
col3{15+1} = size(arousal,1)/TRT;

% Indices during sleep
col4 = cell(15,1);
col4{1} = datestr(TST/24,'HH:MM:SS');
col4{1+1} = size(plm_results.CLMS,1)/TST;
col4{2+1} = size(plm_results.PLMS,1)/TST;
col4{3+1} = size(plm_results.PLMS(plm_results.PLMS(:,12) > 0),1)/TST;
col4{4+1} = size(plm_results.PLMS,1)/size(plm_results.CLMS,1);
col4{5+1} = exp(mean(log(plm_results.PLMS(plm_results.PLMS(:,9)==0,4))));
col4{6+1} = exp(std(log(plm_results.PLMS(plm_results.PLMS(:,9)==0,4))));
col4{7+1} = size(plm_results.CLMr(plm_results.CLMr(:,6) > 0),1)/TST;
col4{8+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) > 0),1)/TST;
col4{9+1} = size(plm_results.PLMr(plm_results.PLMr(:,12) > 0 & ...
    plm_results.PLMr(:,6) > 0),1)/TST;
col4{10+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) > 0),1)/...
    size(plm_results.CLMr(plm_results.CLMr(:,6) > 0),1); %TODO: PI
col4{11+1} = exp(mean(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) > 0,4))));
col4{12+1} = exp(std(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) > 0,4))));
col4{13+1} = size(apnea,1);
col4{14+1} = size(plm_results.CLMr(plm_results.CLMr(:,11)>0 & ...
    plm_results.CLMr(:,6) > 0),1);
col4{15+1} = size(arousal,1)/TST; % TODO  arousal in sleep stage

% Indices during wake
PLMW = plm_results.PLM(plm_results.PLM(:,6) == 0,:);
CLMW = plm_results.CLM(plm_results.CLM(:,6) == 0,:);
col5 = cell(15,1);
col5{1} = datestr(TWT/24,'HH:MM:SS');
col5{1+1} = size(CLMW,1)/TWT;
col5{2+1} = size(PLMW,1)/TWT;
col5{3+1} = size(PLMW(PLMW(:,12) > 0),1)/TWT;
col5{4+1} = size(PLMW,1)/size(CLMW,1); %TODO: PInr
col5{5+1} = exp(mean(log(PLMW(PLMW(:,9)==0,4))));
col5{6+1} = exp(std(log(PLMW(PLMW(:,9)==0,4))));
col5{7+1} = size(plm_results.CLMr(plm_results.CLMr(:,6) == 0),1)/TWT;
col5{8+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 0),1)/TWT;
col5{9+1} = size(plm_results.PLMr(plm_results.PLMr(:,12) == 0 & ...
    plm_results.PLMr(:,6) == 0),1)/TWT;
col5{10+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 0),1)/...
    size(plm_results.CLMr(plm_results.CLMr(:,6) == 0),1); %TODO: PI
col5{11+1} = exp(mean(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 0,4))));
col5{12+1} = exp(std(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 0,4))));
col5{13+1} = size(apnea,1);
col5{14+1} = size(plm_results.CLMr(plm_results.CLMr(:,11)>0 & ...
    plm_results.CLMr(:,6) == 0),1);
col5{15+1} = size(arousal,1)/TWT; % TODO  arousal in sleep stage

% Indices during stage 1
PLM1 = plm_results.PLM(plm_results.PLM(:,6) == 1,:);
CLM1 = plm_results.CLM(plm_results.CLM(:,6) == 1,:);
col6 = cell(15,1);
col6{1} = datestr(T1T/24,'HH:MM:SS');
col6{1+1} = size(CLM1,1)/T1T;
col6{2+1} = size(PLM1,1)/T1T;
col6{3+1} = size(PLM1(PLM1(:,12) > 0),1)/T1T;
col6{4+1} = size(PLM1,1)/size(CLM1,1); %TODO: PInr
col6{5+1} = exp(mean(log(PLM1(PLM1(:,9)==0,4))));
col6{6+1} = exp(std(log(PLM1(PLM1(:,9)==0,4))));
col6{7+1} = size(plm_results.CLMr(plm_results.CLMr(:,6) == 1),1)/T1T;
col6{8+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 1),1)/T1T;
col6{9+1} = size(plm_results.PLMr(plm_results.PLMr(:,12) == 0 & ...
    plm_results.PLMr(:,6) == 1),1)/T1T;
col6{10+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 1),1)/...
    size(plm_results.CLMr(plm_results.CLMr(:,6) == 1),1); %TODO: PI
col6{11+1} = exp(mean(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 1,4))));
col6{12+1} = exp(std(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 1,4))));
col6{13+1} = size(apnea,1);
col6{14+1} = size(plm_results.CLMr(plm_results.CLMr(:,11)>0 & ...
    plm_results.CLMr(:,6) == 1),1);
col6{15+1} = size(arousal,1)/T1T; % TODO  arousal in sleep stage

outtable = table(col1,col2,col3,col4,col5,col6);

% Indices during stage 2
PLM2 = plm_results.PLM(plm_results.PLM(:,6) == 2,:);
CLM2 = plm_results.CLM(plm_results.CLM(:,6) == 2,:);
col7 = cell(15,1);
col7{1} = datestr(T2T/24,'HH:MM:SS');
col7{1+1} = size(CLM2,1)/T2T;
col7{2+1} = size(PLM2,1)/T2T;
col7{3+1} = size(PLM2(PLM2(:,12) > 0),1)/T2T;
col7{4+1} = size(PLM2,1)/size(CLM2,1); %TODO: PInr
col7{5+1} = exp(mean(log(PLM2(PLM2(:,9)==0,4))));
col7{6+1} = exp(std(log(PLM2(PLM2(:,9)==0,4))));
col7{7+1} = size(plm_results.CLMr(plm_results.CLMr(:,6) == 2),1)/T2T;
col7{8+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 2),1)/T2T;
col7{9+1} = size(plm_results.PLMr(plm_results.PLMr(:,12) == 0 & ...
    plm_results.PLMr(:,6) == 2),1)/T2T;
col7{10+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 2),1)/...
    size(plm_results.CLMr(plm_results.CLMr(:,6) == 2),1);
col7{11+1} = exp(mean(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 2,4))));
col7{12+1} = exp(std(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 2,4))));
col7{13+1} = size(apnea,1);
col7{14+1} = size(plm_results.CLMr(plm_results.CLMr(:,11)>0 & ...
    plm_results.CLMr(:,6) == 2),1);
col7{15+1} = size(arousal,1)/T2T; % TODO  arousal in sleep stage

% Indices during stage 3
PLM3 = plm_results.PLM(plm_results.PLM(:,6) == 3,:);
CLM3 = plm_results.CLM(plm_results.CLM(:,6) == 3,:);
col8 = cell(15,1);
col8{1} = datestr(T3T/24,'HH:MM:SS');
col8{1+1} = size(CLM3,1)/T3T;
col8{2+1} = size(PLM3,1)/T3T;
col8{3+1} = size(PLM3(PLM3(:,12) > 0),1)/T3T;
col8{4+1} = size(PLM3,1)/size(CLM3,1); %TODO: PInr
col8{5+1} = exp(mean(log(PLM3(PLM3(:,9)==0,4))));
col8{6+1} = exp(std(log(PLM3(PLM3(:,9)==0,4))));
col8{7+1} = size(plm_results.CLMr(plm_results.CLMr(:,6) == 3),1)/T3T;
col8{8+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 3),1)/T3T;
col8{9+1} = size(plm_results.PLMr(plm_results.PLMr(:,12) == 0 & ...
    plm_results.PLMr(:,6) == 3),1)/T3T;
col8{10+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 3),1)/...
    size(plm_results.CLMr(plm_results.CLMr(:,6) == 3),1); %TODO: PI
col8{11+1} = exp(mean(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 3,4))));
col8{12+1} = exp(std(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 3,4))));
col8{13+1} = size(apnea,1);
col8{14+1} = size(plm_results.CLMr(plm_results.CLMr(:,11)>0 & ...
    plm_results.CLMr(:,6) == 3),1);
col8{15+1} = size(arousal,1)/T3T; % TODO  arousal in sleep stage

% Indices during REM
PLMREM = plm_results.PLM(plm_results.PLM(:,6) == 5,:);
CLMREM = plm_results.CLM(plm_results.CLM(:,6) == 5,:);
col9 = cell(15,1);
col9{1} = datestr(TREMT/24,'HH:MM:SS');
col9{1+1} = size(CLMREM,1)/TREMT;
col9{2+1} = size(PLMREM,1)/TREMT;
col9{3+1} = size(PLMREM(PLMREM(:,12) > 0),1)/TREMT;
col9{4+1} = size(PLMREM,1)/size(CLMREM,1); %TODO: PInr
col9{5+1} = exp(mean(log(PLMREM(PLMREM(:,9)==0,4))));
col9{6+1} = exp(std(log(PLMREM(PLMREM(:,9)==0,4))));
col9{7+1} = size(plm_results.CLMr(plm_results.CLMr(:,6) == 5),1)/TREMT;
col9{8+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 5),1)/TREMT;
col9{9+1} = size(plm_results.PLMr(plm_results.PLMr(:,12) == 0 & ...
    plm_results.PLMr(:,6) == 5),1)/TREMT;
col9{10+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) == 5),1)/...
    size(plm_results.CLMr(plm_results.CLMr(:,6) == 5),1); %TODO: PI
col9{11+1} = exp(mean(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 5,4))));
col9{12+1} = exp(std(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) == 5,4))));
col9{13+1} = size(apnea,1);
col9{14+1} = size(plm_results.CLMr(plm_results.CLMr(:,11)>0 & ...
    plm_results.CLMr(:,6) == 5),1);
col9{15+1} = size(arousal,1)/TREMT; % TODO  arousal in sleep stage

% Indices during REM
PLMnREM = plm_results.PLM(plm_results.PLM(:,6) > 0 & ...
    plm_results.PLM(:,6) < 5,:);
CLMnREM = plm_results.CLM(plm_results.CLM(:,6) > 0 & ...
    plm_results.CLM(:,6) < 5,:);
col10 = cell(15,1);
col10{1} = datestr(TnREMT/24,'HH:MM:SS');
col10{1+1} = size(CLMnREM,1)/TnREMT;
col10{2+1} = size(PLMnREM,1)/TnREMT;
col10{3+1} = size(PLMnREM(PLMnREM(:,12) > 0),1)/TnREMT;
col10{4+1} = size(PLMnREM,1)/size(CLMnREM,1); %TODO: PInr
col10{5+1} = exp(mean(log(PLMnREM(PLMnREM(:,9)==0,4))));
col10{6+1} = exp(std(log(PLMnREM(PLMnREM(:,9)==0,4))));
col10{7+1} = size(plm_results.CLMr(plm_results.CLMr(:,6) > 0 & ...
    plm_results.CLMr(:,6) < 5),1)/TnREMT;
col10{8+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) > 0 & ...
    plm_results.PLMr(:,6) < 5),1)/TnREMT;
col10{9+1} = size(plm_results.PLMr(plm_results.PLMr(:,12) == 0 & ...
    plm_results.PLMr(:,6) > 0 & ...
    plm_results.PLMr(:,6) < 5),1)/TnREMT;
col10{10+1} = size(plm_results.PLMr(plm_results.PLMr(:,6) > 0 & ...
    plm_results.PLMr(:,6) < 5),1)/size(plm_results.CLMr(plm_results.CLMr(:,6) > 0 & ...
    plm_results.CLMr(:,6) < 5),1); %TODO: PI
col10{11+1} = exp(mean(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
    plm_results.PLMr(:,6) > 0 & ...
    plm_results.PLMr(:,6) < 5,4))));
col10{12+1} = exp(std(log(plm_results.PLMr(plm_results.PLMr(:,9)==0 & ...
   plm_results.PLMr(:,6) > 0 & ...
    plm_results.PLMr(:,6) < 5,4))));
col10{13+1} = size(apnea,1);
col10{14+1} = size(plm_results.CLMr(plm_results.CLMr(:,11)>0 & ...
    plm_results.CLMr(:,6) > 0 & ...
    plm_results.CLMr(:,6) < 5),1);
col10{15+1} = size(arousal,1)/TnREMT; % TODO  arousal in sleep stage


colnames = {'Event','Metric','TIB','TST','Wake','N1','N2','N3','REM','NREM'};

% PLM Results
outtable = table(col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,...
    'VariableNames',colnames);

% Plotting procedure
lin_labels = {'2s','10s','20s','30s','40s','50s','60s','70s','80s','90s'};
log_labels = {'2s','10s','20s','40s','60s','90s'};

figure('units','normalized','position',[.3 .3 .4 .4])

subplot(2,2,1);
histogram(plm_results.CLMS(plm_results.CLMS(:,9) == 0,4),50);
title('CLMSnr intermovement intervals')
xlim([2,90]); 
set(gca,'xtick',[2,10:10:90]);
set(gca,'xticklabel',lin_labels);

subplot(2,2,2);
histogram(log(plm_results.CLMS(plm_results.CLMS(:,9) == 0,4)),50);
title('CLMSnr intermovement intervals, log scale')
xlim([log(2),log(90)])
set(gca,'xtick',[log(2),log(10),log(20),log(40),log(60),log(90)]);
set(gca,'xticklabel',log_labels);

subplot(2,2,3);
histogram(plm_results.CLMr(plm_results.CLMr(:,6) > 0 & ...
    plm_results.CLMr(:,9) == 0,4),50);
title('CLMS intermovement intervals')
xlim([2,90]); 
set(gca,'xtick',[2,10:10:90]);
set(gca,'xticklabel',lin_labels);

subplot(2,2,4);
histogram(log(plm_results.CLMr(plm_results.CLMr(:,6) > 0 & ...
    plm_results.CLMr(:,9) == 0,4)),50);
title('CLMS intermovement intervals, log scale')
xlim([log(2),log(90)])
set(gca,'xtick',[log(2),log(10),log(20),log(40),log(60),log(90)]);
set(gca,'xticklabel',log_labels);

%% Report Generation

end