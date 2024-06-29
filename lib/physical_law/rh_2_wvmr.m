function [wvmr] = rh_2_wvmr(RH, p, T)
% RH_2_WVMR convert relative humidity to water vapor mixing ratio.
%
% USAGE:
%    [wvmr] = rh_2_wvmr(RH, p, T)
%
% INPUTS:
%    RH: numeric
%        relative humidity. (%)
%    p: numeric
%        ambient pressure. (hPa)
%    T: numeric
%        ambient temperature. (celsius)
%
% OUTPUTS:
%    wvmr: numeric
%        water vapor mixing ratio. (g/kg)
%
% HISTORY:
%    2023-06-28: first edition by Zhenping
% .. Authors: - zp.yin@whu.edu.cn

es = saturated_vapor_pres(T);

Mw = 18.0160;
Md = 28.9660;
wvmr = Mw ./ Md .* RH ./ 100 .* es ./ (p - RH ./ 100 .* es) * 1000.0;

end