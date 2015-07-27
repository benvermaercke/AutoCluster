function CE_save_data(varargin)
H=varargin{1};
handles=guidata(H);

dataFolder=handles.dataFolder;
globalProperties=handles.globalProperties;
folderProperties=handles.folderProperties;


%%% Process folder properties
nFolders=length(folderProperties);
for iFolder=1:nFolders    
    P=folderProperties(iFolder);    
    saveName=fullfile(dataFolder,P.folderName,'exp_properties.txt');
    data=[globalProperties.Experiment_number P.SiteNr P.AreaNr];
    if length(data)==3
        %if ~exist(saveName,'file')
            dlmwrite(saveName,data,'\t')
        %end
    else
        %P.Nr
        %disp('Data incomplete')
    end
end

%%% Save all acquired data into mat-file in dataFolder
saveName=fullfile(dataFolder,'ExpData.mat')
save(saveName,'globalProperties','folderProperties')

disp('Folder and general data saved!!!')