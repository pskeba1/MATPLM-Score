function outtable = generate_report(plm_results,arousal,apnea,ID)
% TODO: need sleep stages for arousal and apnea stuff
% TODO: adjust times for lights on/off

col1 = {'Time in Stage';'CLMnr';'PLMnr';'PLMnr_a';'PInr';'IMInr';'IMInr';...
    'CLMnr';'PLMnr';'PLMa';'PI';'IMI';'IMI';'R events';'R events';'Arousal'};

col2 = {'hours';'no./hour';'no./hour';'no./hour';'no./hour';'log; mean';...
    'log; SD';'no./hour';'no./hour';'no./hour';' ';'log; mean';...
    'log; SD';'no./hour';'with CLMnr';'no./hour'};

ep = plm_results.epochstage;

%% Indices during entire night
PLMnr = plm_results.PLMnr; CLMnr = plm_results.CLMnr;
PLM = plm_results.PLM; CLM = plm_results.CLM; TT = size(ep,1)/120;
col3 = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea);

%% Indices during sleep
PLMnr = plm_results.PLMnr(plm_results.PLMnr(:,6) > 0,:); 
CLMnr = plm_results.CLMnr(plm_results.CLMnr(:,6) > 0,:);
PLM = plm_results.PLM(plm_results.PLM(:,6) > 0,:); 
CLM = plm_results.CLM(plm_results.CLM(:,6) > 0,:);
TT = size(ep(ep > 0),1)/120;
col4 = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea);

%% Indices during wake
PLMnr = plm_results.PLMnr(plm_results.PLMnr(:,6) == 0,:); 
CLMnr = plm_results.CLMnr(plm_results.CLMnr(:,6) == 0,:);
PLM = plm_results.PLM(plm_results.PLM(:,6) == 0,:); 
CLM = plm_results.CLM(plm_results.CLM(:,6) == 0,:);
TT = size(ep(ep == 0),1)/120;
col5 = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea);

%% Indices during N1
PLMnr = plm_results.PLMnr(plm_results.PLMnr(:,6) == 1,:); 
CLMnr = plm_results.CLMnr(plm_results.CLMnr(:,6) == 1,:);
PLM = plm_results.PLM(plm_results.PLM(:,6) == 1,:); 
CLM = plm_results.CLM(plm_results.CLM(:,6) == 1,:);
TT = size(ep(ep == 1),1)/120;
col6 = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea);

%% Indices during N2
PLMnr = plm_results.PLMnr(plm_results.PLMnr(:,6) == 2,:); 
CLMnr = plm_results.CLMnr(plm_results.CLMnr(:,6) == 2,:);
PLM = plm_results.PLM(plm_results.PLM(:,6) == 2,:); 
CLM = plm_results.CLM(plm_results.CLM(:,6) == 2,:);
TT = size(ep(ep == 2),1)/120;
col7 = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea);

%% Indices during N3
PLMnr = plm_results.PLMnr(plm_results.PLMnr(:,6) == 3,:); 
CLMnr = plm_results.CLMnr(plm_results.CLMnr(:,6) == 3,:);
PLM = plm_results.PLM(plm_results.PLM(:,6) == 3,:); 
CLM = plm_results.CLM(plm_results.CLM(:,6) == 3,:);
TT = size(ep(ep == 3),1)/120;
col8 = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea);

%% Indices during REM
PLMnr = plm_results.PLMnr(plm_results.PLMnr(:,6) == 5,:); 
CLMnr = plm_results.CLMnr(plm_results.CLMnr(:,6) == 5,:);
PLM = plm_results.PLM(plm_results.PLM(:,6) == 5,:); 
CLM = plm_results.CLM(plm_results.CLM(:,6) == 5,:);
TT = size(ep(ep == 5),1)/120;
col9 = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea);

%% Indices during REM
PLMnr = plm_results.PLMnr(plm_results.PLMnr(:,6) < 5 & plm_results.PLMnr(:,6) > 0,:); 
CLMnr = plm_results.CLMnr(plm_results.CLMnr(:,6) < 5 & plm_results.CLMnr(:,6) > 0,:); 
PLM = plm_results.PLM(plm_results.PLM(:,6) < 5 & plm_results.PLM(:,6) > 0,:);
CLM = plm_results.CLM(plm_results.CLM(:,6) < 5 & plm_results.CLM(:,6) > 0,:);
TT = size(ep(ep < 5 & ep > 0),1)/120;
col10 = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea);

%% Other things
colnames = {'Event','Metric','TIB','TST','Wake','N1','N2','N3','REM','NREM'};

% PLMnr Results
outtable = table(col1(1:13,:),col2(1:13,:),col3(1:13,:),col4(1:13,:),...
    col5(1:13,:),col6(1:13,:),col7(1:13,:),col8(1:13,:),col9(1:13,:),...
    col10(1:13,:),'VariableNames',colnames);

% Plotting procedure
lin_labels = {'2s','10s','20s','30s','40s','50s','60s','70s','80s','90s'};
log_labels = {'2s','10s','20s','40s','60s','90s'};

figure('units','normalized','position',[.3 .3 .4 .4],'Visible','off')

subplot(2,2,1);
% HEY YOU, I CHANGED THIS SO NOW IT PLOTS ALL CLMnr EXCEPT > 90 IMI
CLMSnr = plm_results.CLMnr(plm_results.CLMnr(:,6) > 0,:);
hst = histogram(CLMSnr(CLMSnr(:,9) ~= 1,4),40);
title('CLMSnr intermovement intervals')
xlim([0,90]); ylim([0,max(20,max(hst.Values))]);
set(gca,'xtick',[2,10:10:90]);
set(gca,'xticklabel',lin_labels);

subplot(2,2,2);
hst = histogram(log(CLMSnr(CLMSnr(:,9) ~= 1,4)),40);
title('CLMSnr intermovement intervals, log scale')
xlim([0,log(90)]); ylim([0,max(20,max(hst.Values))]);
set(gca,'xtick',[log(2),log(10),log(20),log(40),log(60),log(90)]);
set(gca,'xticklabel',log_labels);

subplot(2,2,3);
CLMS = plm_results.CLM(plm_results.CLM(:,6) > 0,:);
hst = histogram(CLMS(CLMS(:,9) ~= 1,4),40);
title('CLMS intermovement intervals')
xlim([0,90]); ylim([0,max(20,max(hst.Values))]);
set(gca,'xtick',[2,10:10:90]);
set(gca,'xticklabel',lin_labels);

subplot(2,2,4);
hst = histogram(log(CLMS(CLMS(:,9) ~= 1,4)),40);
title('CLMS intermovement intervals, log scale')
xlim([0,log(90)]); ylim([0,max(20,max(hst.Values))]);
set(gca,'xtick',[log(2),log(10),log(20),log(40),log(60),log(90)]);
set(gca,'xticklabel',log_labels);

%% Report Generation
assignin('base','outcell',[outtable.Properties.VariableNames;...
    table2cell(outtable)]);
assignin('base','ID',ID);
assignin('base','today_date',datestr(today));
report('generate_report',['-o' ID]);
close;
end

function col = get_column(CLMnr,PLMnr,CLM,PLM,TT,arousal,apnea)
col = cell(15,1);
col{1} = datestr(TT/24,'HH:MM:SS');
col{1+1} = size(CLMnr,1)/TT;
col{2+1} = size(PLMnr,1)/TT;
col{3+1} = size(PLMnr(PLMnr(:,12) > 0),1)/TT;
col{4+1} = size(PLMnr,1)/size(CLMnr,1);
col{5+1} = exp(mean(log(PLMnr(PLMnr(:,9) ~= 1,4))));
col{6+1} = exp(std(log(PLMnr(PLMnr(:,9) ~= 1,4))));
col{7+1} = size(CLM,1)/TT;
col{8+1} = size(PLM,1)/TT;
col{9+1} = size(PLM(PLM(:,12) > 0),1)/TT;
col{10+1} = size(PLM,1)/size(CLM,1);
col{11+1} = exp(mean(log(PLM(PLM(:,9) ~= 1,4))));
col{12+1} = exp(std(log(PLM(PLM(:,9) ~= 1,4))));
col{13+1} = size(apnea,1);
col{14+1} = size(CLM(CLM(:,11)>0),1);
col{15+1} = size(arousal,1)/TT;
end