%%% Find which folder we are in on this computer
rootFolder=fileparts(which('headerFile.m'));

if ispc
    name=getenv('COMPUTERNAME');
    switch lower(name)
        case 'p101pw126'
            dataRootFolder='E:\LeuvenData\Developement\AutoCluster\CSC_data';
            saveFolder='E:\LeuvenData\Developement\AutoCluster\dataFiles';
        case 'p102pw041'
            dataRootFolder='E:\LeuvenData\Developement\AutoCluster\CSC_data';
            saveFolder='E:\LeuvenData\Developement\AutoCluster\dataFiles';
        case 'ppw52606'
            dataRootFolder='E:\Experiments\12_multisite_testing';
            saveFolder='E:\LeuvenData\Developement\AutoCluster\dataFiles\NX32_data';
        otherwise
            %%% User defined folders
            dataRootFolder='C:\Users\LBP\Desktop\Ben\AutoCluster\CSC_data';
            saveFolder='C:\Users\LBP\Desktop\Ben\AutoCluster\dataFiles\Roxane';
    end
else
    dataRootFolder=fullfile(rootFolder,'CSC_data');
    saveFolder=fullfile(rootFolder,'dataFiles','Ben');
end
saveFolder


%%% Include subdirectories to the path (only for this session)
addpath(fullfile(rootFolder,'includes'))
addpath(fullfile(rootFolder,'GUI_func'))
addpath(fullfile(rootFolder,'Neuralynx'))
addpath(fullfile(rootFolder,'KlustaKwik'))
%addpath(fullfile(rootFolder,'WaveClus')) % not implemented yet...

%%% Set some useful and constant filenames

%%% Define colorscheme
cheetahColors=[255 0 0 ; 255 222 153 ; 161 255 0 ; 153 255 158 ; 0 255 187 ; 153 212 255 ; 12 0 127 ; 232 153 255 ; 255 0 135 ; 255 168 153 ; 255 212 0 ; 202 255 153 ; 0 255 51 ; 153 255 243 ; 0 110 255 ; 89 76 127 ; 119 0 127 ; 127 76 96 ; 127 38 0 ; 127 126 76 ; 42 127 0 ; 76 127 94 ; 0 123 127 ; 76 90 127 ; 51 0 127 ; 127 76 123 ; 127 0 29 ; 127 99 76 ; 110 127 0 ; 85 127 76 ; 0 127 63 ; 76 118 127]/255;
nColors=size(cheetahColors,1);

%cheetahColors(7,:)=[80 0 255]/255;
cheetahColors(7,:)=[80 80 255]/255;
