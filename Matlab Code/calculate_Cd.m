function doctor_Cd = calculate_Cd(RH)
% 计算医生诊断信心
Ld = 20;% 医生能力水平

% 病情诊断结果DH，服从众数为RH的beta分布，形状参数为Ld
a1 = (RH * Ld - 2 * RH + 1)/(1 - RH);% 原文中alpha
DH = betarnd(a1,Ld);% 根据beta分布得出随机数DH

% 医生诊断信心Cd，服从众数为Cd_m的beta分布，形状参数为Ld
Cd_m = (15 * (RH ^ 2))/Ld - (15 * RH)/Ld + 1;
a2 = (Cd_m * Ld - 2 * Cd_m + 1)/(1 - Cd_m);
doctor_Cd = betarnd(a2,Ld);
end