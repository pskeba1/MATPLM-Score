function split_events()
%% output = split_events(events_file)
% This functions takes as input a Remlogic file with all the events that
% one would wish to score. Event types should be specified before running
% the script in the file 'event_types.csv'. At this point, Remlogic event
% file should have four columns: type, event, duration, location.
%
% TODO: consider making use of 'position' channel - no need at the moment,
% but perhaps it would be of clinical significance
% TODO: multilanguage support for left/right emg
% TODO: allow user to specify output path.

[events_files,event_paths] = uigetfile('.txt','Select input event files:',...
    'sample_events/BC1-Events.txt','MultiSelect','on');

load('history/last_used_defaults.mat','last_used');
%%% begin sleep stage prompt
prompt = {'REM','WAKE','N1','N2','N3','N4'};
name = 'Sleep stage event names:';
sleep_stage_names = inputdlg(prompt,name,[1, length(name)+20],...
    last_used.sleep_defaults);

%%% begin apnea/arousl event prompts
prompt = {'Apnea','Arousal'};
name = 'Names of Arousal and Apnea Events Scored:';
apar_event_names = inputdlg(prompt,name,[10, length(name)+20],...
    {last_used.apnea_defaults,last_used.arousal_defaults});

%%% begin plm event desriptors
prompt = {'LMA','Left Leg Location','Right Leg Location'};
name = 'LM event descriptions:';
plm_event_names = inputdlg(prompt,name,[2, length(name)+20],...
    {last_used.lma_defaults,last_used.left_loc,last_used.right_loc});

%%% save the defaults specified this time so we don't have to reenter
last_used = struct();
last_used(1).apnea_defaults = apar_event_names{1,1};
last_used(1).arousal_defaults = apar_event_names{2,1};
last_used(1).sleep_defaults = sleep_stage_names';
last_used.lma_defaults = plm_event_names{1,1};
last_used.left_loc = plm_event_names{2,1};
last_used.right_loc = plm_event_names{3,1};

save('history/last_used_defaults.mat','last_used');
clear last_used;
%%% we may wish to wait until later to save the actual struct, but for
%%% testing purposes it's alright here.

%%% redefine our names as cell arrays for easy use later
apnea_defaults = cellstr(apar_event_names{1,1});
arousal_defaults = cellstr(apar_event_names{2,1});
sleep_defaults = cellstr(sleep_stage_names');
lma_defaults = cellstr(plm_event_names{1,1});
left_loc = cellstr(plm_event_names{2,1});
right_loc = cellstr(plm_event_names{3,1});

params = getInput2(1);


for each_file = 1:length(events_files)
    
    outfile_path = [events_files{each_file}(1:end-4), '.report'];
    outfile_path = [event_paths, outfile_path];
    
    fid = fopen([event_paths, events_files{each_file}]);
    
    tline = fgetl(fid);
    indata = false;
    while ~feof(fid)
        
        % Is this language dependent? Also, may be able to automatically
        % extract time format from this file
        if ~isempty(strfind(tline,'Time [hh:mm:ss.xxx]')) ||...
                ~isempty(strfind(tline,'Time [hh:mm:ss]'))
            
            if strfind(tline,'Time [hh:mm:ss.xxx]')
                tformat = 'yyyy-mm-ddTHH:MM:SS.fff';
            else
                tformat = 'yyyy-mm-ddTHH:MM:SS';
            end
            indata=true;
            label_line = {'Time','Event','Duration','Location'};
            
            sleep_stages = cell2table(cell(0,4),'VariableNames',label_line');
            arousals = cell2table(cell(0,4),'VariableNames',label_line');
            apneas = cell2table(cell(0,4),'VariableNames',label_line');
            lms = cell2table(cell(0,4),'VariableNames',label_line');
        end
        
        tline = fgetl(fid);
        
        % if the last line was the start of the data part of the file, we'll
        % begin processing things
        if indata
            dataline = strsplit(tline,'\t'); % should be tab delineated
            
            %if size(strmatch(dataline(2),event_types.Sleep_Stages),1) > 0
            if size(strmatch(dataline(2),sleep_defaults),1) > 0
                sleep_stages = [sleep_stages; cell2table(dataline,'VariableNames',label_line)];
                %elseif size(strmatch(dataline(2),event_types.Arousal_Events),1) > 0
            elseif size(strmatch(dataline(2),arousal_defaults),1) > 0
                arousals = [arousals; cell2table(dataline,'VariableNames',label_line)];
                %elseif size(strmatch(dataline(2),event_types.Respiratory_Events),1) > 0
            elseif size(strmatch(dataline(2),apnea_defaults),1) > 0
                apneas = [apneas; cell2table(dataline,'VariableNames',label_line)];
                %elseif size(strmatch(dataline(2),event_types.PLM_Events),1) > 0
            elseif size(strmatch(dataline(2),lma_defaults),1) > 0
                lms = [lms; cell2table(dataline,'VariableNames',label_line)];
            end
        end
        
    end
    
    fclose(fid);
    
    if ~params.ars, arousals = table(); end
    if ~params.aps, apneas = table(); end
    
    % At the moment, we expect that Remlogic output will contain 30 second
    % epochs for sleep staging. Also, hopefully all the events will contain a
    % number or REM to indicate stage. This could be tough if the format is
    % very different in international versions.
    T = sleep_stages{:,2};
    ep = zeros(size(T,1),1);
    ep(~cellfun('isempty', strfind(T,sleep_stage_names{3}))) = 1;
    ep(~cellfun('isempty', strfind(T,sleep_stage_names{4}))) = 2;
    ep(~cellfun('isempty', strfind(T,sleep_stage_names{5}))) = 3;
    ep(~cellfun('isempty', strfind(T,'4'))) = 4;
    ep(~cellfun('isempty', strfind(T,sleep_stage_names{1}))) = 5;
    
    % Select left and right LMs
    lLM_tbl = lms(~cellfun('isempty', strfind(lms.Location,left_loc{1})),:);
    rLM_tbl = lms(~cellfun('isempty', strfind(lms.Location,right_loc{1})),:);
    
    start_time = datenum(sleep_stages{1,1},tformat);
    
    % Remember, we're going to just assume 500 hz becuase it's purely arbitrary
    % past the detection step.
    if ~isempty(lLM_tbl)
        lLM = round((datenum(lLM_tbl{:,1},tformat)-start_time) * 86500 * 500);
        
        lLM(:,2) = lLM(:,1) + 500 * cellfun(@str2double, lLM_tbl{:,3});
    else
        lLM = [];
    end
    
    if ~isempty(rLM_tbl)
        rLM = round((datenum(rLM_tbl{:,1},tformat)-start_time) * 86500 * 500);
        rLM(:,2) = rLM(:,1) + 500 * cellfun(@str2double, rLM_tbl{:,3});
    else
        rLM = [];
    end
    
    arcell = {}; apcell = {};
    if ~isempty(arousals), arcell = table2cell(arousals(:,1:3)); end
    if ~isempty(apneas), apcell = table2cell(apneas(:,1:3)); end
    
    
    
    % chop off location column for apnea/arousal
    CLM = candidate_lms(rLM,lLM,ep,params,tformat,apcell,arcell,start_time);
    x = periodic_lms(CLM,params);
    
    plm_results = struct();
    plm_results.PLM = x;
    plm_results.PLMS = x(x(:,6) > 0,:);
    plm_results.CLM = CLM;
    plm_results.CLMS = CLM(CLM(:,6) > 0,:);
    plm_results.epochstage = ep;
    
    generate_report(plm_results, params, outfile_path);
    
    % output = struct('sleepstages',sleep_stages,'arousals',arousals,...
    %    'apneas',apneas,'lms',lms,'tformat',tformat,'plm_results',plm_results);
    
end
end

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

rCLMS_Ni = sum(plm_outputs.CLMS(:,11) > 0 & plm_outputs.CLMS(:,6) < 5)/...
    (sum(ep > 0 & ep < 5)/120);
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

function [in,cancel] = getInput2(ask)

if ~ask
    in = struct('ars',true,'aps',true,'maxdur',10,'bmaxdur',15,...
        'minIMI',10,'maxIMI',90,'lb1',0.5,'ub1',0.5,'lb2',0.5,'ub2',0.5,...
        'inlm',true,'minNumIMI',3,'maxcomb',4);
    
    cancel = false;
else
    
    Title = 'MATPLM Parameters';
    
    %%%% SETTING DIALOG OPTIONS
    Options.Resize = 'on';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ButtonNames = {'Continue','Cancel'}; %<- default names, included here just for illustration
    Option.Dim = 4; % Horizontal dimension in fields
    
    Prompt = {};
    Formats = {};
    DefAns = struct([]);
    
    Prompt(1,:) = {'Arousal Events' 'ars',[]};
    Formats(1,1).type = 'check';
    DefAns(1).ars = true;
    
    Prompt(end+1,:) = {'Respiratory Events' 'aps',[]};
    Formats(1,2).type = 'check';
    DefAns.aps = true;
    
    Prompt(end+1,:) = {'Arousal Assoc. Pre   ', 'lb2','s'};
    Formats(2,1).type = 'edit';
    Formats(2,1).format = 'float';
    Formats(2,1).size = 50;
    DefAns.lb2 = 0.5;
    
    Prompt(end+1,:) = {'Respiratory Assoc. Pre  ', 'lb1','s'};
    Formats(2,2).type = 'edit';
    Formats(2,2).format = 'float';
    Formats(2,2).size = 50;
    DefAns.lb1 = 2;
    
    Prompt(end+1,:) = {'Arousal Assoc. Post ', 'ub2','s'};
    Formats(3,1).type = 'edit';
    Formats(3,1).format = 'float';
    Formats(3,1).size = 50;
    DefAns.ub2 = 0.5;
    
    Prompt(end+1,:) = {'Respiratory Assoc. Post', 'ub1','s'};
    Formats(3,2).type = 'edit';
    Formats(3,2).format = 'float';
    Formats(3,2).size = 50;
    DefAns.ub1 = 10.25;
    
    Prompt(end+1,:) = {'Max Monolateral Dur', 'maxdur','s'};
    Formats(4,1).type = 'edit';
    Formats(4,1).format = 'float';
    Formats(4,1).size = 50;
    DefAns.maxdur = 10;
    
    Prompt(end+1,:) = {'Max Bilateral Dur           ', 'bmaxdur','s'};
    Formats(4,2).type = 'edit';
    Formats(4,2).format = 'float';
    Formats(4,2).size = 50;
    DefAns.bmaxdur = 15;
    
    Prompt(end+1,:) = {'Intervening LM Breakpoint' 'inlm',[]};
    Formats(5,1).type = 'check';
    DefAns.inlm = true;
    
    Prompt(end+1,:) = {'Max Comb. Movements', 'maxcomb',[]};
    Formats(6,1).type = 'edit';
    Formats(6,1).format = 'integer';
    Formats(6,1).size = 50; % automatically assign the height
    DefAns.maxcomb = 4;
    
    Prompt(end+1,:) = {'Min num IMI for PLM run', 'minNumIMI',[]};
    Formats(6,2).type = 'edit';
    Formats(6,2).format = 'integer';
    Formats(6,2).size = 50; % automatically assign the height
    DefAns.minNumIMI = 3;
    
    Prompt(end+1,:) = {'Min IMI for PLM             ', 'minIMI','s'};
    Formats(7,1).type = 'edit';
    Formats(7,1).format = 'float';
    Formats(7,1).size = 50; % automatically assign the height
    DefAns.minIMI = 10;
    
    Prompt(end+1,:) = {'Max IMI for PLM             ', 'maxIMI','s'};
    Formats(7,2).type = 'edit';
    Formats(7,2).format = 'float';
    Formats(7,2).size = 50; % automatically assign the height
    DefAns.maxIMI = 90;
    
    [in,cancel] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
    in.fs = 500; % this is abitrary since our event files have time
end

end