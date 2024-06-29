function [meteorData] = readMeteorData(mTime, meteorCfg, varargin)
% READMETEORDATA read meteorological data.
%
% USAGE:
%    [meteorData] = readMeteorData(mTime, meteorCfg)
%
% INPUTS:
%    mTime: numeric
%        matlab datenum array for each query timestamp.
%    meteorCfg: struct
%        meteorSource
%        sondeType
%        sondePath
%        sondeStation
%        datetime
%
% OUTPUTS:
%    meteorData: struct
%        time: datenum
%        altitude: matrix (m) (altitude x time)
%        pressure: matrix (hPa) (altitude x time)
%        temperature: matrix (degC) (altitude x time)
%        water_vapor_mixing_ratio: matrix (g * kg-1) (altitude x time)
%
% HISTORY:
%    2024-03-19: first edition by Zhenping
% .. Authors: - zp.yin@whu.edu.cn

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'mTime', @isnumeric);
addRequired(p, 'meteorCfg', @isstruct);
addParameter(p, 'debug', false, @islogical);

parse(p, mTime, meteorCfg, varargin{:});

startTime = min(mTime);
stopTime = max(mTime);

meteorData = struct();
meteorData.time = [];
meteorData.altitude = [];
meteorData.pressure = [];
meteorData.temperature = [];
meteorData.water_vapor_mixing_ratio = [];

switch meteorCfg.meteorSource

case 'local-sonde'   % netCDF4 file

    for thisTime = startTime:datenum(0, 1, 0, 12, 0, 0):stopTime
        queryDate = floor(thisTime);
        isBeforeMidDay = (thisTime - queryDate) < 0.5;
        if isBeforeMidDay
            sondeTime = queryDate + datenum(0, 1, 0, 0, 0, 0);
        else
            sondeTime = queryDate + datenum(0, 1, 0, 12, 0, 0);
        end

        sondeSubPath = fullfile(meteorCfg.sondePath, meteorCfg.sondeStation);
        sondeFile = listfile(...
            fullfile(sondeSubPath, datestr(sondeTime, 'yyyy')), ...
            sprintf('radiosonde_\\w*_%s.nc', datestr(sondeTime, 'yyyymmdd_HHMM')), ...
            1);

        if ~ isempty(sondeFile)
            thisALT = ncread(sondeFile{1}, 'altitude');
            thisPRES = ncread(sondeFile{1}, 'pressure');
            thisTEMP = ncread(sondeFile{1}, 'temperature');
            thisWVMR = ncread(sondeFile{1}, 'water_vapor_mixing_ratio');
        else
            error('No sonde file was found. Check the meteorCfg');
        end

        meteorData.time = cat(2, meteorData.time, sondeTime);
        meteorData.altitude = cat(2, meteorData.altitude, thisALT);
        meteorData.pressure = cat(2, meteorData.pressure, thisPRES);
        meteorData.temperature = cat(2, meteorData.temperature, thisTEMP);
        meteorData.water_vapor_mixing_ratio = cat(2, meteorData.water_vapor_mixing_ratio, thisWVMR);
    end

case 'local-sonde-2'   % HDF5 file

    for thisTime = startTime:datenum(0, 1, 0, 12, 0, 0):stopTime
        queryDate = floor(thisTime);
        isBeforeMidDay = (thisTime - queryDate) < 0.5;
        if isBeforeMidDay
            sondeTime = queryDate + datenum(0, 1, 0, 0, 0, 0);
        else
            sondeTime = queryDate + datenum(0, 1, 0, 12, 0, 0);
        end

        sondeSubPath = fullfile(meteorCfg.sondePath, meteorCfg.sondeStation);
        sondeFile = listfile(...
            fullfile(sondeSubPath, datestr(sondeTime, 'yyyy')), ...
            sprintf('radiosonde_\\w*_%s.h5', datestr(sondeTime, 'yyyymmdd_HH')), ...
            1);

        if ~ isempty(sondeFile)
            sondeData = h5read(sondeFile{1}, '/RadioSonde');
        else
            error('No sonde file was found. Check the meteorCfg');
        end

        meteorData.time = cat(2, meteorData.time, sondeTime);
        meteorData.altitude = cat(2, meteorData.altitude, sondeData.HGHT);
        meteorData.pressure = cat(2, meteorData.pressure, sondeData.PRES);
        meteorData.temperature = cat(2, meteorData.temperature, sondeData.TEMP);
        meteorData.water_vapor_mixing_ratio = cat(2, meteorData.water_vapor_mixing_ratio, sondeData.MIXR);
    end

case 'web-sonde'
    for thisTime = startTime:datenum(0, 1, 0, 12, 0, 0):stopTime
        queryDate = floor(thisTime);
        isBeforeMidDay = (thisTime - queryDate) < 0.5;
        if isBeforeMidDay
            sondeTime = queryDate + datenum(0, 1, 0, 0, 0, 0);
        else
            sondeTime = queryDate + datenum(0, 1, 0, 12, 0, 0);
        end

        try
            [thisAlt, thisTemp, thisPres, thisRelh, globalAttri] = read_websonde(sondeTime, [datenum(0, 1, 0, 3, 0, 0), datenum(0, 1, 0, 3, 0, 0)], meteorCfg.sondeStation, 'BUFR');
        catch
            error('Failure in reading web-sonde data.');
        end

        if isempty(thisAlt)
            warning('Empty data returned for web-sonde!');
        else
            meteorData.time = cat(2, meteorData.time, globalAttri.datetime);
            meteorData.altitude = cat(2, meteorData.altitude, thisAlt);
            meteorData.pressure = cat(2, meteorData.pressure, thisPres);
            meteorData.temperature = cat(2, meteorData.temperature, thisTemp);
            meteorData.water_vapor_mixing_ratio = cat(2, meteorData.water_vapor_mixing_ratio, rh_2_wvmr(thisRelh, thisPres, thisTemp));
        end
    end

case 'standard-atmosphere'

    const = loadConstants();

    for thisTime = startTime:datenum(0, 1, 1, 0, 0, 0):stopTime

        % read standard_atmosphere data
        [alt, ~, ~, temp, pres] = atmo(60, 0.03, 1);
        alt = alt * 1e3;
        pres = pres / 1e2;
        temp = temp + const.T0;   % convert to [\circC]
        wvmr = NaN(size(temp));

        meteorData.time = cat(2, meteorData.time, thisTime);
        meteorData.altitude = cat(2, meteorData.altitude, alt);
        meteorData.pressure = cat(2, meteorData.pressure, pres);
        meteorData.temperature = cat(2, meteorData.temperature, temp);
        meteorData.water_vapor_mixing_ratio = cat(2, meteorData.water_vapor_mixing_ratio, wvmr);
    end

end

end