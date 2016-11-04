function output = split_events(events_file)
%% output = split_events(events_file)
% This functions takes as input a Remlogic file with all the events that
% one would wish to score. Event types should be specified before running
% the script in the file 'event_types.csv'. At this point, Remlogic event
% file should have four columns: type, event, duration, location.
%
% TODO: consider making use of 'position' channel - no need at the moment,
% but perhaps it would be of clinical significance
% TODO: multilanguage support for left/right emg

event_types = readtable('event_types.csv');

params = getInput2(1);

fid = fopen(events_file);

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
        
        if size(strmatch(dataline(2),event_types.Sleep_Stages),1) > 0
            sleep_stages = [sleep_stages; cell2table(dataline,'VariableNames',label_line)];
        elseif size(strmatch(dataline(2),event_types.Arousal_Events),1) > 0
            arousals = [arousals; cell2table(dataline,'VariableNames',label_line)];
        elseif size(strmatch(dataline(2),event_types.Respiratory_Events),1) > 0
            apneas = [apneas; cell2table(dataline,'VariableNames',label_line)];
        elseif size(strmatch(dataline(2),event_types.PLM_Events),1) > 0
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
ep(~cellfun('isempty', strfind(T,'1'))) = 1;
ep(~cellfun('isempty', strfind(T,'2'))) = 2;
ep(~cellfun('isempty', strfind(T,'3'))) = 3;
ep(~cellfun('isempty', strfind(T,'4'))) = 4;
ep(~cellfun('isempty', strfind(T,'REM'))) = 5;


% TODO: multilanguage support
lLM_tbl = lms(find(not(cellfun('isempty', strfind(lms.Location,'Left')))),:);
rLM_tbl = lms(find(not(cellfun('isempty', strfind(lms.Location,'Right')))),:);

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

generate_report(plm_results, params);

output = struct('sleepstages',sleep_stages,'arousals',arousals,...
    'apneas',apneas,'lms',lms,'tformat',tformat,'plm_results',plm_results);
end

function generate_report(plm_outputs, params)
%% generate_report(plm_outputs, params)
% Display to console pertinent features
% plm_outputs must at least contain epochstage,PLM,PLMS,CLM
%
% TOD0: report log IMI, allow output to file

ep = plm_outputs.epochstage;
TST = sum(ep > 0,1)/120; TWT = sum(ep == 0,1)/120; 

display(sprintf('Total sleep time: %.2f hours',TST));

PLMSi = size(plm_outputs.PLMS,1)/TST;
display(sprintf('PLMS index: %.2f per hour',PLMSi));

PLMWi = size(setdiff(plm_outputs.PLM,plm_outputs.PLMS,'rows'),1)/TWT;
display(sprintf('PLMW index: %.2f per hour', PLMWi));

PLMS_Ni = sum(plm_outputs.PLMS(:,6) < 5)/(sum(ep > 0 & ep < 5)/120);
display(sprintf('PLMS-N index: %.2f per hour',PLMS_Ni));

PLMS_Ri = sum(plm_outputs.PLMS(:,6) == 5)/(sum(ep == 5)/120);
display(sprintf('PLMS-R index: %.2f per hour',PLMS_Ri));

PLMS_ai = sum(plm_outputs.PLMS(:,12) > 0)/TST;
display(sprintf('PLMS-arousal index: %.2f per hour',PLMS_ai));

% Here we display PLMS/hr excluding CLM associated with apnea events. This
% requires a reevaluation of periodicity, but I am unsure whether
% apnea-associated CLM should be removed or breakpoints added. And I don't
% know if this needs to be done in candidate_lms or periodic_lms
% nrCLM = plm_outputs.CLM(plm_outputs.CLM(:,11) == 0,:);

% The next 3 displays are indices for CLM associated with apnea events
% (suppose I should say respiratory, since they're abbreviated rCLM)
rCLMSi = sum(plm_outputs.CLMS(:,11) > 0)/TST;
display(sprintf('rCLMS index: %.2f per hour',rCLMSi));

rCLMS_Ni = sum(plm_outputs.CLMS(:,11) > 0 & plm_outputs.CLMS(:,6) < 5)/...
    (sum(ep > 0 & ep < 5)/120);
display(sprintf('rCLMS-N index: %.2f per hour',rCLMS_Ni));

rCLMS_Ri = sum(plm_outputs.CLMS(:,11) > 0 & plm_outputs.CLMS(:,6) == 5)/...
    (sum(ep == 5)/120);
display(sprintf('rCLMS-R index: %.2f per hour',rCLMS_Ri));

% The next 2 displays are indices for CLM with IMI less than the min IMI
short_CLMSi = sum(plm_outputs.CLMS(:,4) < params.minIMI)/TST;
display(sprintf('short IMI CLMS index: %.2f per hour',short_CLMSi));

short_CLMWi = sum(plm_outputs.CLM(:,4) < params.minIMI & ...
    plm_outputs.CLM(:,6) == 0)/TWT;
display(sprintf('short IMI CLMW index: %.2f per hour',short_CLMWi));

% Next 2 dipslays are are nonperiodic CLM
np_CLMSi = sum(plm_outputs.CLMS(:,5) == 0)/TST;
display(sprintf('nonperiodic CLMS index: %.2f per hour',np_CLMSi))

np_CLMWi = sum(plm_outputs.CLM(:,5) == 0 & plm_outputs.CLM(:,6) == 0)/TWT;
display(sprintf('nonperiodic CLMW index: %.2f per hour',np_CLMWi))

% Next 4 are some duration stuff
PLMS_dur = mean(plm_outputs.PLMS(:,3));
display(sprintf('mean PLMS duration: %.2f s',PLMS_dur));

PLMS_Ndur = mean(plm_outputs.PLMS(plm_outputs.PLMS(:,6) < 5,3));
display(sprintf('mean PLMS-N duration: %.2f s',PLMS_Ndur));

PLMS_Rdur = mean(plm_outputs.PLMS(plm_outputs.PLMS(:,6) == 5,3));
display(sprintf('mean PLMS-R duration: %.2f s',PLMS_Rdur));

PLMW_dur = mean(plm_outputs.PLM(plm_outputs.PLM(:,6) == 0,3));
display(sprintf('mean PLMW-N duration: %.2f s',PLMW_dur));

% Next 4 are some IMI stuff
PLMS_imi = mean(plm_outputs.PLMS(plm_outputs.PLMS(:,9) == 0,4));
display(sprintf('mean PLMS IMI: %.2f s',PLMS_imi));

PLMS_Nimi = mean(plm_outputs.PLMS(plm_outputs.PLMS(plm_outputs.PLMS(:,9) == 0,6) < 5,4));
display(sprintf('mean PLMS-N IMI: %.2f s',PLMS_Nimi));

PLMS_Rimi = mean(plm_outputs.PLMS(plm_outputs.PLMS(plm_outputs.PLMS(:,9) == 0,6) == 5,4));
display(sprintf('mean PLMS-R IMI: %.2f s',PLMS_Rimi));

PLMW_imi = mean(plm_outputs.PLM(plm_outputs.PLM(plm_outputs.PLMS(:,9) == 0,6) == 0,4));
display(sprintf('mean PLMW-N IMI: %.2f s',PLMW_imi));

% The next 2 displays are duration for CLM with IMI less than the min IMI
short_CLMSdur = mean(plm_outputs.CLMS(plm_outputs.CLMS(:,4) < params.minIMI,3));
display(sprintf('short IMI CLMS duratoin: %.2f s',short_CLMSdur));

short_CLMWdur = mean(plm_outputs.CLM(plm_outputs.CLM(:,4) < params.minIMI & ...
    plm_outputs.CLM(:,6) == 0,3));
display(sprintf('short IMI CLMW duration: %.2f s',short_CLMWdur));

right_mPLMSi = sum(plm_outputs.PLMS(:,13) == 1)/TST;
display(sprintf('right monolateral PLMS index: %.2f per hour',right_mPLMSi));

left_mPLMSi = sum(plm_outputs.PLMS(:,13) == 2)/TST;
display(sprintf('left monolateral PLMS index: %.2f per hour',left_mPLMSi));

bPLMSi = sum(plm_outputs.PLMS(:,13) == 3)/TST;
display(sprintf('bilateral PLMS index: %.2f per hour',bPLMSi));
end

function [in,cancel] = getInput2(ask)
%% [in] = getInput2(fs, ask)
% Display a dialog window that asks the user for several initial conditions
% and parameters. Store these conditions in the 'in' structure, to be
% passed around the main function. Program will terminate if cancel is
% true. Based off of the file 'inputsdlg.m', which is a script by Takeshi 
% Ikuma that expands the functionality of matlab's built-in input dialogs.
%
% See the bottom of this function for several parameters related to the
% classification of PLM that most users will have no desire to change, but
% can do so here.
%
% inputs:
%   - fs - sampling rate (for filter estimates)
%   - ask - if false, just returns the default struct

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