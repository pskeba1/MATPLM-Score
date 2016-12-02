function generate_report(plm_outputs, params, filename)
%% generate_report(plm_outputs, params)
% Display to console pertinent features
% plm_outputs must at least contain epochstage,PLM,PLMS,CLM
%
% TOD0: report log IMI, allow output to file

fid = fopen(filename,'w+');

ep = plm_outputs.epochstage;
TST = sum(ep > 0,1)/120; TWT = sum(ep == 0,1)/120;

fprintf(fid,'Total sleep time: %.2f hours\n',TST);

PLMSi = size(plm_outputs.PLMS,1)/TST;
fprintf(fid,'PLMS index: %.2f per hour\n',PLMSi);

PLMWi = size(setdiff(plm_outputs.PLM,plm_outputs.PLMS,'rows'),1)/TWT;
fprintf(fid,'PLMW index: %.2f per hour\n', PLMWi);

PLMS_Ni = sum(plm_outputs.PLMS(:,6) < 5)/(sum(ep > 0 & ep < 5)/120);
fprintf(fid,'PLMS-N index: %.2f per hour\n',PLMS_Ni);

PLMS_Ri = sum(plm_outputs.PLMS(:,6) == 5)/(sum(ep == 5)/120);
fprintf(fid,'PLMS-R index: %.2f per hour\n',PLMS_Ri);

PLMS_ai = sum(plm_outputs.PLMS(:,12) > 0)/TST;
fprintf(fid,'PLMS-arousal index: %.2f per hour\n',PLMS_ai);

% Here we display PLMS/hr excluding CLM associated with apnea events. This
% requires a reevaluation of periodicity, but I am unsure whether
% apnea-associated CLM should be removed or breakpoints added. And I don't
% know if this needs to be done in candidate_lms or periodic_lms
% nrCLM = plm_outputs.CLM(plm_outputs.CLM(:,11) == 0,:);

% The next 3 displays are indices for CLM associated with apnea events
% (suppose I should say respiratory, since they're abbreviated rCLM)
rCLMSi = sum(plm_outputs.CLMS(:,11) > 0)/TST;
fprintf(fid,'rCLMS index: %.2f per hour\n',rCLMSi);

rCLMS_Ni = sum(plm_outputs.CLMap);
fprintf(fid,'rCLMS-N index: %.2f per hour\n',rCLMS_Ni);

rCLMS_Ri = sum(plm_outputs.CLMS(:,11) > 0 & plm_outputs.CLMS(:,6) == 5)/...
    (sum(ep == 5)/120);
fprintf(fid,'rCLMS-R index: %.2f per hour\n',rCLMS_Ri);

% The next 2 displays are indices for CLM with IMI less than the min IMI
short_CLMSi = sum(plm_outputs.CLMS(:,4) < params.minIMI)/TST;
fprintf(fid,'short IMI CLMS index: %.2f per hour\n',short_CLMSi);

short_CLMWi = sum(plm_outputs.CLM(:,4) < params.minIMI & ...
    plm_outputs.CLM(:,6) == 0)/TWT;
fprintf(fid,'short IMI CLMW index: %.2f per hour\n',short_CLMWi);

% Next 2 dipslays are are nonperiodic CLM
np_CLMSi = sum(plm_outputs.CLMS(:,5) == 0)/TST;
fprintf(fid,'nonperiodic CLMS index: %.2f per hour\n',np_CLMSi);

np_CLMWi = sum(plm_outputs.CLM(:,5) == 0 & plm_outputs.CLM(:,6) == 0)/TWT;
fprintf(fid,'nonperiodic CLMW index: %.2f per hour\n',np_CLMWi);

% Next 4 are some duration stuff
PLMS_dur = mean(plm_outputs.PLMS(:,3));
fprintf(fid,'mean PLMS duration: %.2f s\n',PLMS_dur);

PLMS_Ndur = mean(plm_outputs.PLMS(plm_outputs.PLMS(:,6) < 5,3));
fprintf(fid,'mean PLMS-N duration: %.2f s\n',PLMS_Ndur);

PLMS_Rdur = mean(plm_outputs.PLMS(plm_outputs.PLMS(:,6) == 5,3));
fprintf(fid,'mean PLMS-R duration: %.2f s\n',PLMS_Rdur);

PLMW_dur = mean(plm_outputs.PLM(plm_outputs.PLM(:,6) == 0,3));
fprintf(fid,'mean PLMW-N duration: %.2f s\n',PLMW_dur);

% Next 4 are some IMI stuff
PLMS_imi = mean(plm_outputs.PLMS(plm_outputs.PLMS(:,9) == 0,4));
fprintf(fid,'mean PLMS IMI: %.2f s\n',PLMS_imi);

PLMS_Nimi = mean(plm_outputs.PLMS(plm_outputs.PLMS(plm_outputs.PLMS(:,9) == 0,6) < 5,4));
fprintf(fid,'mean PLMS-N IMI: %.2f s\n',PLMS_Nimi);

PLMS_Rimi = mean(plm_outputs.PLMS(plm_outputs.PLMS(plm_outputs.PLMS(:,9) == 0,6) == 5,4));
fprintf(fid,'mean PLMS-R IMI: %.2f s\n',PLMS_Rimi);

PLMW_imi = mean(plm_outputs.PLM(plm_outputs.PLM(plm_outputs.PLMS(:,9) == 0,6) == 0,4));
fprintf(fid,'mean PLMW-N IMI: %.2f s\n',PLMW_imi);

% The next 2 displays are duration for CLM with IMI less than the min IMI
short_CLMSdur = mean(plm_outputs.CLMS(plm_outputs.CLMS(:,4) < params.minIMI,3));
fprintf(fid,'short IMI CLMS duratoin: %.2f s\n',short_CLMSdur);

short_CLMWdur = mean(plm_outputs.CLM(plm_outputs.CLM(:,4) < params.minIMI & ...
    plm_outputs.CLM(:,6) == 0,3));
fprintf(fid,'short IMI CLMW duration: %.2f s\n',short_CLMWdur);

right_mPLMSi = sum(plm_outputs.PLMS(:,13) == 1)/TST;
fprintf(fid,'right monolateral PLMS index: %.2f per hour\n',right_mPLMSi);

left_mPLMSi = sum(plm_outputs.PLMS(:,13) == 2)/TST;
fprintf(fid,'left monolateral PLMS index: %.2f per hour\n',left_mPLMSi);

bPLMSi = sum(plm_outputs.PLMS(:,13) == 3)/TST;
fprintf(fid,'bilateral PLMS index: %.2f per hour\n',bPLMSi);

fclose(fid);
end