global METEOR_ENVS;

METEOR_ENVS.RootDir = fileparts(mfilename('fullpath'));
METEOR_ENVS.Author = 'Zhenping Yin';
METEOR_ENVS.Version = '0.1';
METEOR_ENVS.UpdateTime = '2024-01-31';
METEOR_ENVS.Toolbox = 'MeteorToolbox';

addpath(genpath(fullfile(METEOR_ENVS.RootDir, 'lib')));
addpath(genpath(fullfile(METEOR_ENVS.RootDir, 'include')));