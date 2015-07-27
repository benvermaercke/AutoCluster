clear all
clc

headerFile % Define dataFolder in here!!!

if ~exist('dataFolder','var')
    dataFolder=uigetdir(dataRootFolder);
end

saveName=fullfile(dataFolder,'ExpData.mat');
handles.saveName=saveName;
handles.dataFolder=dataFolder;
if exist(saveName,'file')
    %%% Reload information if saveName is already present
    load(saveName,'globalProperties','folderProperties')    
    handles.globalProperties=globalProperties;
    handles.folderProperties=folderProperties;
    
    for iFolder=1:length(folderProperties)
        if isempty(handles.folderProperties(iFolder).Analyze)
            disp(iFolder)
            handles.folderProperties(iFolder).Analyze=false;
        end
    end
    
    %     if ~isfield(handles.folderProperties,'Analyze')
    %         [handles.folderProperties.Analyze]=deal(true);
    %         disp('field Analyze added')
    %     end
else
    %%% If not, prepare defaultData_2013-12-02 structures
    A=dir(dataFolder);
    
    sub_folders=getSubFolders(dataFolder);
    nFolders=length(sub_folders);
    
    %%% Set default global properties
    globalProperties.Rat_ID='';
    globalProperties.Date=A(1).date;
    globalProperties.Experiment_number=0;
    globalProperties.Experiment_description='';
    globalProperties.Biela_used=0;
    globalProperties.Touch_down=0; % turns
    globalProperties.Last_known_impedance=0;
    globalProperties.Cage_barcode=0;
    handles.globalProperties=globalProperties;
    
    %%% Set default folder properties
    count=1;
    folderProperties=struct;
    for iFolder=1:nFolders
        sub_folder=sub_folders{iFolder};
        eventFilename=fullfile(dataFolder,sub_folder,'Events.nev');
        [TTL_TimeStamps TTLS] = Nlx2MatEV( eventFilename, [1 0 1 0 0], 0, 1, []);
        if length(TTLS)<=2             
            disp('Empty experiment')
            folderProperties(count).Nr=count;
            folderProperties(count).folderName=sub_folder;         
            folderProperties(count).Analyze=false; 
        else
            experimentProperties=extract_experimentProperties(TTL_TimeStamps,TTLS);            
            folderProperties(count).Nr=count;
            folderProperties(count).folderName=sub_folder;
            folderProperties(count).expType=experimentProperties.experiment_type;
            folderProperties(count).nTrials=experimentProperties.nTrials;
            folderProperties(count).Turns=[];
            folderProperties(count).SiteNr=[];
            folderProperties(count).AreaNr=[];
            folderProperties(count).Analyze=true;                        
        end
        count=count+1;
    end
    handles.folderProperties=folderProperties;
end


%%% Set up GUI
handles.figure1=figure(1);
clf
set(handles.figure1,'units','normalized','position',[0.15 0.15 0.5 0.75],'resize','on','menubar','none','NumberTitle','Off','Name','AutoCluster: Experiment Crawler')
mainPanel=uipanel(handles.figure1,'units','normalized','position',[.01 .01 .98 .98]);

%%% Show general properties (ratID, day, exp nr, type of experiment, biela used,
%%% last known impedance of the electrode, cageNr, serial number,
%%% touch-down, ... plus custom)
%%% Prepare properties table
handles.gproperties_table=uitable(mainPanel,'Tag','input_table','Units','Normalized','Position',[.01 .6 .98 .35]);
handles.gproperties_table_name='globalProperties';
set(handles.gproperties_table,'ColumnName',{'Parameter' 'Value'},'ColumnWidth',{300 300},'ColumnEditable',[false true],'ColumnFormat',{'char' ''},'RowName',[],'CellEditCallback',{@readTable,handles.gproperties_table_name})


%%% Show these data in table + allow option to add columns and data
% folder nr, folder name, exp type, nTrials, site nr, area nr, analyse yes/no
handles.fproperties_table=uitable(mainPanel,'Tag','input_table','Units','Normalized','Position',[.01 .1 .98 .45]);
handles.fproperties_table_name='folderProperties';
fieldNames=fieldnames(folderProperties);
set(handles.fproperties_table,'ColumnName',fieldNames,'ColumnWidth',{50 250 50 50 50 50 50 50},'ColumnEditable',[false false true true true true true true],'ColumnFormat',{'' 'char' '' '' '' '' '' ''},'RowName',[],'CellEditCallback',{@readSummaryTable,handles.fproperties_table_name,1})

%%% Place save button
uicontrol(mainPanel,'style','pushbutton','string','Save Folder Information','units','normalized','position',[.01 .01 .98 .08 ],'CallBack',@CE_save_data)

%%% Store current handles
guidata(handles.figure1,handles)

%%% Fill tables with handles
writeTable(handles.gproperties_table,handles.gproperties_table_name)
writeSummaryTable(handles.fproperties_table,handles.fproperties_table_name,1)

